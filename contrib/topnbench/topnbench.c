/*
 * topnbench.c
 *
 * A benchmark extension for delayed target-list projection around
 * ORDER BY ... LIMIT.  This is test code, not intended for commit.
 */
#include "postgres.h"

#include <ctype.h>
#include <math.h>
#include <stdlib.h>

#include "access/htup_details.h"
#include "catalog/namespace.h"
#include "catalog/pg_class.h"
#include "catalog/pg_type_d.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "funcapi.h"
#include "lib/stringinfo.h"
#include "miscadmin.h"
#include "nodes/pathnodes.h"
#include "nodes/parsenodes.h"
#include "optimizer/planner.h"
#include "tcop/tcopprot.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/tuplestore.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(topnbench_work);
PG_FUNCTION_INFO_V1(topnbench_run);
PG_FUNCTION_INFO_V1(topnbench_compare);
PG_FUNCTION_INFO_V1(topnbench_measure);

#define DECISION_NOISE_FRACTION 0.03

typedef enum ProjectionPlacement
{
	PLACEMENT_UNKNOWN,
	PLACEMENT_EARLY,
	PLACEMENT_LATE
} ProjectionPlacement;

typedef struct CandidateCost
{
	bool		valid;
	int			disabled_nodes;
	double		startup_cost;
	double		total_cost;
	double		limit_cost;
	double		sort_rows;
	int			sort_width;
} CandidateCost;

typedef struct CandidateCosts
{
	CandidateCost early;
	CandidateCost late;
} CandidateCosts;

typedef enum ExpressionShape
{
	EXPR_INDEPENDENT,
	EXPR_NESTED
} ExpressionShape;

typedef struct BenchCase
{
	const char *name;
	int			offset_ppm;
	int			limit_ppm;
	int			expression_steps;
	int			declared_cost;
	int			work_rounds;
	ExpressionShape shape;
	int			workers;
} BenchCase;

typedef struct ExplainResult
{
	double		milliseconds;
	double		startup_cost;
	double		total_cost;
	int			launched_workers;
	int			sort_output_columns;
	char	   *sort_output_signature;
	double		estimated_sort_rows;
	double		actual_sort_input_rows;
	int			estimated_sort_width;
	double		sort_space_used_kb;
	char	   *sort_method;
	char	   *sort_space_type;
	char	   *nodes;
	CandidateCosts candidates;
} ExplainResult;

typedef struct TimingSummary
{
	double		minimum;
	double		median;
} TimingSummary;

typedef struct StrategyResult
{
	int			launched_workers;
	int			sort_output_columns;
	char	   *sort_output_signature;
	char	   *manual_late_sort_output_signature;
	char	   *forced_early_sort_output_signature;
	double		estimated_sort_rows;
	double		actual_sort_input_rows;
	int			estimated_sort_width;
	double		sort_space_used_kb;
	char	   *sort_method;
	char	   *sort_space_type;
	double		manual_late_sort_space_used_kb;
	char	   *manual_late_sort_method;
	char	   *manual_late_sort_space_type;
	double		forced_early_sort_space_used_kb;
	char	   *forced_early_sort_method;
	char	   *forced_early_sort_space_type;
	CandidateCosts candidates;
	char	   *nodes;
	TimingSummary auto_timing;
	TimingSummary manual_timing;
	TimingSummary forced_early_timing;
} StrategyResult;

static create_upper_paths_hook_type previous_create_upper_paths_hook = NULL;
static bool capture_candidate_costs = false;
static CandidateCosts captured_candidate_costs;

void		_PG_init(void);
void		_PG_fini(void);

static const Path *unary_subpath(const Path *path);
static ProjectionPlacement classify_projection_placement(const Path *path,
											  const Path **sort_input);
static void remember_candidate(const PlannerInfo *root, const Path *path,
							   ProjectionPlacement placement,
							   const Path *sort_input);
static void topnbench_create_upper_paths(PlannerInfo *root,
									 UpperRelationKind stage,
									 RelOptInfo *input_rel,
									 RelOptInfo *output_rel,
									 void *extra);

void
_PG_init(void)
{
	previous_create_upper_paths_hook = create_upper_paths_hook;
	create_upper_paths_hook = topnbench_create_upper_paths;
}

void
_PG_fini(void)
{
	if (create_upper_paths_hook == topnbench_create_upper_paths)
		create_upper_paths_hook = previous_create_upper_paths_hook;
}

/* Return the child of the unary upper paths relevant to this benchmark. */
static const Path *
unary_subpath(const Path *path)
{
	switch (nodeTag(path))
	{
		case T_ProjectionPath:
			return ((const ProjectionPath *) path)->subpath;
		case T_SortPath:
			return ((const SortPath *) path)->subpath;
		case T_IncrementalSortPath:
			return ((const IncrementalSortPath *) path)->spath.subpath;
		case T_GatherPath:
			return ((const GatherPath *) path)->subpath;
		case T_GatherMergePath:
			return ((const GatherMergePath *) path)->subpath;
		default:
			return NULL;
	}
}

/*
 * The POC produces one of these two shapes:
 *
 *     late:  Projection -> [Gather Merge] -> Sort -> input
 *     early: [Gather Merge] -> Sort -> Projection -> input
 *
 * ProjectionPath can be a dummy path whose projection is absorbed into its
 * child plan node, but its position still describes which tuples are charged
 * for evaluating the target.
 */
static ProjectionPlacement
classify_projection_placement(const Path *path, const Path **sort_input)
{
	bool		projection_above_sort = false;
	bool		projection_below_sort = false;
	bool		seen_sort = false;

	*sort_input = NULL;
	for (int depth = 0; path != NULL && depth < 16; depth++)
	{
		if (IsA(path, ProjectionPath))
		{
			if (seen_sort)
				projection_below_sort = true;
			else
				projection_above_sort = true;
		}
		else if (IsA(path, SortPath) || IsA(path, IncrementalSortPath))
		{
			const Path *child = unary_subpath(path);

			if (!seen_sort)
				*sort_input = child;
			seen_sort = true;
		}

		path = unary_subpath(path);
	}

	if (!seen_sort)
		return PLACEMENT_UNKNOWN;
	if (projection_above_sort && !projection_below_sort)
		return PLACEMENT_LATE;
	if (!projection_above_sort && projection_below_sort)
		return PLACEMENT_EARLY;
	return PLACEMENT_UNKNOWN;
}

static void
remember_candidate(const PlannerInfo *root, const Path *path,
				   ProjectionPlacement placement, const Path *sort_input)
{
	CandidateCost *candidate;
	double		fraction = 1.0;
	double		limit_cost;

	if (placement == PLACEMENT_EARLY)
		candidate = &captured_candidate_costs.early;
	else if (placement == PLACEMENT_LATE)
		candidate = &captured_candidate_costs.late;
	else
		return;

	/*
	 * create_ordered_paths() has already included OFFSET + LIMIT in the
	 * bounded Sort cost, but the Path still reports all input rows.  Estimate
	 * the cost consumed through the upper Limit in the same linear fashion as
	 * adjust_limit_rows_costs().
	 */
	if (root->limit_tuples > 0.0 && path->rows > 0.0)
		fraction = Min(root->limit_tuples / path->rows, 1.0);
	limit_cost = path->startup_cost +
		fraction * (path->total_cost - path->startup_cost);

	/* Disabled nodes dominate cost in the normal path tournament. */
	if (candidate->valid &&
		(candidate->disabled_nodes < path->disabled_nodes ||
		 (candidate->disabled_nodes == path->disabled_nodes &&
		  candidate->limit_cost <= limit_cost)))
		return;

	candidate->valid = true;
	candidate->disabled_nodes = path->disabled_nodes;
	candidate->startup_cost = path->startup_cost;
	candidate->total_cost = path->total_cost;
	candidate->limit_cost = limit_cost;
	candidate->sort_rows = sort_input != NULL ? sort_input->rows : -1.0;
	candidate->sort_width =
		sort_input != NULL ? sort_input->pathtarget->width : -1;
}

