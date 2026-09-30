# sortbench 05：槽位耗尽时建 heap 的 A/B

本补丁接在 `0004-sortbench-boundary-diagnostics.patch` 后面。
新增 `debug_sort_heap_on_slots`，默认 OFF；不修改 planner 成本公式。
这是执行策略实验，是否更快需要测试，不能把避免落盘直接等同于收益。

## 应用与运行

在已经应用 01—04 的独立排序分支源码根目录执行：

```sh
git apply --check /path/to/0005-sortbench-heap-on-slots-ab.patch
git apply /path/to/0005-sortbench-heap-on-slots-ab.patch
make -j8
make install
make -C contrib/sortbench install
```

重启测试实例，确认新二进制和新参数已经生效：

```sql
SHOW debug_sort_heap_on_slots;
```

在专用测试库、可写目录执行唯一入口：

```sh
psql -X -d sort_test -f contrib/sortbench/benchmark.sql > sortbench-report.txt 2>&1
```

不用传 `-v`。脚本重建 sortbench 扩展和 public.sortbench_data；不要用于业务库。
同名结果会覆盖，先保留上一轮文件。交付结果仍为 sortbench-report.txt 和
sortbench-plans.log，前者包含 trace，后者包含带标签的 JSON。

## 新开关及基线

开启新开关时，允许在数组槽位用完、且累计数量严格大于 bound 时建立 bounded heap。
原有的超过 2*bound 和内存不足触发条件保持有效；没有 bound 时不启用新分支。
`debug_disable_sort_bounded=on` 始终优先，新开关不能绕过它。

默认 05 矩阵固定 `debug_sort_free_heap_root=on`。
**标签 off/default、on/default 的 OFF/ON 现在指新 slots 开关，不是 root 释放开关。**

| 策略后缀 | disable_sort_bounded | disable_sort_radix |
|---|---|---|
| default | off | off |
| no-radix | off | on |
| no-heap | on | off |

每个策略都成对运行 slots OFF/ON。新开关 OFF 恢复 04 的算法切换条件。
这不是稳定 API，也不是最终提交形式；其他实验开关仍保留。

## 一个 SQL 入口，三个模式

benchmark.sql 顶部：

```text
\set sortbench_slots on
\set sortbench_full off
```

- slots=on：本轮默认的正确性、计时 A/B 和 trace。
- slots=off、full=off：04 的集中边界诊断。
- slots=off、full=on：03 的完整 root 释放 A/B。

旧两个模式的主体保持原样，新开关在进入旧模式前固定 OFF。
所有被测查询都是字面 SQL，可以复制对应 SET 和 SELECT/EXPLAIN 单独执行。
初始化、断言、捕获解析和统计实现位于 sortbench--1.0.sql。

## 05 默认覆盖

保留 04 的 21 个预算/宽度条件，均为 N=1000000、LIMIT 250000：

| 输入 | work_mem |
|---|---|
| narrow | 16、24、28、29、30、30.5、31、31.5、32、33、36、64 MB；1 GB |
| wide | 64、96、128、144、192、256、272 MB；1 GB |

所有条件都有 default 的 OFF/ON。
04 观察到的九个候选条件另加 no-radix OFF/ON：narrow 的 16—30.5MB，
wide 的 144/192/256MB，检查 radix 是否影响策略收益。
narrow/16MB、narrow/32MB、wide/144MB 另加 no-heap OFF/ON 作为负对照。

总共 66 个 case/variant，每个预热一次、计时四次，最后独立 trace 一次。
每批保持同策略的 OFF/ON 相邻，交替先后并轮换策略对的位置。
这能缓解顺序影响，不能消除温度、缓存和系统负载漂移。

正确性继续执行原有 12 条小数据结果断言，并新增 24 条断言：

- Datum / tuple，ascending、descending、permuted，各 slots OFF/ON。
- tuple 的 K=2046/2047/2048，在 128kB、当前 64 位构建的槽位边界附近探测。
  不把这些边界值假设为所有平台都一样，不强制每组都走 heap。
