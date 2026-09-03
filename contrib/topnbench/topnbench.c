/*
 * topnbench.c
 *
 * A benchmark extension for delayed target-list projection around
 * ORDER BY ... LIMIT.  This is test code, not intended for commit.
 */
#include "postgres.h"

#include <float.h>
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
#include "nodes/parsenodes.h"
#include "tcop/tcopprot.h"
#include "utils/builtins.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/rel.h"
#include "utils/tuplestore.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(topnbench_cost_1);
PG_FUNCTION_INFO_V1(topnbench_cost_2);
PG_FUNCTION_INFO_V1(topnbench_cost_5);
PG_FUNCTION_INFO_V1(topnbench_cost_10);
PG_FUNCTION_INFO_V1(topnbench_run);
PG_FUNCTION_INFO_V1(topnbench_compare);

typedef struct BenchCase
{
	int			selectivity_ppm;
	int			expression_count;
	int			expression_cost;
	int			workers;
} BenchCase;

typedef struct ExplainResult
{
	double		milliseconds;
	int			launched_workers;
	char	   *nodes;
} ExplainResult;

typedef struct StrategyResult
{
	ExplainResult auto_result;
	double		manual_milliseconds;
	double		forced_early_milliseconds;
} StrategyResult;

/*
 * Quick cases are deliberately curated rather than a Cartesian product.
 * They isolate the three inputs to the heuristic and repeat representative
 * points with parallel query enabled.
 */
static const BenchCase quick_cases[] = {
	/* selection-rate sweep: four COST 1 expressions */
	{1, 4, 1, 0},
	{100, 4, 1, 0},
	{10000, 4, 1, 0},
	{100000, 4, 1, 0},
	{250000, 4, 1, 0},
	{500000, 4, 1, 0},

	/* expression-count sweep at 10% */
	{100000, 1, 1, 0},
	{100000, 8, 1, 0},
	{100000, 16, 1, 0},

	/* per-expression cost sweep at 25% */
	{250000, 1, 2, 0},
	{250000, 1, 5, 0},
	{250000, 1, 10, 0},

	/* representative parallel cases */
	{1, 4, 1, 2},
	{10000, 4, 1, 2},
	{250000, 4, 1, 2},
	{500000, 4, 1, 2}
};