static void
topnbench_create_upper_paths(PlannerInfo *root, UpperRelationKind stage,
							RelOptInfo *input_rel, RelOptInfo *output_rel,
							void *extra)
{
	ListCell   *lc;

	if (previous_create_upper_paths_hook != NULL)
		previous_create_upper_paths_hook(root, stage, input_rel, output_rel,
									 extra);

	if (!capture_candidate_costs || stage != UPPERREL_ORDERED ||
		root->query_level != 1 || root->limit_tuples <= 0.0)
		return;

	foreach(lc, output_rel->pathlist)
	{
		const Path *path = lfirst(lc);
		const Path *sort_input;
		ProjectionPlacement placement;

		placement = classify_projection_placement(path, &sort_input);
		remember_candidate(root, path, placement, sort_input);
	}
}

/*
 * These are curated rather than a Cartesian product.  The quick profile
 * exercises the decision boundary, deliberately inaccurate procost values,
 * expression shape, parallel query, and OFFSET.  The confidence profile adds
 * denser boundary coverage.
 */
static const BenchCase quick_cases[] = {
	/* LIMIT sweep: four independent, COST 1 calls. */
	{"limit-0.0001pct", 0, 1, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-0.01pct", 0, 100, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-1pct", 0, 10000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-10pct", 0, 100000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-20pct", 0, 200000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-30pct", 0, 300000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-40pct", 0, 400000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-50pct", 0, 500000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-60pct", 0, 600000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-70pct", 0, 700000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-80pct", 0, 800000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-90pct", 0, 900000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"limit-100pct", 0, 1000000, 4, 1, 4, EXPR_INDEPENDENT, 0},

	/* Structural complexity sweep at 10%. */
	{"steps-1", 0, 100000, 1, 1, 4, EXPR_INDEPENDENT, 0},
	{"steps-2", 0, 100000, 2, 1, 4, EXPR_INDEPENDENT, 0},
	{"steps-8", 0, 100000, 8, 1, 4, EXPR_INDEPENDENT, 0},
	{"steps-16", 0, 100000, 16, 1, 4, EXPR_INDEPENDENT, 0},

	/* 3x3 declared-cost versus actual-work error matrix. */
	{"cost-1-work-1", 0, 250000, 1, 1, 1, EXPR_INDEPENDENT, 0},
	{"cost-1-work-16", 0, 250000, 1, 1, 16, EXPR_INDEPENDENT, 0},
	{"cost-1-work-64", 0, 250000, 1, 1, 64, EXPR_INDEPENDENT, 0},
	{"cost-10-work-1", 0, 250000, 1, 10, 1, EXPR_INDEPENDENT, 0},
	{"cost-10-work-16", 0, 250000, 1, 10, 16, EXPR_INDEPENDENT, 0},
	{"cost-10-work-64", 0, 250000, 1, 10, 64, EXPR_INDEPENDENT, 0},
	{"cost-100-work-1", 0, 250000, 1, 100, 1, EXPR_INDEPENDENT, 0},
	{"cost-100-work-16", 0, 250000, 1, 100, 16, EXPR_INDEPENDENT, 0},
	{"cost-100-work-64", 0, 250000, 1, 100, 64, EXPR_INDEPENDENT, 0},

	/* Same call counts, one deep expression instead of many targets. */
	{"nested-1", 0, 100000, 1, 1, 4, EXPR_NESTED, 0},
	{"nested-2", 0, 100000, 2, 1, 4, EXPR_NESTED, 0},
	{"nested-4", 0, 100000, 4, 1, 4, EXPR_NESTED, 0},
	{"nested-8", 0, 100000, 8, 1, 4, EXPR_NESTED, 0},
	{"nested-16", 0, 100000, 16, 1, 4, EXPR_NESTED, 0},

	/* Representative parallel cases. */
	{"parallel-limit-1", 0, 1, 4, 1, 4, EXPR_INDEPENDENT, 2},
	{"parallel-limit-1pct", 0, 10000, 4, 1, 4, EXPR_INDEPENDENT, 2},
	{"parallel-limit-25pct", 0, 250000, 4, 1, 4, EXPR_INDEPENDENT, 2},
	{"parallel-limit-50pct", 0, 500000, 4, 1, 4, EXPR_INDEPENDENT, 2},

	/* The Sort must retain OFFSET + LIMIT rows. */
	{"offset-10pct-limit-1", 100000, 1, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"offset-25pct-limit-1", 250000, 1, 4, 1, 4, EXPR_INDEPENDENT, 0}
};

static const BenchCase confidence_extra_cases[] = {
	{"boundary-2.5pct-1", 0, 25000, 1, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-5pct-1", 0, 50000, 1, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-7.5pct-1", 0, 75000, 1, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-15pct-2", 0, 150000, 2, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-20pct-2", 0, 200000, 2, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-20pct-4", 0, 200000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-30pct-4", 0, 300000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-40pct-4", 0, 400000, 4, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-40pct-8", 0, 400000, 8, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-50pct-8", 0, 500000, 8, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-60pct-8", 0, 600000, 8, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-55pct-16", 0, 550000, 16, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-65pct-16", 0, 650000, 16, 1, 4, EXPR_INDEPENDENT, 0},
	{"boundary-75pct-16", 0, 750000, 16, 1, 4, EXPR_INDEPENDENT, 0},
	{"parallel-steps-1", 0, 100000, 1, 1, 4, EXPR_INDEPENDENT, 2},
	{"parallel-steps-8", 0, 100000, 8, 1, 4, EXPR_INDEPENDENT, 2},
	{"parallel-work-64", 0, 250000, 1, 1, 64, EXPR_INDEPENDENT, 2},
	{"parallel-offset-25pct", 250000, 1, 4, 1, 4, EXPR_INDEPENDENT, 2}
};

static pg_noinline int32
run_workload(int32 value, int rounds)
{
	uint32		x = (uint32) value ^ 0x9e3779b9U;

	for (int i = 0; i < rounds; i++)
	{
		x ^= x << 13;
		x ^= x >> 17;
		x ^= x << 5;
		x += 0x7f4a7c15U;
	}

	return (int32) x;
}

Datum
topnbench_work(PG_FUNCTION_ARGS)
{
	int32		value = PG_GETARG_INT32(0);
	int32		rounds = PG_GETARG_INT32(1);
	int32		salt = PG_GETARG_INT32(2);

	if (rounds < 0 || rounds > 10000)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("work rounds must be between 0 and 10000")));

	PG_RETURN_INT32(run_workload(value ^ salt, rounds));
}

static void
validate_select(const char *sql)
{
	List	   *raw_parsetree_list = pg_parse_query(sql);
	RawStmt    *rawstmt;
	SelectStmt *stmt;

	if (list_length(raw_parsetree_list) != 1)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("benchmark query must contain exactly one statement")));

	rawstmt = linitial_node(RawStmt, raw_parsetree_list);
	if (!IsA(rawstmt->stmt, SelectStmt))
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("benchmark query must be a SELECT statement")));

	stmt = castNode(SelectStmt, rawstmt->stmt);
	if (stmt->intoClause != NULL || stmt->lockingClause != NIL)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("SELECT INTO and row locking are not supported")));
}

static double
extract_json_double(const char *json, const char *field, double fallback)
{
	char	   *p = strstr(json, field);
	char	   *endptr;
	double		result;

	if (p == NULL)
		return fallback;
	p += strlen(field);
	while (*p == ' ' || *p == '\t' || *p == ':')
		p++;

	result = strtod(p, &endptr);
	if (endptr == p)
		return fallback;
	return result;
}

static double
extract_json_double_before(const char *start, const char *end,
						   const char *field, double fallback)
{
	const char *p = strstr(start, field);
	char	   *endptr;
	double		result;

	if (p == NULL || (end != NULL && p >= end))
		return fallback;
	p += strlen(field);
	while (*p == ' ' || *p == '\t' || *p == ':')
		p++;

	result = strtod(p, &endptr);
	if (endptr == p || (end != NULL && endptr > end))
		return fallback;
	return result;
}

static char *
extract_json_string_before(const char *start, const char *end,
						   const char *field)
{
	const char *p = strstr(start, field);
	const char *value_start;
	const char *value_end;

	if (p == NULL || (end != NULL && p >= end))
		return NULL;
	p += strlen(field);
	p = strchr(p, ':');
	if (p == NULL || (end != NULL && p >= end))
		return NULL;
	value_start = strchr(p, '"');
	if (value_start == NULL || (end != NULL && value_start >= end))
		return NULL;
	value_start++;
	value_end = strchr(value_start, '"');
	if (value_end == NULL || (end != NULL && value_end > end))
		return NULL;

	return pnstrdup(value_start, value_end - value_start);
}