- LIMIT 1000 OFFSET 200，验证有效 bound 包含 OFFSET。
- 重复键和 NULL，分别 NULLS FIRST / LAST；payload 为唯一的第二排序键。

新增断言使用 8193 行固定数据、work_mem=128kB。参考数组先完整聚合再切片，
参考排序没有 LIMIT bound；断言函数不生成或执行被测查询。
以上 24 个小条件还各捕获一份 EXPLAIN，观察实际算法和内存。

捕获总数 **420**：24 小数据计划 + 66 预热 + 264 计时 + 66 trace。
只有 264 个 timed 样本参与时间汇总。计时 trace_sort=off；trace 打开后只诊断。
主矩阵仍未逐一比较百万行查询的全部返回值，结果断言覆盖上述小数据条件。

## 报告与判断

`sortbench_slots_check()` 对齐全部样本与 manifest，检查数量/批次/标签、计划形状、
输入输出行数、所有控制开关及同条件的 planner 字段稳定性。
小数据 OFFSET 用例同时检查 Limit 输出和 Sort 输出行数。
禁 heap 的对照必须不使用 heap，且 OFF/ON 的实际方法一致。
至少一个 default 计时条件须出现 disk -> heap，避免新分支根本未被覆盖却通过。
在 04 的固定数据/平台下预计九个默认条件改变，但检查器不硬编码九这个数字。

`sortbench_slots_ratios()` 返回 33 组、各四个批次的配对比值：
slots ON 的 Execution Time / slots OFF 的 Execution Time。
小于 1 表示 ON 较快。它是整条查询耗时，不是纯排序 CPU 时间；
0.95/1.05 批次计数仅描述差异，不是统计显著性判据。

关注三件事：候选条件是否避免落盘、建 heap 后是否符合预算、关闭 trace 后是否更快。
wide/96MB、128MB 这类尚未积累够 K 的条件预计仍然外排序，留作边界负例。
原本已走 heap 的条件及禁 heap 对照用于判断副作用和噪声。
变长数据进入 bounded 状态后可能因后续元组变大而超过 work_mem；这是原有行为，
本轮不把 work_mem 变成硬上限，也不据固定宽度结果宣称覆盖所有数据分布。

## trace 说明

每个 trace 前有 SLOTS seq=... 标记，与 JSON 的 seq 对应。
原有 grow 日志和成本日志继续保留；成本日志仍可能包含多个候选路径。
新增 heap-input reason=slots，及 slots_trigger、slots_heap_enabled 字段。
slots_trigger 表示新条件的谓词值；仍需结合 heap_enabled 看禁 heap 开关是否允许。

04 的 tuple_mem 字段改名为 tuple_mem_counter，并补充说明：该内部计数不随单个
free_sort_tuple() 回减，不能当作 heap-ready 的存活内存。
当前内存看 accounted_bytes、array_bytes、tuple_bytes；均为排序器账目，不是 RSS。

## 交付验证及限制

- 修改的 tuplesort.c，以及通过原有生成器生成的 GUC 表，使用保存的 PG20 开发
  头文件通过 -O2 -Wall -Werror 编译。
- PGlite PG18 加载扩展定义、初始化并执行 24 条新增字面结果断言，规划所有新查询。
- 静态核对 420 份 capture 的 manifest、查询、开关、批次和 OFF/ON 相邻轮换顺序。
- 使用 04 真实计划的副本和明确构造的新分支结果验证解析、66 组计时汇总、
  33 组配对，以及漏样本/错误开关/错误计划/禁 heap 失效等异常拒绝。
  合成记录只验证报告逻辑，不代表原生 PG20 已运行新分支。
- 增量补丁应用、反向和文件内容一致性检查；历史模式主体一致性检查。
- 原生 PG20 新切换条件的正确性、实际内存和性能仍需你运行 benchmark.sql 验证。
