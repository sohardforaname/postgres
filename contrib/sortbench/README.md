# 独立排序实验：sortbench

这是独立分支的诊断补丁，不是 TopN 0026。TopN 分支停在 0025；本实验不修改
planner、投影位置或任何成本公式，先测排序执行策略本身。

## 基线与安装

补丁以之前保存的 PG20 开发源码为基底，已移除旧实验对三个目标文件的改动。
没有重新拉取今天的 master，也没有恢复到原始仓库的完整 commit ID。
恢复后的 `src/backend/utils/sort/tuplesort.c` Git blob 为：

```
f67651483f8768fdc7c3c62bdd0d7efdf8ba3f58
```

请从你开始延迟投影实验时的干净主线 commit 建独立分支/工作树，再应用本补丁。
不要叠在 0025 或 0026 上；已有的 radix 开关会冲突，旧成本修改也会污染基线。
如果选择更新的主线，先做 `git apply --check`，并保存实际使用的 commit ID。
本补丁不改 `make_bounded_heap()` 内部的元组释放逻辑。

```sh
# 在独立、干净的 PG 源码树根目录，替换补丁实际路径。
git apply --check /path/to/sortbench-disable-bounded-heap.patch
git apply /path/to/sortbench-disable-bounded-heap.patch

# 沿用该源码树的 configure 参数和安装前缀。
make -j8
make install
make -C contrib/sortbench install
```

停止旧测试服务，使用新安装的服务器启动测试实例。两个新 GUC 在内核里，仅重装
扩展不会生效。可以先检查：

```sql
SHOW debug_disable_sort_bounded;
SHOW debug_disable_sort_radix;
```

两个值默认均为 `off`。扩展为纯 SQL，不需要额外的 `.so`。
如果使用另附的完整扩展包，它与补丁内的 `contrib/sortbench` 完全相同，二选一即可；
完整扩展包不能替代内核补丁。也可以针对新服务器的 `pg_config` 用 PGXS 安装：

```sh
make -C contrib/sortbench USE_PGXS=1 PG_CONFIG=/path/to/bin/pg_config install
```

## 运行

在专用测试库、可写目录中运行。初始化会重建 `public.sortbench_data`，约 100 万行；
核心数据约 300 MB，另外需要为临时排序文件预留空间。每次运行覆盖同名输出文件。

```sh
/path/to/bin/psql -X -d sort_test -v ON_ERROR_STOP=1 \
  -f /path/to/contrib/sortbench/benchmark.sql > sortbench-report.txt 2>&1
```

只需执行 `benchmark.sql`。它通过 `sortbench_prepare()` 初始化，通过 `\o` 保存
EXPLAIN JSON，再通过客户端 `\copy` 导入并调用扩展中的统计函数。
数据库服务器不需要读取客户端路径。

生成两个文件：

- `sortbench-report.txt`：检查结果、汇总、配对比值、估算成本、最后的独立 trace。
- `sortbench-plans.log`：128 份带标签的原始 JSON 计划，用于复查与重新分析。

测试入口仅此一个 SQL 文件。`sortbench--1.0.sql` 是 PostgreSQL 要求的扩展安装脚本，
不是另一套测试入口。没有隐藏查询生成器或另一个 full 文件；每条测量查询都写在
`benchmark.sql` 里。复制查询及前面的 SET 就能单独执行，capture 调用可以不复制。
单独执行时同样设置 `max_parallel_workers_per_gather=0`、`jit=off`、`trace_sort=off`。

## 测什么

同一张表包含唯一的、打乱顺序的整数键，以及 8 字节/256 字节两个文本载荷。
载荷强制 `STORAGE PLAIN`，避免 TOAST 压缩与外置成为额外变量。两类查询均输出两列，
均为 SortTuple 路径；不把单列 Datum 排序与 tuple 宽度混在一起。

```sql
SELECT k, small_payload FROM public.sortbench_data ORDER BY k LIMIT 250000;
SELECT k, large_payload FROM public.sortbench_data ORDER BY k LIMIT 250000;
```

顺序、键、输入行数、LIMIT、基表扫描页数保持相同。载荷宽度仍可能影响读取/拷贝开销；
记录的是整个查询耗时，不冒充纯排序 CPU 时间。所有计时运行使用串行、JIT off、trace off。

| 组 | work_mem | 对比 | 目的 |
|---|---|---|---|
| heap，窄/宽 | 4、8、16、24、32 MB，1 GB | default / no-heap | 同一预算下允许或禁止进入 bounded heap |
| radix，窄/宽 | 4 MB，1 GB | no-heap / no-heap-no-radix | 固定禁止 heap，单独切换 radix dispatch |

共 16 个配对条件，每个条件两种策略，各 1 次预热、3 次计时：32 次预热、96 次计时。
配对执行顺序交替；汇总报告中位数和逐批配对比值，不混入预热与 trace。
三批是首轮诊断，不足以凭几个百分点差异作稳定性能结论。