static int
extract_max_workers(const char *json)
{
	const char *field = "\"Workers Launched\"";
	const char *p = json;
	int			maximum = 0;

	while ((p = strstr(p, field)) != NULL)
	{
		double		value = extract_json_double(p, field, 0.0);

		if (value > maximum)
			maximum = (int) value;
		p += strlen(field);
	}
	return maximum;
}

static char *
extract_plan_nodes(const char *json)
{
	const char *field = "\"Node Type\"";
	const char *p = json;
	StringInfoData result;
	int			nnodes = 0;

	initStringInfo(&result);
	while ((p = strstr(p, field)) != NULL)
	{
		const char *colon = strchr(p + strlen(field), ':');
		const char *start;
		const char *end;

		if (colon == NULL)
			break;
		start = strchr(colon, '"');
		if (start == NULL)
			break;
		start++;
		end = strchr(start, '"');
		if (end == NULL)
			break;

		if (nnodes++ > 0)
			appendStringInfoString(&result, " > ");
		appendBinaryStringInfo(&result, start, end - start);
		p = end + 1;
	}

	return result.data;
}

/*
 * Return the number of expressions in the first Sort node's Output array.
 * EXPLAIN JSON represents every Output item as a JSON string, so a small
 * string-array parser is sufficient and avoids making benchmark timings
 * depend on SQL-level JSON processing.
 */
static int
extract_sort_output_columns(const char *json)
{
	const char *sort = strstr(json, "\"Node Type\": \"Sort\"");
	const char *plans;
	const char *output;
	const char *p;
	int			count = 0;

	if (sort == NULL)
		return -1;

	plans = strstr(sort, "\"Plans\"");
	output = strstr(sort, "\"Output\"");
	if (output == NULL || (plans != NULL && output > plans))
		return -1;

	p = strchr(output, '[');
	if (p == NULL)
		return -1;
	p++;

	for (;;)
	{
		while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n')
			p++;
		if (*p == ']')
			return count;
		if (*p != '"')
			return -1;

		p++;
		while (*p != '\0' && *p != '"')
		{
			if (*p == '\\' && p[1] != '\0')
				p += 2;
			else
				p++;
		}
		if (*p != '"')
			return -1;
		count++;
		p++;

		while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n')
			p++;
		if (*p == ']')
			return count;
		if (*p != ',')
			return -1;
		p++;
	}
}

/*
 * Return a whitespace-normalized copy of the first Sort node's Output array.
 * Whitespace inside JSON strings is preserved.  Comparing this signature
 * across the automatic, manual-late, and forced-early forms distinguishes
 * source Vars carried through Sort from expressions evaluated below Sort.
 */
static char *
extract_sort_output_signature(const char *json)
{
	const char *sort = strstr(json, "\"Node Type\": \"Sort\"");
	const char *plans;
	const char *output;
	const char *p;
	StringInfoData signature;
	int			depth = 0;
	bool		in_string = false;
	bool		escaped = false;

	if (sort == NULL)
		return NULL;

	plans = strstr(sort, "\"Plans\"");
	output = strstr(sort, "\"Output\"");
	if (output == NULL || (plans != NULL && output > plans))
		return NULL;

	p = strchr(output, '[');
	if (p == NULL || (plans != NULL && p > plans))
		return NULL;

	initStringInfo(&signature);
	for (; *p != '\0'; p++)
	{
		char		ch = *p;

		if (in_string)
		{
			appendStringInfoChar(&signature, ch);
			if (escaped)
				escaped = false;
			else if (ch == '\\')
				escaped = true;
			else if (ch == '"')
				in_string = false;
			continue;
		}

		if (ch == '"')
		{
			in_string = true;
			appendStringInfoChar(&signature, ch);
		}
		else if (ch == '[')
		{
			depth++;
			appendStringInfoChar(&signature, ch);
		}
		else if (ch == ']')
		{
			appendStringInfoChar(&signature, ch);
			if (--depth == 0)
				return signature.data;
		}
		else if (ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n')
			appendStringInfoChar(&signature, ch);
	}

	pfree(signature.data);
	return NULL;
}

/*
 * EXPLAIN may qualify a Var in one query form but not another, for example
 * "a" versus "topnbench_data.a".  Remove bare identifier qualifiers before
 * comparing signatures.  This intentionally handles the simple identifiers
 * generated by this benchmark; quoted identifiers remain visible and may
 * cause the result to be reported as unknown rather than misclassified.
 */
static char *
canonicalize_sort_output_signature(const char *signature)
{
	StringInfoData result;
	const char *p = signature;
	bool		in_json_string = false;
	bool		escaped = false;
	bool		in_sql_literal = false;

	initStringInfo(&result);
	while (*p != '\0')
	{
		char		ch = *p;

		if (!in_json_string)
		{
			appendStringInfoChar(&result, ch);
			if (ch == '"')
				in_json_string = true;
			p++;
			continue;
		}

		if (escaped)
		{
			appendStringInfoChar(&result, ch);
			escaped = false;
			p++;
			continue;
		}
		if (ch == '\\')
		{
			appendStringInfoChar(&result, ch);
			escaped = true;
			p++;
			continue;
		}
		if (ch == '"')
		{
			appendStringInfoChar(&result, ch);
			in_json_string = false;
			in_sql_literal = false;
			p++;
			continue;
		}
		if (ch == '\'')
		{
			appendStringInfoChar(&result, ch);
			if (in_sql_literal && p[1] == '\'')
			{
				appendStringInfoChar(&result, p[1]);
				p += 2;
			}
			else
			{
				in_sql_literal = !in_sql_literal;
				p++;
			}
			continue;
		}

		if (!in_sql_literal &&
			(isalpha((unsigned char) ch) || ch == '_'))
		{
			const char *start = p;

			p++;
			while (isalnum((unsigned char) *p) || *p == '_' || *p == '$')
				p++;
			if (*p == '.')
			{
				p++;
				continue;
			}
			appendBinaryStringInfo(&result, start, p - start);
			continue;
		}

		appendStringInfoChar(&result, ch);
		p++;
	}

	return result.data;
}

static void
extract_sort_metadata(const char *json, ExplainResult *result)
{
	const char *sort = strstr(json, "\"Node Type\": \"Sort\"");
	const char *plans;
	const char *child;
	const char *child_plans;
	double		plan_rows;
	double		sort_loops;
	double		child_rows;
	double		child_loops;

	result->estimated_sort_rows = -1.0;
	result->actual_sort_input_rows = -1.0;
	result->estimated_sort_width = -1;
	result->sort_space_used_kb = -1.0;
	result->sort_method = NULL;
	result->sort_space_type = NULL;

	if (sort == NULL)
		return;

	plans = strstr(sort, "\"Plans\"");
	plan_rows = extract_json_double_before(sort, plans,
									   "\"Plan Rows\"", -1.0);
	sort_loops = extract_json_double_before(sort, plans,
										"\"Actual Loops\"", 1.0);
	if (plan_rows >= 0.0)
		result->estimated_sort_rows = plan_rows * Max(sort_loops, 1.0);
	result->estimated_sort_width = (int)
		extract_json_double_before(sort, plans, "\"Plan Width\"", -1.0);
	result->sort_space_used_kb =
		extract_json_double_before(sort, plans, "\"Sort Space Used\"", -1.0);
	result->sort_method =
		extract_json_string_before(sort, plans, "\"Sort Method\"");
	result->sort_space_type =
		extract_json_string_before(sort, plans, "\"Sort Space Type\"");

	/*
	 * A bounded Sort reports only the rows retained by top-N.  Its first
	 * child reports all rows presented to the Sort, so use child rows times
	 * loops as the execution-time counterpart of Plan Rows.
	 */
	if (plans == NULL)
		return;
	child = strstr(plans, "\"Node Type\"");
	if (child == NULL)
		return;
	child_plans = strstr(child, "\"Plans\"");
	child_rows = extract_json_double_before(child, child_plans,
										 "\"Actual Rows\"", -1.0);
	child_loops = extract_json_double_before(child, child_plans,
										  "\"Actual Loops\"", -1.0);
	if (child_rows >= 0.0 && child_loops >= 0.0)
		result->actual_sort_input_rows = child_rows * child_loops;
}

static void
free_explain_strings(ExplainResult *result)
{
	if (result->sort_method != NULL)
		pfree(result->sort_method);
	if (result->sort_space_type != NULL)
		pfree(result->sort_space_type);
	if (result->sort_output_signature != NULL)
		pfree(result->sort_output_signature);
	pfree(result->nodes);
}

/*
 * palloc() allocations made after SPI_connect() belong to SPI's private
 * context and are destroyed by SPI_finish().  topnbench_compare() constructs
 * its result row after disconnecting, so copy retained plan strings into the
 * upper executor context first.
 */
static char *
spi_pstrdup_nullable(const char *value)
{
	char	   *copy;
	Size		length;

	if (value == NULL)
		return NULL;

	length = strlen(value) + 1;
	copy = SPI_palloc(length);
	memcpy(copy, value, length);
	return copy;
}

static void
copy_strategy_strings_to_upper_context(StrategyResult *result)
{
	result->nodes = spi_pstrdup_nullable(result->nodes);
	result->sort_output_signature =
		spi_pstrdup_nullable(result->sort_output_signature);
	result->manual_late_sort_output_signature =
		spi_pstrdup_nullable(result->manual_late_sort_output_signature);
	result->forced_early_sort_output_signature =
		spi_pstrdup_nullable(result->forced_early_sort_output_signature);
	result->sort_method = spi_pstrdup_nullable(result->sort_method);
	result->sort_space_type = spi_pstrdup_nullable(result->sort_space_type);
	result->manual_late_sort_method =
		spi_pstrdup_nullable(result->manual_late_sort_method);
	result->manual_late_sort_space_type =
		spi_pstrdup_nullable(result->manual_late_sort_space_type);
	result->forced_early_sort_method =
		spi_pstrdup_nullable(result->forced_early_sort_method);
	result->forced_early_sort_space_type =
		spi_pstrdup_nullable(result->forced_early_sort_space_type);
}

static ExplainResult
run_explain(const char *query)
{
	ExplainResult result;
	StringInfoData sql;
	char	   *json;
	int			rc;

	initStringInfo(&sql);
	appendStringInfo(&sql,
					 "EXPLAIN (ANALYZE, VERBOSE, COSTS ON, TIMING OFF, "
					 "SUMMARY ON, FORMAT JSON) %s", query);

	MemSet(&captured_candidate_costs, 0, sizeof(captured_candidate_costs));
	capture_candidate_costs = true;

	/* EXPLAIN is a utility statement, even though the wrapped query is SELECT. */
	rc = SPI_execute(sql.data, false, 0);
	capture_candidate_costs = false;
	if (rc != SPI_OK_UTILITY || SPI_processed != 1 || SPI_tuptable == NULL)
		ereport(ERROR,
				(errmsg("could not execute benchmark EXPLAIN: SPI result %s",
						SPI_result_code_string(rc))));

	json = SPI_getvalue(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 1);
	if (json == NULL)
		ereport(ERROR, (errmsg("benchmark EXPLAIN returned NULL")));

	result.milliseconds = extract_json_double(json, "\"Execution Time\"", -1.0);
	if (result.milliseconds < 0)
		ereport(ERROR, (errmsg("could not read Execution Time from EXPLAIN JSON")));
	result.startup_cost = extract_json_double(json, "\"Startup Cost\"", -1.0);
	result.total_cost = extract_json_double(json, "\"Total Cost\"", -1.0);
	result.launched_workers = extract_max_workers(json);
	result.sort_output_columns = extract_sort_output_columns(json);
	result.sort_output_signature = extract_sort_output_signature(json);
	extract_sort_metadata(json, &result);
	result.nodes = extract_plan_nodes(json);
	result.candidates = captured_candidate_costs;

	SPI_freetuptable(SPI_tuptable);
	pfree(sql.data);
	return result;
}

static int
compare_double(const void *left, const void *right)
{
	double		a = *((const double *) left);
	double		b = *((const double *) right);

	return (a > b) - (a < b);
}

static TimingSummary
summarize_timings(double *values, int nvalues)
{
	TimingSummary result;

	Assert(nvalues > 0);
	qsort(values, nvalues, sizeof(double), compare_double);
	result.minimum = values[0];
	if (nvalues % 2 == 0)
		result.median = (values[nvalues / 2 - 1] + values[nvalues / 2]) / 2.0;
	else
		result.median = values[nvalues / 2];

	return result;
}

static void
verify_equivalent(const char *auto_query, const char *manual_query)
{
	StringInfoData sql;
	bool		isnull;
	Datum		value;
	int			rc;

	initStringInfo(&sql);
	appendStringInfo(&sql,
					 "SELECT NOT EXISTS (SELECT 1 FROM ("
					 "((SELECT * FROM (%s) AS auto_result) "
					 " EXCEPT ALL "
					 " (SELECT * FROM (%s) AS manual_result)) UNION ALL "
					 "((SELECT * FROM (%s) AS manual_result) "
					 " EXCEPT ALL "
					 " (SELECT * FROM (%s) AS auto_result))) AS differences)",
					 auto_query, manual_query, manual_query, auto_query);

	rc = SPI_execute(sql.data, true, 1);
	if (rc != SPI_OK_SELECT || SPI_processed != 1 || SPI_tuptable == NULL)
		ereport(ERROR,
				(errmsg("could not verify benchmark queries: SPI result %s",
						SPI_result_code_string(rc))));

	value = SPI_getbinval(SPI_tuptable->vals[0], SPI_tuptable->tupdesc,
						  1, &isnull);
	if (isnull || !DatumGetBool(value))
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("benchmark queries returned different results")));

	SPI_freetuptable(SPI_tuptable);
	pfree(sql.data);
}

