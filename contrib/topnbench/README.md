# topnbench

直接用 psql 执行 `benchmark.sql`。要研究某一条查询，就从文件里复制对应的
SET 和 EXPLAIN 到 psql 手动执行。没有 Python 运行入口，也没有隐藏的查询生成器。

## 安装与运行

0025 接在 0024 后。C 文件和内核没有改动；新增的采集、解析和报告函数在扩展安装 SQL
里，需要更新安装文件。扩展仍是 `topnbench` / `topnbench.c` / 版本 `1.0`。

```sh
make -C contrib/topnbench install PG_CONFIG=/你的PG/bin/pg_config
psql -X -v ON_ERROR_STOP=1 -d postgres -f contrib/topnbench/benchmark.sql > topnbench-report.log 2>&1
```

在专用测试库执行。脚本开头会 DROP/CREATE EXTENSION 并重建 `topnbench_*` 数据表，
然后顺序执行全部用例，每条一次。数据准备代码在插件函数里，只有一行调用留在文件开头。
准备函数返回顶层命令给 `\gexec`，确保 VACUUM 不在函数或事务块里执行。

客户端工作目录会生成两个文件：

- `topnbench-plans.log`：每条查询的用例标识、真实 GUC、原始 EXPLAIN JSON、开始/结束标记。
- `topnbench-report.log`：导入状态、耗时/成本/排序方法汇总、配对比值、计划检查结果以及错误消息。

实际 SELECT 源码保留在 `benchmark.sql`；计划文件记录的是计划与标识，不重复存储 SELECT 文本。
复现实验时请一起保留对应版本的 `benchmark.sql`。文件路径相对于启动 psql 时的目录，
不是数据库服务器的目录，也不是自动相对于脚本所在目录。默认覆盖上一轮文件。

## 单条查询

搜索 `cost-1-work-16`，找到所需 work_mem 和策略。复制实际 SET 和 EXPLAIN 就能运行。
例如：

```sql
SET max_parallel_workers_per_gather = 0;
SET jit = off;
SET work_mem = '16MB';
SET enable_cost_based_delayed_projection = on;
SET enable_sort_tuple_width_cost = on;
SET enable_sort_datum_cost = on;
SET enable_projection_total_cost = on;
SET debug_disable_sort_radix = off;
SET debug_projection_placement = early;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k,
       topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data
ORDER BY a_random
LIMIT 250000;
```

手动查看时可删除 FORMAT JSON 恢复文本计划；需要逐节点计时时也可删除 TIMING OFF。
如果想把结果导入报告，则保留 JSON 格式及查询前的 `topnbench_capture(...)` 调用。
单纯排查不需要复制采集函数，也不用运行文件末尾的统计入口。
SQL 文件中的 GUC 按正常 psql 语义沿用；复制到新连接时请同时设置所需的全局开关。

## 文件结构

只有开头和结尾含运行入口；每条实际查询前有一行标签/参数采集调用：

```sql
-- 开头：扩展和数据准备后
\o topnbench-plans.log
SELECT topnbench_capture_begin(1028);

-- 中间：实际参数和实际查询，逐条展开
SET work_mem = '16MB';
SELECT topnbench_capture('same-query/cost-1-work-16/16MB', 'early', 'same-query', 'timed');
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF, SUMMARY ON, FORMAT JSON)
SELECT a_random AS k, topnbench_work_cost_1(a_random, 16, 1) AS e1
FROM topnbench_data ORDER BY a_random LIMIT 250000;

-- 结尾：完成所有查询后关闭文件，再导入并分析
SELECT topnbench_capture_end();
\o
SELECT topnbench_file_reset();
\copy topnbench_file_lines(line) FROM 'topnbench-plans.log' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
SELECT topnbench_file_load();
SELECT * FROM topnbench_file_report();
SELECT * FROM topnbench_file_ratios();
SELECT * FROM topnbench_file_checks();
```