static const BenchCase full_extra_cases[] = {
	{50000, 1, 1, 0},
	{250000, 1, 1, 0},
	{500000, 1, 1, 0},
	{750000, 1, 1, 0},
	{50000, 4, 2, 0},
	{100000, 4, 2, 0},
	{250000, 4, 2, 0},
	{500000, 4, 2, 0},
	{750000, 4, 2, 0},
	{50000, 8, 5, 0},
	{100000, 8, 5, 0},
	{250000, 8, 5, 0},
	{500000, 8, 5, 0},
	{750000, 8, 5, 0},
	{100000, 16, 10, 0},
	{250000, 16, 10, 0},
	{500000, 16, 10, 0},
	{100000, 1, 1, 2},
	{100000, 8, 1, 2},
	{250000, 1, 5, 2},
	{250000, 8, 5, 2},
	{500000, 16, 10, 2}
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
topnbench_cost_1(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(run_workload(PG_GETARG_INT32(0), 1));
}

Datum
topnbench_cost_2(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(run_workload(PG_GETARG_INT32(0), 4));
}

Datum
topnbench_cost_5(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(run_workload(PG_GETARG_INT32(0), 16));
}

Datum
topnbench_cost_10(PG_FUNCTION_ARGS)
{
	PG_RETURN_INT32(run_workload(PG_GETARG_INT32(0), 40));
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

static ExplainResult
run_explain(const char *query)
{
	ExplainResult result;
	StringInfoData sql;
	char	   *json;
	int			rc;

	initStringInfo(&sql);
	appendStringInfo(&sql,
					 "EXPLAIN (ANALYZE, VERBOSE, COSTS OFF, TIMING OFF, "
					 "SUMMARY ON, FORMAT JSON) %s", query);

	/* EXPLAIN is a utility statement, even though the wrapped query is SELECT. */
	rc = SPI_execute(sql.data, false, 0);
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
	result.launched_workers = extract_max_workers(json);
	result.nodes = extract_plan_nodes(json);

	SPI_freetuptable(SPI_tuptable);
	pfree(sql.data);
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

	result.auto_result.milliseconds = DBL_MAX;
	result.auto_result.launched_workers = 0;
	result.auto_result.nodes = NULL;
	result.manual_milliseconds = DBL_MAX;
	result.forced_early_milliseconds = DBL_MAX;

	if (verify)
	{
		verify_equivalent(auto_query, manual_query);
		verify_equivalent(auto_query, forced_early_query);
	}

	/* Untimed warmup for all three strategies. */
	{
		ExplainResult warmup;

		warmup = run_explain(auto_query);
		pfree(warmup.nodes);
		warmup = run_explain(manual_query);
		pfree(warmup.nodes);
		warmup = run_explain(forced_early_query);
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
				if (measured.milliseconds < result.auto_result.milliseconds)
				{
					if (result.auto_result.nodes != NULL)
						pfree(result.auto_result.nodes);
					result.auto_result = measured;
				}
				else
					pfree(measured.nodes);
			}
			else if (which == 1)
			{
				measured = run_explain(manual_query);
				if (measured.milliseconds < result.manual_milliseconds)
					result.manual_milliseconds = measured.milliseconds;
				pfree(measured.nodes);
			}
			else
			{
				measured = run_explain(forced_early_query);
				if (measured.milliseconds < result.forced_early_milliseconds)
					result.forced_early_milliseconds = measured.milliseconds;
				pfree(measured.nodes);
			}
		}
	}

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
qualified_function_name(Oid benchmark_function_oid, int cost)
{
	Oid			nspoid = get_func_namespace(benchmark_function_oid);
	char	   *nspname = get_namespace_name(nspoid);
	char		funcname[NAMEDATALEN];

	if (nspname == NULL)
		elog(ERROR, "cache lookup failed for namespace %u", nspoid);

	snprintf(funcname, sizeof(funcname), "topnbench_cost_%d", cost);
	return quote_qualified_identifier(nspname, funcname);
}

static void
build_queries(StringInfo auto_query, StringInfo manual_query,
			  StringInfo forced_early_query,
			  const char *relation_name, const char *column_name,
			  const char *function_name, int expression_count, int64 limit_rows)
{
	resetStringInfo(auto_query);
	resetStringInfo(manual_query);
	resetStringInfo(forced_early_query);

	appendStringInfo(auto_query, "SELECT %s AS k", column_name);
	appendStringInfo(manual_query, "SELECT s.k");
	appendStringInfo(forced_early_query, "SELECT %s AS k", column_name);
	for (int i = 0; i < expression_count; i++)
	{
		appendStringInfo(auto_query, ", %s(%s + %d) AS e%d",
						 function_name, column_name, i, i + 1);
		appendStringInfo(manual_query, ", %s(s.k + %d) AS e%d",
						 function_name, i, i + 1);
		appendStringInfo(forced_early_query, ", %s(%s + %d) AS e%d",
						 function_name, column_name, i, i + 1);
	}
	appendStringInfo(auto_query, " FROM %s ORDER BY %s LIMIT " INT64_FORMAT,
					 relation_name, column_name, limit_rows);
	appendStringInfo(manual_query,
					 " FROM (SELECT %s AS k FROM %s ORDER BY %s LIMIT "
					 INT64_FORMAT ") AS s ORDER BY s.k",
					 column_name, relation_name, column_name, limit_rows);

	/*
	 * Adding the projected expressions as secondary sort keys gives them a
	 * sortgroupref, which forces evaluation below the Sort.  Because every
	 * expression is a deterministic function of the leading key, this does
	 * not change the ordering of rows tied on that key.  It also preserves
	 * the Sort -> Gather Merge shape of a parallel plan.
	 */
	appendStringInfo(forced_early_query, " FROM %s ORDER BY %s",
					 relation_name, column_name);
	for (int i = 0; i < expression_count; i++)
		appendStringInfo(forced_early_query, ", e%d", i + 1);
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
case_limit(int64 nrows, int selectivity_ppm)
{
	int64		limit_rows;
	int64		whole = nrows / 1000000;
	int64		remainder = nrows % 1000000;

	/* Exact ceiling division without overflowing nrows * selectivity_ppm. */
	limit_rows = whole * selectivity_ppm +
		(remainder * selectivity_ppm + 999999) / 1000000;

	return Max(INT64CONST(1), Min(nrows, limit_rows));
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
	Datum		values[14];
	bool		nulls[14] = {false};
	int64		limit_rows = case_limit(nrows, benchcase->selectivity_ppm);
	const char *winner;

	set_local_int("max_parallel_workers_per_gather", benchcase->workers);
	function_name = qualified_function_name(fcinfo->flinfo->fn_oid,
											 benchcase->expression_cost);

	initStringInfo(&auto_query);
	initStringInfo(&manual_query);
	initStringInfo(&forced_early_query);
	build_queries(&auto_query, &manual_query, &forced_early_query,
				  relation_name, column_name,
				  function_name, benchcase->expression_count, limit_rows);

	result = run_three(auto_query.data, manual_query.data,
				   forced_early_query.data, iterations, verify);
	if (result.auto_result.milliseconds <= result.manual_milliseconds &&
		result.auto_result.milliseconds <= result.forced_early_milliseconds)
		winner = "auto";
	else if (result.manual_milliseconds <= result.forced_early_milliseconds)
		winner = "manual-late";
	else
		winner = "forced-early";

	values[0] = Int64GetDatum(nrows);
	values[1] = Int64GetDatum(limit_rows);
	values[2] = Float8GetDatum((double) limit_rows / (double) nrows);
	values[3] = Int32GetDatum(benchcase->expression_count);
	values[4] = Int32GetDatum(benchcase->expression_cost);
	values[5] = Int32GetDatum(benchcase->workers);
	values[6] = Int32GetDatum(result.auto_result.launched_workers);
	values[7] = CStringGetTextDatum(result.auto_result.nodes);
	values[8] = Float8GetDatum(result.auto_result.milliseconds);
	values[9] = Float8GetDatum(result.manual_milliseconds);
	values[10] = Float8GetDatum(result.forced_early_milliseconds);
	values[11] = Float8GetDatum(result.auto_result.milliseconds /
								result.manual_milliseconds);
	values[12] = Float8GetDatum(result.forced_early_milliseconds /
								result.manual_milliseconds);
	values[13] = CStringGetTextDatum(winner);

	tuplestore_putvalues(rsinfo->setResult, rsinfo->setDesc, values, nulls);

	pfree(auto_query.data);
	pfree(manual_query.data);
	pfree(forced_early_query.data);
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
	if (strcmp(profile, "quick") != 0 && strcmp(profile, "full") != 0)
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_PARAMETER_VALUE),
				 errmsg("profile must be \"quick\" or \"full\"")));

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

		if (strcmp(profile, "full") == 0)
		{
			for (int i = 0; i < lengthof(full_extra_cases); i++)
				emit_run_case(fcinfo, &full_extra_cases[i], nrows,
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
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;
	StrategyResult result;
	Datum		values[8];
	bool		nulls[8] = {false};
	const char *winner;
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
		set_local("jit", "off");
		result = run_three(auto_query, manual_query, forced_early_query,
					   iterations, verify);
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

	if (result.auto_result.milliseconds <= result.manual_milliseconds &&
		result.auto_result.milliseconds <= result.forced_early_milliseconds)
		winner = "auto";
	else if (result.manual_milliseconds <= result.forced_early_milliseconds)
		winner = "manual-late";
	else
		winner = "forced-early";
	values[0] = CStringGetTextDatum(result.auto_result.nodes);
	values[1] = Int32GetDatum(result.auto_result.launched_workers);
	values[2] = Float8GetDatum(result.auto_result.milliseconds);
	values[3] = Float8GetDatum(result.manual_milliseconds);
	values[4] = Float8GetDatum(result.forced_early_milliseconds);
	values[5] = Float8GetDatum(result.auto_result.milliseconds /
								result.manual_milliseconds);
	values[6] = Float8GetDatum(result.forced_early_milliseconds /
								result.manual_milliseconds);
	values[7] = CStringGetTextDatum(winner);
	tuplestore_putvalues(rsinfo->setResult, rsinfo->setDesc, values, nulls);

	return (Datum) 0;
}