static StrategyResult
run_three(const char *auto_query, const char *manual_query,
		  const char *forced_early_query, int iterations, bool verify)
{
	StrategyResult result;
	double	   *auto_times = palloc_array(double, iterations);
	double	   *manual_times = palloc_array(double, iterations);
	double	   *forced_early_times = palloc_array(double, iterations);

	if (verify)
	{
		verify_equivalent(auto_query, manual_query);
		verify_equivalent(auto_query, forced_early_query);
	}

	/* Untimed warmup for all three strategies. */
	{
		ExplainResult warmup;

		warmup = run_explain(auto_query);
		result.launched_workers = warmup.launched_workers;
		result.sort_output_columns = warmup.sort_output_columns;
		result.sort_output_signature = warmup.sort_output_signature;
		result.estimated_sort_rows = warmup.estimated_sort_rows;
		result.actual_sort_input_rows = warmup.actual_sort_input_rows;
		result.estimated_sort_width = warmup.estimated_sort_width;
		result.sort_space_used_kb = warmup.sort_space_used_kb;
		result.sort_method = warmup.sort_method;
		result.sort_space_type = warmup.sort_space_type;
		result.nodes = warmup.nodes;
		result.candidates = warmup.candidates;
		warmup = run_explain(manual_query);
		result.manual_late_sort_space_used_kb = warmup.sort_space_used_kb;
		result.manual_late_sort_method = warmup.sort_method;
		result.manual_late_sort_space_type = warmup.sort_space_type;
		result.manual_late_sort_output_signature = warmup.sort_output_signature;
		pfree(warmup.nodes);
		warmup = run_explain(forced_early_query);
		result.forced_early_sort_space_used_kb = warmup.sort_space_used_kb;
		result.forced_early_sort_method = warmup.sort_method;
		result.forced_early_sort_space_type = warmup.sort_space_type;
		result.forced_early_sort_output_signature = warmup.sort_output_signature;
		pfree(warmup.nodes);
	}

	for (int r = 0; r < iterations; r++)
	{
		for (int k = 0; k < 3; k++)
		{
			int			which = (k + r) % 3;
			ExplainResult measured;

			CHECK_FOR_INTERRUPTS();
			if (which == 0)
			{
				measured = run_explain(auto_query);
				auto_times[r] = measured.milliseconds;
				free_explain_strings(&measured);
			}
			else if (which == 1)
			{
				measured = run_explain(manual_query);
				manual_times[r] = measured.milliseconds;
				free_explain_strings(&measured);
			}
			else
			{
				measured = run_explain(forced_early_query);
				forced_early_times[r] = measured.milliseconds;
				free_explain_strings(&measured);
			}
		}
	}

	result.auto_timing = summarize_timings(auto_times, iterations);
	result.manual_timing = summarize_timings(manual_times, iterations);
	result.forced_early_timing =
		summarize_timings(forced_early_times, iterations);
	pfree(auto_times);
	pfree(manual_times);
	pfree(forced_early_times);

	return result;
}

