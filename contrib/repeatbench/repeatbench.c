/*
 * repeatbench.c -- compare candidate repeat() copy strategies.
 * SELECT * FROM repeat_bench();  Not for commit.
 */
#include "postgres.h"

#include "fmgr.h"
#include "funcapi.h"
#include "miscadmin.h"
#include "portability/instr_time.h"
#include "utils/builtins.h"
#include "utils/fmgrprotos.h"
#include "utils/memutils.h"
#include "utils/tuplestore.h"
#include "varatt.h"

PG_MODULE_MAGIC;

#define ITERS 25

static void
memsets(char *dst, const char *src, int slen, int count)
{
	memset(dst, src[0], count);
	CHECK_FOR_INTERRUPTS();
	return;
}

/* master */
static void
strat_linear(char *dst, const char *src, int slen, int count)
{
	char	   *cp = dst;

	for (int i = 0; i < count; i++)
	{
		memcpy(cp, src, slen);
		cp += slen;
		CHECK_FOR_INTERRUPTS();
	}
}

/* current patch candidate: doubling plus a single-byte memset fast path */
static void
strat_double(char *dst, const char *src, int slen, int count)
{
	char	   *cp = dst;

	if (slen == 1) {
		memsets(cp, src, slen, count);
		return;
	}

	memcpy(cp, src, slen);
	cp += slen;
	CHECK_FOR_INTERRUPTS();

	for (int curcount = 1; curcount < count;)
	{
		int			chunk = Min(curcount, count - curcount);

		memcpy(cp, dst, (size_t) chunk * slen);
		cp += (size_t) chunk * slen;
		curcount += chunk;
		CHECK_FOR_INTERRUPTS();
	}
}

/*
 * Double until the block reaches blocksz bytes, then repeat that block.
 * blocksz is a target block size, not a hard upper bound: doubling may
 * cross it before the block is fixed.
 * chunk <= curcount, so every memcpy has disjoint source and destination.
 * The block limit is computed once rather than multiplied per iteration.
 * A one-copy block holds the same bytes as src, and reading it there keeps
 * large sources identical to master.
 */
static void
capped(char *dst, const char *src, int slen, int count, int blocksz)
{
	char	   *cp = dst;
	const char *from;
	int			curcount = 1;
	int			blockcount;
	int			blocklimit = (blocksz - 1) / slen + 1;	/* ceil, no overflow */

	memcpy(cp, src, slen);
	cp += slen;
	CHECK_FOR_INTERRUPTS();

	while (curcount < count && curcount < blocklimit)
	{
		int			chunk = Min(curcount, count - curcount);

		memcpy(cp, dst, (size_t) chunk * slen);
		cp += (size_t) chunk * slen;
		curcount += chunk;
		CHECK_FOR_INTERRUPTS();
	}

	blockcount = curcount;
	from = (blockcount == 1) ? src : dst;

	while (curcount < count)
	{
		int			chunk = Min(blockcount, count - curcount);

		memcpy(cp, from, (size_t) chunk * slen);
		cp += (size_t) chunk * slen;
		curcount += chunk;
		CHECK_FOR_INTERRUPTS();
	}
}

#define capped_strategy(name, blocksz) \
static void \
name(char *dst, const char *src, int slen, int count) \
{ \
	capped(dst, src, slen, count, blocksz); \
}

capped_strategy(strat_cap512, 1 << 9)
capped_strategy(strat_cap1k, 1 << 10)
capped_strategy(strat_cap2k, 1 << 11)
capped_strategy(strat_cap4k, 1 << 12)
capped_strategy(strat_cap8k, 1 << 13)
capped_strategy(strat_cap16k, 1 << 14)
capped_strategy(strat_cap32k, 1 << 15)
capped_strategy(strat_cap64k, 1 << 16)
capped_strategy(strat_cap128k, 1 << 17)
capped_strategy(strat_cap256k, 1 << 18)
capped_strategy(strat_cap512k, 1 << 19)
capped_strategy(strat_cap1m, 1 << 20)
capped_strategy(strat_cap2m, 1 << 21)
capped_strategy(strat_cap4m, 1 << 22)
capped_strategy(strat_cap8m, 1 << 23)
capped_strategy(strat_cap16m, 1 << 24)