最后另外执行 12 条 trace 查询，覆盖窄/宽、内存边界和大预算，并补充 radix 禁用对照。
它们的执行耗时不进入统计。

## 两个开关的确切含义

`debug_disable_sort_bounded=on` 只阻止 `TSS_INITIAL` 转入 bounded heap。
仍传递 LIMIT bound，仍保留相同的键准备、内存上下文选择；正常数组扩容与外部排序
继续工作。它不会强制所有数据挤进内存，也不保证采用 quicksort：输入多、预算小时
仍会落盘。已有的编译期 `DEBUG_BOUNDED_SORT` / `optimize_bounded_sort` 会在接收 bound
时提前返回，与这里仅禁止执行策略转换的实验不同。

`debug_disable_sort_radix=on` 阻止符合条件的内存排序/外部排序初始 run 进入 radix，
改走已有的 quicksort 分支。不强制外部归并，也不改变成本估算。

策略标签：

| 标签 | 禁止 bounded heap | 禁止 radix |
|---|---|---|
| default | off | off |
| no-heap | on | off |
| no-heap-no-radix | on | on |

`work_mem` 仍按原有规则执行，不是进程内存的硬上限；本补丁没有提供绕过预算的“强制内存排序”。
实验首先问：同一预算和同一查询下，默认策略是否比另一条可执行策略更慢？
不会把“external merge”视为必然比“top-N heapsort”慢。

## 报告怎么看

1. 先看 `sortbench_file_checks()`。检查两个策略的计划估算完全一致、串行
   `Limit -> Sort -> Seq Scan`、两列、100 万输入/25 万输出、开关与计时设置正确。
   出现 FAIL 时先解决实验条件，不使用那组结果推断成本问题。
2. `sortbench_file_report()` 给出整条查询的执行时间中位数、根节点估算成本和
   实际 Sort Method / Memory 或 Disk。多个实际值用 `/` 并列，保留原始差异。
3. `sortbench_file_ratios()` 中 `no-heap / default < 1` 表示禁止 heap 更快；
   `no-heap-no-radix / no-heap < 1` 表示禁止 radix 更快。
   `faster_batches` / `slower_batches` 使用 0.95 / 1.05 描述逐批差异，不是统计显著性检验。
4. `sortbench_file_costs()` 中：
   - `sort_startup_added = Sort.Startup Cost - 子节点.Total Cost`。
   - `sort_run_cost = Sort.Total Cost - Sort.Startup Cost`。
   - 临时读写量的单位是数据库 block；JSON 中也保存 Buffers 明细。
   这些成本使用 EXPLAIN 展示的舍入值，不能与毫秒直接相减或直接作比值。
5. 最后看 trace：`heap-input` / `heap-ready` 是转 heap 前后，`external-input`
   是首次落盘前，`full-input` 是装下全部输入后、开始内存排序前。
   `capacity` 是数组槽位数，`array_bytes` 是数组分配账目，`tuple_bytes`
   是扣掉数组后的元组分配账目（包含相应分配开销，不等于列宽乘行数）。
   `accounted_bytes` 是 `allowedMem - availMem`，不是 RSS 或内存上下文峰值。
   `slots_full` / `memory_full` 帮助区分数组容量与内存账目触发的落盘。

EXPLAIN 显示 `quicksort` 不足以确定 radix 是否运行。`radix-entry` 仅表示进入了 radix
例程；例程内部仍可能提前退出或使用 quicksort。`qsort-single` / `qsort-tuple` 表示
直接进入相应 quicksort 分支。外部排序可能为多个初始 run 打印多条 dispatch 日志。

EXPLAIN 不返回结果值，因此报告没有宣称验证结果集正确性。两个策略执行同一条查询，
本补丁只禁用已有策略，不修改比较器、元组内容或排序实现本身。

## 本地验证范围

- 修改后的 tuplesort C 单元以 PG20 头文件完成编译（`-O2 -Wall -Werror`）。
- GUC 数据通过原有生成器，并编译包含新表及新声明的 guc_tables C 单元。
- 补丁应用/反向检查，完整包与补丁内扩展文件一致性检查。
- 原生 psql 对 PGlite PostgreSQL 18.3：缩小到 1 万行验证建表、`\gexec`、
  `\o`、JSON 导入、预热排除、配对统计及损坏文件拒绝；所有 140 条字面查询的
  两种查询体均解析并生成计划。
- 独立的合成计划测试验证检查器能接受正确形状、拒绝禁止 heap 却使用 heap、
  拒绝仅切换执行策略却改变计划估算的情况。

当前运行环境不能启动原生 PG20 服务。尚未执行新增内核开关的运行时测试、完整
PG 回归测试或本机性能测量；PGlite 验证不代表 PG20 排序实现得到运行验证。