static void
set_local_int(const char *name, int value)
{
	StringInfoData sql;
	int			rc;

	initStringInfo(&sql);
	appendStringInfo(&sql, "SET LOCAL %s = %d", name, value);
	rc = SPI_execute(sql.data, false, 0);
	if (rc != SPI_OK_UTILITY)
		ereport(ERROR, (errmsg("could not set %s", name)));
	pfree(sql.data);
}

static void
set_local(const char *name, const char *value)
{
	StringInfoData sql;
	int			rc;

	initStringInfo(&sql);
	appendStringInfo(&sql, "SET LOCAL %s = %s", name, value);
	rc = SPI_execute(sql.data, false, 0);
	if (rc != SPI_OK_UTILITY)
		ereport(ERROR, (errmsg("could not set %s", name)));
	pfree(sql.data);
}

static char *
qualified_function_name(Oid benchmark_function_oid, int declared_cost)
{
	Oid			nspoid = get_func_namespace(benchmark_function_oid);
	char	   *nspname = get_namespace_name(nspoid);
	char		funcname[NAMEDATALEN];

	if (nspname == NULL)
		elog(ERROR, "cache lookup failed for namespace %u", nspoid);

	snprintf(funcname, sizeof(funcname), "topnbench_work_cost_%d",
			 declared_cost);
	return quote_qualified_identifier(nspname, funcname);
}

static int
target_count(const BenchCase *benchcase)
{
	return benchcase->shape == EXPR_NESTED ? 1 : benchcase->expression_steps;
}

static const char *
shape_name(ExpressionShape shape)
{
	return shape == EXPR_NESTED ? "nested" : "independent";
}

static void
append_expression(StringInfo query, const char *function_name,
				  const char *argument, int work_rounds, int salt)
{
	appendStringInfo(query, "%s(%s, %d, %d)", function_name, argument,
				 work_rounds, salt);
}

static void
append_nested_expression(StringInfo query, const char *function_name,
					 const char *argument, int work_rounds, int steps)
{
	for (int i = 0; i < steps; i++)
		appendStringInfo(query, "%s(", function_name);
	appendStringInfoString(query, argument);
	for (int i = steps; i > 0; i--)
		appendStringInfo(query, ", %d, %d)", work_rounds, i);
}

static void
append_target_expressions(StringInfo query, const char *function_name,
					  const char *argument, const BenchCase *benchcase)
{
	if (benchcase->shape == EXPR_NESTED)
	{
		appendStringInfoString(query, ", ");
		append_nested_expression(query, function_name, argument,
							 benchcase->work_rounds,
							 benchcase->expression_steps);
		appendStringInfoString(query, " AS e1");
	}
	else
	{
		for (int i = 0; i < benchcase->expression_steps; i++)
		{
			appendStringInfoString(query, ", ");
			append_expression(query, function_name, argument,
						  benchcase->work_rounds, i + 1);
			appendStringInfo(query, " AS e%d", i + 1);
		}
	}
}

static void
build_queries(StringInfo auto_query, StringInfo manual_query,
			  StringInfo forced_early_query,
			  const char *relation_name, const char *column_name,
			  const char *function_name, const BenchCase *benchcase,
			  int64 offset_rows, int64 limit_rows, int64 sort_rows)
{
	int			nexpressions = target_count(benchcase);

	resetStringInfo(auto_query);
	resetStringInfo(manual_query);
	resetStringInfo(forced_early_query);

	appendStringInfo(auto_query, "SELECT %s AS k", column_name);
	appendStringInfo(manual_query, "SELECT s.k");
	appendStringInfo(forced_early_query, "SELECT %s AS k", column_name);
	append_target_expressions(auto_query, function_name, column_name, benchcase);
	append_target_expressions(manual_query, function_name, "s.k", benchcase);
	append_target_expressions(forced_early_query, function_name, column_name,
						  benchcase);

	appendStringInfo(auto_query, " FROM %s ORDER BY %s",
					 relation_name, column_name);
	if (offset_rows > 0)
		appendStringInfo(auto_query, " OFFSET " INT64_FORMAT, offset_rows);
	appendStringInfo(auto_query, " LIMIT " INT64_FORMAT, limit_rows);

	appendStringInfo(manual_query,
					 " FROM (SELECT %s AS k FROM %s ORDER BY %s LIMIT "
					 INT64_FORMAT ") AS s",
					 column_name, relation_name, column_name, sort_rows);
	if (offset_rows > 0)
		appendStringInfo(manual_query, " OFFSET " INT64_FORMAT, offset_rows);
	appendStringInfo(manual_query, " LIMIT " INT64_FORMAT, limit_rows);

	/*
	 * Adding the projected expressions as secondary sort keys gives them a
	 * sortgroupref, which forces evaluation below the Sort.  Because every
	 * expression is a deterministic function of the leading key, this does
	 * not change the ordering of rows tied on that key.  It also preserves
	 * the Sort -> Gather Merge shape of a parallel plan.
	 */
	appendStringInfo(forced_early_query, " FROM %s ORDER BY %s",
					 relation_name, column_name);
	for (int i = 0; i < nexpressions; i++)
		appendStringInfo(forced_early_query, ", e%d", i + 1);
	if (offset_rows > 0)
		appendStringInfo(forced_early_query, " OFFSET " INT64_FORMAT,
						 offset_rows);
	appendStringInfo(forced_early_query, " LIMIT " INT64_FORMAT, limit_rows);
}

static int64
relation_row_count(const char *relation_name)
{
	StringInfoData sql;
	bool		isnull;
	Datum		value;
	int			rc;

	initStringInfo(&sql);
	appendStringInfo(&sql, "SELECT count(*)::bigint FROM %s", relation_name);
	rc = SPI_execute(sql.data, true, 1);
	if (rc != SPI_OK_SELECT || SPI_processed != 1)
		ereport(ERROR, (errmsg("could not count benchmark relation")));

	value = SPI_getbinval(SPI_tuptable->vals[0], SPI_tuptable->tupdesc,
						  1, &isnull);
	if (isnull)
		ereport(ERROR, (errmsg("benchmark row count is NULL")));

	SPI_freetuptable(SPI_tuptable);
	pfree(sql.data);
	return DatumGetInt64(value);
}

static int64
case_rows(int64 nrows, int fraction_ppm, bool at_least_one)
{
	int64		rows;
	int64		whole = nrows / 1000000;
	int64		remainder = nrows % 1000000;

	/* Exact ceiling division without overflowing nrows * fraction_ppm. */
	rows = whole * fraction_ppm +
		(remainder * fraction_ppm + 999999) / 1000000;
	if (at_least_one)
		rows = Max(INT64CONST(1), rows);

	return Min(nrows, rows);
}

static const char *
projection_choice(const StrategyResult *result)
{
	bool		matches_late;
	bool		matches_early;
	char	   *auto_signature;
	char	   *late_signature;
	char	   *early_signature;

	if (result->sort_output_signature == NULL ||
		result->manual_late_sort_output_signature == NULL ||
		result->forced_early_sort_output_signature == NULL)
		return "unknown";

	auto_signature = canonicalize_sort_output_signature(
		result->sort_output_signature);
	late_signature = canonicalize_sort_output_signature(
		result->manual_late_sort_output_signature);
	early_signature = canonicalize_sort_output_signature(
		result->forced_early_sort_output_signature);
	matches_late = strcmp(auto_signature, late_signature) == 0;
	matches_early = strcmp(auto_signature, early_signature) == 0;
	pfree(auto_signature);
	pfree(late_signature);
	pfree(early_signature);

	if (matches_late && !matches_early)
		return "late";
	if (matches_early && !matches_late)
		return "early";
	return "unknown";
}

static const char *
actual_winner(double late_ms, double early_ms)
{
	double		best = Min(late_ms, early_ms);

	if (fabs(late_ms - early_ms) <= best * DECISION_NOISE_FRACTION)
		return "tie";
	return late_ms < early_ms ? "late" : "early";
}

static const char *
model_choice(double expression_weight, int64 input_rows, int64 sort_rows)
{
	double		discarded_rows = (double) input_rows - (double) sort_rows;

	if (expression_weight * discarded_rows > 10.0 * (double) sort_rows)
		return "late";
	return "early";
}