/* cap large enough that it never engages (repeat() tops out at 1GB) --
 * isolates the cost of the structure from the cost of capping */
static void
strat_nocap(char *dst, const char *src, int slen, int count)
{
	capped(dst, src, slen, count, PG_INT32_MAX);
}

static void (*const strategies[]) (char *dst, const char *src,
								int slen, int count) = {
	strat_linear, strat_double, strat_nocap,
	strat_cap512, strat_cap1k, strat_cap2k, strat_cap4k, strat_cap8k,
	strat_cap16k, strat_cap32k, strat_cap64k, strat_cap128k, strat_cap256k,
	strat_cap512k, strat_cap1m, strat_cap2m, strat_cap4m, strat_cap8m, strat_cap16m
};

static const char *const names[] = {"master", "doubling", "nocap",
	"cap512", "cap1k", "cap2k", "cap4k", "cap8k",
	"cap16k", "cap32k", "cap64k", "cap128k", "cap256k",
	"cap512k", "cap1m", "cap2m", "cap4m", "cap8m", "cap16m"
};



/* every strategy must match the built-in repeat() before any timing is
 * reported, otherwise a broken strategy just looks fast */
static void
verify(void)
{
	static const int slens[] = {0, 1, 2, 3, 7, 8, 16, 100, 1000};
	static const int counts[] = {PG_INT32_MIN, -1, 0, 1, 2, 3, 7, 8, 9,
	15, 16, 17, 64, 65, 1000};

	for (int a = 0; a < lengthof(slens); a++)
	{
		int			slen = slens[a];
		text	   *src = (text *) palloc(VARHDRSZ + slen);

		SET_VARSIZE(src, VARHDRSZ + slen);
		for (int k = 0; k < slen; k++)
			VARDATA(src)[k] = (char) ('a' + (k % 26));

		for (int b = 0; b < lengthof(counts); b++)
		{
			int			eff = Max(counts[b], 0);
			int			tlen = VARHDRSZ + slen * eff;
			text	   *want;

			want = DatumGetTextPP(DirectFunctionCall2(repeat,
													PointerGetDatum(src),
													Int32GetDatum(counts[b])));

			for (int s = 0; s < lengthof(strategies); s++)
			{
				text	   *got = (text *) palloc(tlen);

				SET_VARSIZE(got, tlen);
				if (slen > 0 && eff > 0)
					strategies[s] (VARDATA(got), VARDATA(src), slen, eff);

				if (VARSIZE(want) != VARSIZE(got) ||
					memcmp(VARDATA_ANY(want), VARDATA(got), tlen - VARHDRSZ) != 0)
					elog(ERROR, "strategy \"%s\" differs from repeat() at "
						"slen=%d count=%d", names[s], slen, counts[b]);
				pfree(got);
			}
			pfree(want);
		}
		pfree(src);
	}
}

/* "1 B", "64 KB", "256 MB" */
static char *
human(int64 bytes)
{
	if (bytes >= 1024 * 1024)
		return psprintf("%.4g MB", (double) bytes / (1024 * 1024));
	if (bytes >= 1024)
		return psprintf("%.4g KB", (double) bytes / 1024);
	return psprintf(INT64_FORMAT " B", bytes);
}

/* "339.2 ms", "185.0 us", "7 ns" */
static char *
duration(double ms)
{
	if (ms >= 1.0)
		return psprintf("%.1f ms", ms);
	if (ms >= 0.001)
		return psprintf("%.1f us", ms * 1000.0);
	return psprintf("%.0f ns", ms * 1000000.0);
}

static int
compare_double(const void *a, const void *b)
{
	double		da = *(const double *) a;
	double		db = *(const double *) b;

	return (da > db) - (da < db);
}