以上是结构示意，不是完整 1028 条用例；手动收集少量查询时用
`topnbench_capture_begin()`，不指定期望条数。完整文件传入 1028，用于发现漏跑的用例。
运行时需要文件开头的 unaligned、tuples_only、QUIET 设置，保证归档中只有标记和 JSON。
`\o` 关闭并刷新文件后，`\copy` 从客户端读取文件送入数据库。插件不使用 pg_read_file，
因此本地和远程数据库都能采用相同流程，也不要求服务器能访问客户端路径。

PL/pgSQL、统计 CTE、结果表、文件解析全部在插件中。没有恢复辅助测试 SQL 文件。
安装必需的 `topnbench--1.0.sql` 不属于测试用例文件。

## 报告含义与边界

- `timed_samples` 是实际执行次数；默认每条一次，`median_ms` 就是这次的 Execution Time。
  没有自动预热、轮换顺序或重复六批；单次快慢不是稳定回退的证明。
- 标为 plan 的 scope/cost guard 使用不带 ANALYZE 的 EXPLAIN，计时次数为零。
  warmup / diagnostic 记录不参与耗时统计。capture 的第五参数是批次编号，默认 1。
- 同一批同一变体重复执行时先取中位数；跨批再取中位数。
  配对仅使用批次相同且计时样本数相等的两组，>1 表示分子更慢。
- 报告记录实际 GUC，不依赖注释里手填的 work_mem。相同 case/variant 标签下参数变化会拒绝汇总，
  应改用不同标签。不同变体的实际设置仍需检查，不能把任意两种参数组合解释为单因素因果实验。
- 排序 Memory 与 Disk 分开报告；Disk 不是内存消耗。汇总显示各 Sort 节点的空间值集合，
  不是全查询内存总和。worker 的完整信息在原始 JSON 中。
- 计划检查包括指定的投影形状、Datum 成本开关、radix 计划字段和 heap 形状/空间。
  检查失败显示 `FAIL:`；缺少对照变体会显示未检查，不会当成通过。
- **EXPLAIN 不返回查询结果行。这个采集入口不执行 CTAS/EXCEPT ALL 等价校验，
  不验证返回 key 的顺序或 payload 值。** 报告明确区分计划检查和未做的结果校验。
  旧扩展里的比较/校验接口仍保留，但不会隐式重跑这里的查询。
- 标准 EXPLAIN 只有选中的计划，不含所有被丢弃的候选 Path。这个文件报告不会假称记录了全部候选。
  需要候选路径/排序内部 trace 时手动打开相应 GUC；服务端消息保留在 stderr 报告日志，
  不依靠 `\o` 来归档这些消息，也不要把 trace 执行与正常计时混在一起比较。

保留 0024 中 228 个对照组、1028 条实际 SELECT，包括 1GB 的新场景。
变化是执行方式：现在只按可见 SQL 顺序各执行一次，不再有后台驱动器自动调度。

## 不重跑查询，只分析文件

在安装了本版插件的连接中执行：

```sql
SELECT topnbench_file_reset();
\copy topnbench_file_lines(line) FROM 'topnbench-plans.log' WITH (FORMAT csv, DELIMITER E'\x01', QUOTE E'\x02')
SELECT topnbench_file_load();
SELECT * FROM topnbench_file_report();
SELECT * FROM topnbench_file_ratios();
SELECT * FROM topnbench_file_checks();
```

不需要原始测试表，也不执行文件中的内容；导入函数只解析标记和 JSON。
缺失结束标记、记录数不符、重复序号、无效计划或混入无标签输出都会报错。
旧 Python JSONL 和七用例 CSV 是旧格式，不应直接导入这个文本计划入口。

## 验证范围

已用真实 psql 客户端验证输出重定向、关闭刷新、客户端 COPY，并用 PostgreSQL/WASM
执行扩展函数、CSV/JSON 解析、GUC 记录、报告、重新导入和损坏文件拒绝测试。
WASM 的 COPY 传输使用测试适配器接入 PostgreSQL 的 CSV 解析器。
未在这里跑原生 PG20 全套性能矩阵；PG20 专属计划检查仍需在你的当前分支验证。