static double
choice_regression_ratio(const char *choice, double late_ms, double early_ms)
{
	double		best = Min(late_ms, early_ms);

	if (strcmp(choice, "late") == 0)
		return late_ms / best;
	if (strcmp(choice, "early") == 0)
		return early_ms / best;
	return -1.0;
}

static void
set_correctness(Datum *value, bool *isnull, const char *choice,
				const char *winner)
{
	if (strcmp(choice, "unknown") == 0 || strcmp(winner, "tie") == 0)
	{
		*value = BoolGetDatum(false);
		*isnull = true;
	}
	else
	{
		*value = BoolGetDatum(strcmp(choice, winner) == 0);
		*isnull = false;
	}
}

static const char *
decision_class(const char *choice, const char *winner)
{
	if (strcmp(choice, "unknown") == 0)
		return "unknown";
	if (strcmp(winner, "tie") == 0)
		return "tie";
	if (strcmp(choice, winner) == 0)
		return "correct";
	return strcmp(choice, "late") == 0 ? "false-late" : "false-early";
}

static const char *
lower_limit_cost_choice(const CandidateCosts *candidates)
{
	const CandidateCost *early = &candidates->early;
	const CandidateCost *late = &candidates->late;

	if (!early->valid || !late->valid)
		return "unknown";
	return early->limit_cost <= late->limit_cost ? "early" : "late";
}

/* Append the thirteen SQL-visible candidate-cost diagnostics at start. */
static void
set_candidate_cost_values(Datum *values, bool *nulls, int start,
					  const CandidateCosts *candidates)
{
	const CandidateCost *early = &candidates->early;
	const CandidateCost *late = &candidates->late;

	values[start] = CStringGetTextDatum(lower_limit_cost_choice(candidates));
	if (early->valid && late->valid)
		values[start + 1] = BoolGetDatum(
			early->limit_cost <= late->limit_cost * 1.01 &&
			late->limit_cost <= early->limit_cost * 1.01);
	else
		nulls[start + 1] = true;
	if (early->valid)
	{
		values[start + 2] = Float8GetDatum(early->startup_cost);
		values[start + 3] = Float8GetDatum(early->total_cost);
		values[start + 4] = Float8GetDatum(early->limit_cost);
		values[start + 5] = Float8GetDatum(early->sort_rows);
		values[start + 6] = Int32GetDatum(early->sort_width);
	}
	else
	{
		for (int i = 2; i <= 6; i++)
			nulls[start + i] = true;
	}
	if (late->valid)
	{
		values[start + 7] = Float8GetDatum(late->startup_cost);
		values[start + 8] = Float8GetDatum(late->total_cost);
		values[start + 9] = Float8GetDatum(late->limit_cost);
		values[start + 10] = Float8GetDatum(late->sort_rows);
		values[start + 11] = Int32GetDatum(late->sort_width);
	}
	else
	{
		for (int i = 7; i <= 11; i++)
			nulls[start + i] = true;
	}
	if (early->valid && late->valid && early->limit_cost > 0.0)
		values[start + 12] = Float8GetDatum(late->limit_cost /
										 early->limit_cost);
	else
		nulls[start + 12] = true;
}

static void
emit_run_case(FunctionCallInfo fcinfo, const BenchCase *benchcase,
			  int64 nrows, const char *relation_name, const char *column_name,
			  int iterations, bool verify)
{
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	StringInfoData auto_query;
	StringInfoData manual_query;
	StringInfoData forced_early_query;
	char	   *function_name;
	StrategyResult result;
	Datum		values[60];
	bool		nulls[60] = {false};
	int64		offset_rows = case_rows(nrows, benchcase->offset_ppm, false);
	int64		limit_rows = case_rows(nrows, benchcase->limit_ppm, true);
	int64		sort_rows;
	const char *planner_choice;
	const char *winner;
	const char *cost_choice;
	const char *structural_choice;
	double		best_ms;
	double		choice_regression;

	if (offset_rows >= nrows)
		offset_rows = nrows - 1;
	limit_rows = Min(limit_rows, nrows - offset_rows);
	sort_rows = offset_rows + limit_rows;

	set_local_int("max_parallel_workers_per_gather", benchcase->workers);
	function_name = qualified_function_name(fcinfo->flinfo->fn_oid,
											 benchcase->declared_cost);

	initStringInfo(&auto_query);
	initStringInfo(&manual_query);
	initStringInfo(&forced_early_query);
	build_queries(&auto_query, &manual_query, &forced_early_query,
				  relation_name, column_name,
				  function_name, benchcase, offset_rows, limit_rows, sort_rows);

	result = run_three(auto_query.data, manual_query.data,
				   forced_early_query.data, iterations, verify);
	planner_choice = projection_choice(&result);
	winner = actual_winner(result.manual_timing.median,
						   result.forced_early_timing.median);
	cost_choice = model_choice((double) benchcase->expression_steps *
						   (double) benchcase->declared_cost,
						   nrows, sort_rows);
	structural_choice = model_choice((double) benchcase->expression_steps,
								 nrows, sort_rows);
	best_ms = Min(result.manual_timing.median,
				  result.forced_early_timing.median);
	choice_regression = choice_regression_ratio(planner_choice,
										 result.manual_timing.median,
										 result.forced_early_timing.median);

	values[0] = CStringGetTextDatum(benchcase->name);
	values[1] = Int64GetDatum(nrows);
	values[2] = Int64GetDatum(offset_rows);
	values[3] = Int64GetDatum(limit_rows);
	values[4] = Int64GetDatum(sort_rows);
	values[5] = Float8GetDatum((double) sort_rows / (double) nrows);
	values[6] = CStringGetTextDatum(shape_name(benchcase->shape));
	values[7] = Int32GetDatum(target_count(benchcase));
	values[8] = Int32GetDatum(benchcase->expression_steps);
	values[9] = Int32GetDatum(benchcase->declared_cost);
	values[10] = Int32GetDatum(benchcase->work_rounds);
	values[11] = Int32GetDatum(benchcase->workers);
	values[12] = Int32GetDatum(result.launched_workers);
	values[13] = CStringGetTextDatum(result.nodes);
	if (result.estimated_sort_rows < 0.0)
		nulls[14] = true;
	else
		values[14] = Float8GetDatum(result.estimated_sort_rows);
	if (result.actual_sort_input_rows < 0.0)
		nulls[15] = true;
	else
		values[15] = Float8GetDatum(result.actual_sort_input_rows);
	if (result.launched_workers > 0 ||
		result.estimated_sort_rows <= 0.0 ||
		result.actual_sort_input_rows < 0.0)
		nulls[16] = true;
	else
		values[16] = Float8GetDatum(result.actual_sort_input_rows /
										result.estimated_sort_rows);
	if (result.estimated_sort_width < 0)
		nulls[17] = true;
	else
		values[17] = Int32GetDatum(result.estimated_sort_width);
	if (result.sort_method == NULL)
		nulls[18] = true;
	else
		values[18] = CStringGetTextDatum(result.sort_method);
	if (result.sort_space_type == NULL)
		nulls[19] = true;
	else
		values[19] = CStringGetTextDatum(result.sort_space_type);
	if (result.sort_space_used_kb < 0.0)
		nulls[20] = true;
	else
		values[20] = Float8GetDatum(result.sort_space_used_kb);
	values[21] = CStringGetTextDatum(planner_choice);
	values[22] = Float8GetDatum(result.auto_timing.minimum);
	values[23] = Float8GetDatum(result.auto_timing.median);
	values[24] = Float8GetDatum(result.manual_timing.minimum);
	values[25] = Float8GetDatum(result.manual_timing.median);
	values[26] = Float8GetDatum(result.forced_early_timing.minimum);
	values[27] = Float8GetDatum(result.forced_early_timing.median);
	values[28] = CStringGetTextDatum(winner);
	set_correctness(&values[29], &nulls[29], planner_choice, winner);
	values[30] = Float8GetDatum(result.auto_timing.median / best_ms);
	if (choice_regression < 0)
		nulls[31] = true;
	else
		values[31] = Float8GetDatum(choice_regression);
	values[32] = Float8GetDatum(result.forced_early_timing.median /
								result.manual_timing.median);
	values[33] = CStringGetTextDatum(cost_choice);
	set_correctness(&values[34], &nulls[34], cost_choice, winner);
	values[35] = CStringGetTextDatum(structural_choice);
	set_correctness(&values[36], &nulls[36], structural_choice, winner);
	if (result.manual_late_sort_method == NULL)
		nulls[37] = true;
	else
		values[37] = CStringGetTextDatum(result.manual_late_sort_method);
	if (result.manual_late_sort_space_type == NULL)
		nulls[38] = true;
	else
		values[38] = CStringGetTextDatum(result.manual_late_sort_space_type);
	if (result.manual_late_sort_space_used_kb < 0.0)
		nulls[39] = true;
	else
		values[39] = Float8GetDatum(result.manual_late_sort_space_used_kb);
	if (result.forced_early_sort_method == NULL)
		nulls[40] = true;
	else
		values[40] = CStringGetTextDatum(result.forced_early_sort_method);
	if (result.forced_early_sort_space_type == NULL)
		nulls[41] = true;
	else
		values[41] = CStringGetTextDatum(result.forced_early_sort_space_type);
	if (result.forced_early_sort_space_used_kb < 0.0)
		nulls[42] = true;
	else
		values[42] = Float8GetDatum(result.forced_early_sort_space_used_kb);
	values[43] = CStringGetTextDatum(decision_class(planner_choice, winner));
	if (result.sort_output_signature == NULL)
		nulls[44] = true;
	else
		values[44] = CStringGetTextDatum(result.sort_output_signature);
	if (result.manual_late_sort_output_signature == NULL)
		nulls[45] = true;
	else
		values[45] = CStringGetTextDatum(
			result.manual_late_sort_output_signature);
	if (result.forced_early_sort_output_signature == NULL)
		nulls[46] = true;
	else
		values[46] = CStringGetTextDatum(
			result.forced_early_sort_output_signature);
	set_candidate_cost_values(values, nulls, 47, &result.candidates);

	tuplestore_putvalues(rsinfo->setResult, rsinfo->setDesc, values, nulls);

	pfree(auto_query.data);
	pfree(manual_query.data);
	pfree(forced_early_query.data);
	pfree(function_name);
	if (result.sort_method != NULL)
		pfree(result.sort_method);
	if (result.sort_space_type != NULL)
		pfree(result.sort_space_type);
	if (result.sort_output_signature != NULL)
		pfree(result.sort_output_signature);
	if (result.manual_late_sort_output_signature != NULL)
		pfree(result.manual_late_sort_output_signature);
	if (result.forced_early_sort_output_signature != NULL)
		pfree(result.forced_early_sort_output_signature);
	if (result.manual_late_sort_method != NULL)
		pfree(result.manual_late_sort_method);
	if (result.manual_late_sort_space_type != NULL)
		pfree(result.manual_late_sort_space_type);
	if (result.forced_early_sort_method != NULL)
		pfree(result.forced_early_sort_method);
	if (result.forced_early_sort_space_type != NULL)
		pfree(result.forced_early_sort_space_type);
	pfree(result.nodes);
}