PG_FUNCTION_INFO_V1(repeat_bench);
Datum
repeat_bench(PG_FUNCTION_ARGS)
{
	static const int cases[][2] = {
		/* small counts, densely either side of the patch's threshold of 8 */
		{32, 2}, {32, 4}, {32, 6}, {32, 7}, {32, 8}, {32, 9}, {32, 12},
		{32, 16}, {32, 64}, {32, 4096},
		/* 16 MB of output: usually still cache-resident */
		{1, 16777216}, {10, 1677721}, {100, 167772},
		{1024, 16384}, {65536, 256}, {1048576, 16},
		/* 256 MB of output: far beyond any cache */
		{1, 268435456}, {10, 26843545}, {100, 2684354},
		{1024, 262144}, {65536, 4096}, {1048576, 256},
		/* single-byte sources */
		{1, 1000}, {1, 1000000}
	};
	ReturnSetInfo *rsinfo = (ReturnSetInfo *) fcinfo->resultinfo;

	InitMaterializedSRF(fcinfo, 0);
	verify();

	for (int i = 0; i < lengthof(cases); i++)
	{
		int			slen = cases[i][0];
		int			count = cases[i][1];
		int			tlen = VARHDRSZ + slen * count;
		int			inner = Max(1048576 / tlen, 1);
		int			nstrat = lengthof(strategies);
		int			best = 0;
		int			median_best = 0;
		double		ms[lengthof(strategies)];
		double		median_ms[lengthof(strategies)];
		double		samples[lengthof(strategies)][ITERS];
		Datum		values[4 + lengthof(strategies)];
		bool		nulls[4 + lengthof(strategies)] = {0};
		MemoryContext cxt,
					old;
		char	   *buf;
		char	   *src = palloc(slen);

		memset(src, 'x', slen);
		cxt = AllocSetContextCreate(CurrentMemoryContext, "repeat_bench",
									ALLOCSET_DEFAULT_SIZES);
		old = MemoryContextSwitchTo(cxt);
		buf = palloc(tlen);
		memset(buf, 0, tlen);	/* fault the pages in up front */

		for (int s = 0; s < nstrat; s++)
			ms[s] = -1.0;

		/* Rotate the order so no strategy always runs in the same position. */
		for (int r = 0; r < ITERS; r++)
		{
			for (int k = 0; k < nstrat; k++)
			{
				int			s = (k + r) % nstrat;
				instr_time	t0,
							dur;
				double		el;

				INSTR_TIME_SET_CURRENT(t0);
				for (int j = 0; j < inner; j++)
					strategies[s] (buf + VARHDRSZ, src, slen, count);
				INSTR_TIME_SET_CURRENT(dur);
				INSTR_TIME_SUBTRACT(dur, t0);

				el = INSTR_TIME_GET_MILLISEC(dur) / inner;
				samples[s][r] = el;
				if (ms[s] < 0.0 || el < ms[s])
					ms[s] = el;
			}
		}
		MemoryContextSwitchTo(old);
		MemoryContextDelete(cxt);

		for (int s = 0; s < nstrat; s++)
		{
			double		sorted[ITERS];

			memcpy(sorted, samples[s], sizeof(sorted));
			qsort(sorted, ITERS, sizeof(double), compare_double);
			median_ms[s] = (sorted[(ITERS - 1) / 2] + sorted[ITERS / 2]) / 2.0;
		}

		for (int s = 1; s < nstrat; s++)
		{
			if (ms[s] < ms[best])
				best = s;
			if (median_ms[s] < median_ms[median_best])
				median_best = s;
		}

		values[0] = CStringGetTextDatum(human(slen));
		values[1] = Int32GetDatum(count);
		values[2] = CStringGetTextDatum(human((int64) slen * count));
		values[3] = CStringGetTextDatum(duration(ms[0]));
		for (int s = 1; s < lengthof(strategies); s++)
		{
			values[3 + s] = CStringGetTextDatum(psprintf("%.2fx", ms[0] / ms[s]));
		}
		if (best == median_best)
			values[3 + lengthof(strategies)] = CStringGetTextDatum(names[best]);
		else
			values[3 + lengthof(strategies)] = CStringGetTextDatum(
				psprintf("%s (median: %s)", names[best], names[median_best]));

		tuplestore_putvalues(rsinfo->setResult, rsinfo->setDesc, values, nulls);
	}

	return (Datum) 0;
}
