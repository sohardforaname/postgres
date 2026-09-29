# sortbench：一个入口，heap 释放修复 A/B 测试

只运行 `benchmark.sql`。所有查询、正确性检查、计时和 trace 都在这个文件中。
本补丁接在已应用 `sortbench-round2-on-round1.patch` 的独立排序分支上。
不修改成本公式，也不引入延迟投影路径。

## 应用与运行

在当前独立排序源码树根目录：

```sh
git apply --check /path/to/sortbench-heap-root-ab.patch
git apply /path/to/sortbench-heap-root-ab.patch
make -j8
make install
make -C contrib/sortbench install
```

重启测试实例，使用新安装的 PostgreSQL。确认新开关已注册：

```sql
SHOW debug_sort_free_heap_root;
```

然后在专用测试库、可写目录中运行：

```sh
psql -X -d sort_test -f contrib/sortbench/benchmark.sql > sortbench-report.txt 2>&1
```

脚本包含 ON_ERROR_STOP，不用额外传 `-v`。会重建 sortbench 扩展和
`public.sortbench_data`，并创建会话临时表；请使用专用测试库。
每次运行覆盖 `sortbench-report.txt`、`sortbench-plans.log`，需要保留旧结果时先改名。

只安装扩展不够，必须重新编译、安装并重启内核。完整扩展包与补丁中的扩展一致，
不能替代内核补丁。通过补丁应用会删除旧 `benchmark-round2.sql`、旧分轮说明以及
多余的扩展版本脚本；解压完整包替换目录时请替换整个旧目录，不要叠加解压。

扩展现在只保留五个文件：Makefile、README.md、benchmark.sql、sortbench.control、
sortbench--1.0.sql。最后一个是 PG 必需的安装脚本，不是测试入口。
不再维护版本升级链；benchmark.sql 明确重建扩展并加载这一份安装脚本。
历史结果文件不需要删除，但不要再运行历史测试 SQL。

## 开关

| 参数 | OFF | ON |
|---|---|---|
| debug_sort_free_heap_root | 保留当前基线的堆顶分配 | 构建 bounded heap 时，替换前释放旧堆顶 tuple |
| debug_disable_sort_bounded | 允许 bounded heap | 禁止进入 bounded heap，仍可正常落盘 |
| debug_disable_sort_radix | 允许 radix dispatch | 使用既有 quicksort 分支 |

三个开关默认均为 OFF。新开关仅包住 `make_bounded_heap()` 中的释放操作，
不修改比较器、成本模型、算法选择条件或常规 `TSS_BOUNDED` 输入阶段。
它保留原始基线用于临时 A/B，不是最终提交形态。

例子：复制下面这段就可以单独检查修复开启时的默认排序策略。

```sql
SET max_parallel_workers_per_gather = 0;
SET jit = off;
SET trace_sort = off;
SET work_mem = '1GB';
SET debug_disable_sort_bounded = off;
SET debug_disable_sort_radix = off;
SET debug_sort_free_heap_root = on;
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, TIMING OFF)
SELECT k, small_payload FROM public.sortbench_data ORDER BY k LIMIT 250000;
```

将新开关改为 OFF 即为基线。查询及三个开关均直接写在 benchmark.sql，
没有动态生成被测查询的函数，也没有额外的 full/round 测试文件。
初始化和统计实现放在扩展中，capture 函数只给紧接着的 EXPLAIN 添加标签。

## 覆盖范围

保留前两轮用例的并集，重复条件只保留一次：

- narrow/32MB、narrow/1GB、wide/1GB：LIMIT 1000、10000、50000、100000、
  250000、500000、750000，21 个条件。
- 窄/宽元组、LIMIT 250000：work_mem 4、8、16、24、32 MB 和 1 GB。
  与上面重叠的三个条件不重复，再补九个条件，总计 30 个。
- 原来的 radix 外部排序/内存排序对照，包含在上述条件的四种策略中。
- 原来的 16/24/28/32 MB 内存边界与大预算 trace 均保留，和释放 ON/OFF 配对。

四种排序策略为 default、no-radix、no-heap、no-heap-no-radix。
每种再分 off/ 与 on/，例如 `on/default` 表示释放开启、默认排序策略。
每个条件八种组合各预热一次，再测四批：240 次预热、960 次计时。
修复 OFF/ON 相邻执行并交替先后，四种策略按批次轮换执行位置。
在禁用 heap 的两种策略下，新开关不应改变执行行为；这两组保留为负对照。

另外有 12 份小数据内存诊断计划，以及最后 46 次独立 trace。
捕获文件总计 1212 份 JSON 计划：240 预热 + 960 计时 + 12 内存检查。
trace 不进入捕获文件和计时统计。全套比之前 420 份计划的测试更久。

## 正确性与内存验证

小数据使用 N=8193、K=4096。顺序、逆序、打乱三种插入顺序，分别测单列 Datum
和两列 tuple 排序，并分别开关释放修复。8193=2*4096+1，使 heap 在最后一行构建。

benchmark.sql 中直接写出每条查询；扩展的断言函数只检查传入的数组，
验证 4096 个键和载荷及其顺序。内存检查使用另外的字面 EXPLAIN，要求实际走 heap。
开启修复时，同一表示的三种输入顺序必须与顺序输入的内存占用相同；不符合则报错。
关闭修复时允许元组内存增加，报告相对顺序输入多出的 KB，不把基线现象当作测试失败。

主矩阵检查样本完整性、输入/输出行数、计划形状、三个开关及其余捕获参数。
三个开关均是执行器诊断开关，因此同一条件的 planner 估算应保持一致。
主矩阵没有逐一验证百万行查询的全部返回值；结果断言覆盖上述小数据组。

## 报告解读

先看正确性与检查结果，再看 `scope=release` 的 ON/OFF 配对比值：

- 小于 1：开启释放更快；大于 1：开启释放更慢。
- 之后看 `scope=strategy`，比较同一释放模式内的 heap/radix 策略。
- 耗时为完整查询的 Execution Time，不能当成纯排序 CPU 时间。
- 四批中位数及最小/最大配对比值用于观察稳定性；5% 计数不是显著性检验。
- planner 成本不直接等同于毫秒。强制开关不改变估算是本实验的预期。
- `heap-ready` 内存账目用于确认多余分配消失；不是进程 RSS 或峰值。
- EXPLAIN 的 quicksort 标签不能区分 radix；通过末尾 dispatch trace 辅助确认。
- 逐批原始数据全部在 sortbench-plans.log，报告也列出逐批时间。

## 已完成的验证

- 两个修改相关 C 单元以 PG20 头文件及原有 GUC 生成器编译，`-O2 -Wall -Werror`。
- SQL 扩展在 PGlite PostgreSQL 18.3 加载、生成缩小的主数据及完整小数据。
- 12 条字面结果断言执行通过；1258 条 EXPLAIN 的查询体均完成解析/生成计划。
- 静态逐条核对 1212 份 capture 的 GUC、标签、查询、LIMIT 与 30 条 manifest。
- 用原始上传计划及明确构造的 ON 模式合成记录验证全矩阵汇总、配对和异常拒绝。
- 增量补丁应用/反向检查、删除旧入口和完整扩展包一致性检查。

当前环境不能启动原生 PG20。以上不等同于新增释放开关的运行时验证；
内核释放行为及性能仍需在你的 PG20 实例执行本文件确认。