Datum
topnbench_run(PG_FUNCTION_ARGS)
{
	Oid			relid = PG_GETARG_OID(0);
	char	   *column = NameStr(*PG_GETARG_NAME(1));
	int			iterations = PG_GETARG_INT32(2);
	char	   *profile = text_to_cstring(PG_GETARG_TEXT_PP(3));
	bool		verify = PG_GETARG_BOOL(4);
	char	   *relname;
	char	   *nspname;
	char	   *qualified_relation;
	const char *quoted_column;
	int64		nrows;
	AttrNumber	attnum;
	int			save_nestlevel;

	if (iterations < 1 || iterations > 100)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("iterations must be between 1 and 100")));
	if (strcmp(profile, "quick") != 0 && strcmp(profile, "confidence") != 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("profile must be \"quick\" or \"confidence\"")));

	relname = get_rel_name(relid);
	nspname = get_namespace_name(get_rel_namespace(relid));
	if (relname == NULL || nspname == NULL)
		ereport(ERROR, (errmsg("relation with OID %u does not exist", relid)));

	attnum = get_attnum(relid, column);
	if (attnum == InvalidAttrNumber || get_atttype(relid, attnum) != INT4OID)
		ereport(ERROR,
				(errcode(ERRCODE_DATATYPE_MISMATCH),
				 errmsg("benchmark key column must exist and have type integer")));

	qualified_relation = quote_qualified_identifier(nspname, relname);
	quoted_column = quote_identifier(column);

	InitMaterializedSRF(fcinfo, 0);

	if (SPI_connect() != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed");
	save_nestlevel = NewGUCNestLevel();

	PG_TRY();
	{
		set_local("jit", "off");
		nrows = relation_row_count(qualified_relation);
		if (nrows <= 0)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
					 errmsg("benchmark relation must not be empty")));

		for (int i = 0; i < lengthof(quick_cases); i++)
			emit_run_case(fcinfo, &quick_cases[i], nrows,
						  qualified_relation, quoted_column, iterations, verify);

		if (strcmp(profile, "confidence") == 0)
		{
			for (int i = 0; i < lengthof(confidence_extra_cases); i++)
				emit_run_case(fcinfo, &confidence_extra_cases[i], nrows,
							  qualified_relation, quoted_column, iterations, verify);
		}
	}
	PG_CATCH();
	{
		AtEOXact_GUC(false, save_nestlevel);
		SPI_finish();
		PG_RE_THROW();
	}
	PG_END_TRY();

	AtEOXact_GUC(false, save_nestlevel);
	if (SPI_finish() != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed");

	return (Datum) 0;
}

Datum
topnbench_compare(PG_FUNCTION_ARGS)
{
	char	   *auto_query = text_to_cstring(PG_GETARG_TEXT_PP(0));
	char	   *manual_query = text_to_cstring(PG_GETARG_TEXT_PP(1));
	char	   *forced_early_query = text_to_cstring(PG_GETARG_TEXT_PP(2));
	int			iterations = PG_GETARG_INT32(3);
	bool		verify = PG_GETARG_BOOL(4);
	char	   *work_mem_setting =
		(PG_NARGS() > 5 && !PG_ARGISNULL(5)) ?
		text_to_cstring(PG_GETARG_TEXT_PP(5)) : NULL;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	StrategyResult result;
	Datum		values[44];
	bool		nulls[44] = {false};
	const char *planner_choice;
	const char *winner;
	double		best_ms;
	double		choice_regression;
	int			save_nestlevel;

	if (iterations < 1 || iterations > 100)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("iterations must be between 1 and 100")));
	validate_select(auto_query);
	validate_select(manual_query);
	validate_select(forced_early_query);

	InitMaterializedSRF(fcinfo, 0);
	if (SPI_connect() != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed");
	save_nestlevel = NewGUCNestLevel();

	PG_TRY();
	{
		if (work_mem_setting != NULL)
		{
			char	   *quoted = quote_literal_cstr(work_mem_setting);

			set_local("work_mem", quoted);
			pfree(quoted);
		}
		set_local("jit", "off");
		result = run_three(auto_query, manual_query, forced_early_query,
					   iterations, verify);
		copy_strategy_strings_to_upper_context(&result);
	}
	PG_CATCH();
	{
		AtEOXact_GUC(false, save_nestlevel);
		SPI_finish();
		PG_RE_THROW();
	}
	PG_END_TRY();

	AtEOXact_GUC(false, save_nestlevel);
	if (SPI_finish() != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed");

	planner_choice = projection_choice(&result);
	winner = actual_winner(result.manual_timing.median,
						   result.forced_early_timing.median);
	best_ms = Min(result.manual_timing.median,
				  result.forced_early_timing.median);
	choice_regression = choice_regression_ratio(planner_choice,
										 result.manual_timing.median,
										 result.forced_early_timing.median);

	values[0] = CStringGetTextDatum(result.nodes);
	values[1] = Int32GetDatum(result.launched_workers);
	if (result.estimated_sort_rows < 0.0)
		nulls[2] = true;
	else
		values[2] = Float8GetDatum(result.estimated_sort_rows);
	if (result.actual_sort_input_rows < 0.0)
		nulls[3] = true;
	else
		values[3] = Float8GetDatum(result.actual_sort_input_rows);
	if (result.launched_workers > 0 ||
		result.estimated_sort_rows <= 0.0 ||
		result.actual_sort_input_rows < 0.0)
		nulls[4] = true;
	else
		values[4] = Float8GetDatum(result.actual_sort_input_rows /
									 result.estimated_sort_rows);
	if (result.estimated_sort_width < 0)
		nulls[5] = true;
	else
		values[5] = Int32GetDatum(result.estimated_sort_width);
	if (result.sort_method == NULL)
		nulls[6] = true;
	else
		values[6] = CStringGetTextDatum(result.sort_method);
	if (result.sort_space_type == NULL)
		nulls[7] = true;
	else
		values[7] = CStringGetTextDatum(result.sort_space_type);
	if (result.sort_space_used_kb < 0.0)
		nulls[8] = true;
	else
		values[8] = Float8GetDatum(result.sort_space_used_kb);
	values[9] = CStringGetTextDatum(planner_choice);
	values[10] = Float8GetDatum(result.auto_timing.minimum);
	values[11] = Float8GetDatum(result.auto_timing.median);
	values[12] = Float8GetDatum(result.manual_timing.minimum);
	values[13] = Float8GetDatum(result.manual_timing.median);
	values[14] = Float8GetDatum(result.forced_early_timing.minimum);
	values[15] = Float8GetDatum(result.forced_early_timing.median);
	values[16] = CStringGetTextDatum(winner);
	set_correctness(&values[17], &nulls[17], planner_choice, winner);
	values[18] = Float8GetDatum(result.auto_timing.median / best_ms);
	if (choice_regression < 0)
		nulls[19] = true;
	else
		values[19] = Float8GetDatum(choice_regression);
	values[20] = Float8GetDatum(result.forced_early_timing.median /
								result.manual_timing.median);
	if (result.manual_late_sort_method == NULL)
		nulls[21] = true;
	else
		values[21] = CStringGetTextDatum(result.manual_late_sort_method);
	if (result.manual_late_sort_space_type == NULL)
		nulls[22] = true;
	else
		values[22] = CStringGetTextDatum(result.manual_late_sort_space_type);
	if (result.manual_late_sort_space_used_kb < 0.0)
		nulls[23] = true;
	else
		values[23] = Float8GetDatum(result.manual_late_sort_space_used_kb);
	if (result.forced_early_sort_method == NULL)
		nulls[24] = true;
	else
		values[24] = CStringGetTextDatum(result.forced_early_sort_method);
	if (result.forced_early_sort_space_type == NULL)
		nulls[25] = true;
	else
		values[25] = CStringGetTextDatum(result.forced_early_sort_space_type);
	if (result.forced_early_sort_space_used_kb < 0.0)
		nulls[26] = true;
	else
		values[26] = Float8GetDatum(result.forced_early_sort_space_used_kb);
	values[27] = CStringGetTextDatum(decision_class(planner_choice, winner));
	if (result.sort_output_signature == NULL)
		nulls[28] = true;
	else
		values[28] = CStringGetTextDatum(result.sort_output_signature);
	if (result.manual_late_sort_output_signature == NULL)
		nulls[29] = true;
	else
		values[29] = CStringGetTextDatum(
			result.manual_late_sort_output_signature);
	if (result.forced_early_sort_output_signature == NULL)
		nulls[30] = true;
	else
		values[30] = CStringGetTextDatum(
			result.forced_early_sort_output_signature);
	set_candidate_cost_values(values, nulls, 31, &result.candidates);
	tuplestore_putvalues(rsinfo->setResult, rsinfo->setDesc, values, nulls);
	if (result.sort_method != NULL)
		pfree(result.sort_method);
	if (result.sort_space_type != NULL)
		pfree(result.sort_space_type);
	if (result.sort_output_signature != NULL)
		pfree(result.sort_output_signature);
	if (result.manual_late_sort_output_signature != NULL)
		pfree(result.manual_late_sort_output_signature);
	if (result.forced_early_sort_output_signature != NULL)
		pfree(result.forced_early_sort_output_signature);
	if (result.manual_late_sort_method != NULL)
		pfree(result.manual_late_sort_method);
	if (result.manual_late_sort_space_type != NULL)
		pfree(result.manual_late_sort_space_type);
	if (result.forced_early_sort_method != NULL)
		pfree(result.forced_early_sort_method);
	if (result.forced_early_sort_space_type != NULL)
		pfree(result.forced_early_sort_space_type);
	pfree(result.nodes);

	return (Datum) 0;
}

/*
 * Measure one query without constructing early/late rewrites.  This is used
 * by benchmark.sql to compare narrow and wide Sort inputs while keeping the
 * scan, key distribution, LIMIT, and executor instrumentation identical.
 */
Datum
topnbench_measure(PG_FUNCTION_ARGS)
{
	char	   *query = text_to_cstring(PG_GETARG_TEXT_PP(0));
	int			iterations = PG_GETARG_INT32(1);
	char	   *work_mem_setting =
		(PG_NARGS() > 2 && !PG_ARGISNULL(2)) ?
		text_to_cstring(PG_GETARG_TEXT_PP(2)) : NULL;
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	ExplainResult warmup;
	TimingSummary timing;
	double	   *times;
	char	   *nodes = NULL;
	char	   *sort_method = NULL;
	char	   *sort_space_type = NULL;
	Datum		values[12];
	bool		nulls[12] = {false};
	int			save_nestlevel;

	if (iterations < 1 || iterations > 100)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("iterations must be between 1 and 100")));
	validate_select(query);

	InitMaterializedSRF(fcinfo, 0);
	if (SPI_connect() != SPI_OK_CONNECT)
		elog(ERROR, "SPI_connect failed");
	save_nestlevel = NewGUCNestLevel();

	PG_TRY();
	{
		if (work_mem_setting != NULL)
		{
			char	   *quoted = quote_literal_cstr(work_mem_setting);

			set_local("work_mem", quoted);
			pfree(quoted);
		}
		set_local("jit", "off");

		warmup = run_explain(query);
		nodes = spi_pstrdup_nullable(warmup.nodes);
		sort_method = spi_pstrdup_nullable(warmup.sort_method);
		sort_space_type = spi_pstrdup_nullable(warmup.sort_space_type);

		times = palloc_array(double, iterations);
		for (int i = 0; i < iterations; i++)
		{
			ExplainResult measured;

			CHECK_FOR_INTERRUPTS();
			measured = run_explain(query);
			times[i] = measured.milliseconds;
			free_explain_strings(&measured);
		}
		timing = summarize_timings(times, iterations);
		pfree(times);
		free_explain_strings(&warmup);
	}
	PG_CATCH();
	{
		AtEOXact_GUC(false, save_nestlevel);
		SPI_finish();
		PG_RE_THROW();
	}
	PG_END_TRY();

	AtEOXact_GUC(false, save_nestlevel);
	if (SPI_finish() != SPI_OK_FINISH)
		elog(ERROR, "SPI_finish failed");

	values[0] = CStringGetTextDatum(nodes);
	values[1] = Int32GetDatum(warmup.launched_workers);
	if (warmup.startup_cost < 0.0)
		nulls[2] = true;
	else
		values[2] = Float8GetDatum(warmup.startup_cost);
	if (warmup.total_cost < 0.0)
		nulls[3] = true;
	else
		values[3] = Float8GetDatum(warmup.total_cost);
	if (warmup.estimated_sort_rows < 0.0)
		nulls[4] = true;
	else
		values[4] = Float8GetDatum(warmup.estimated_sort_rows);
	if (warmup.actual_sort_input_rows < 0.0)
		nulls[5] = true;
	else
		values[5] = Float8GetDatum(warmup.actual_sort_input_rows);
	if (warmup.estimated_sort_width < 0)
		nulls[6] = true;
	else
		values[6] = Int32GetDatum(warmup.estimated_sort_width);
	if (sort_method == NULL)
		nulls[7] = true;
	else
		values[7] = CStringGetTextDatum(sort_method);
	if (sort_space_type == NULL)
		nulls[8] = true;
	else
		values[8] = CStringGetTextDatum(sort_space_type);
	if (warmup.sort_space_used_kb < 0.0)
		nulls[9] = true;
	else
		values[9] = Float8GetDatum(warmup.sort_space_used_kb);
	values[10] = Float8GetDatum(timing.minimum);
	values[11] = Float8GetDatum(timing.median);

	tuplestore_putvalues(rsinfo->setResult, rsinfo->setDesc, values, nulls);
	if (nodes != NULL)
		pfree(nodes);
	if (sort_method != NULL)
		pfree(sort_method);
	if (sort_space_type != NULL)
		pfree(sort_space_type);

	return (Datum) 0;
}
