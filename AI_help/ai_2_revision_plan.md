# AI Rate Revision Plan for `ai_2.pdf`

目标：在不改变论文技术结论、不隐藏 AI 使用、不牺牲学术准确性的前提下，把文本改得更像你自己的研究写作。重点不是同义词替换，而是加入你的实验判断、阅读过程、设计理由和限制说明。

建议顺序：先改 Chapter 3，再改 Chapter 4，最后微调 Abstract 和 AI acknowledgement。

## 1. Chapter 3 开头：减少模板式章节介绍

位置：

- `latex/chapters/03_LAPACK_Implementation/03_00.tex`
- `latex/chapters/03_LAPACK_Implementation/03_01_Overview_of_Routine_Structure.tex`

目前问题：

- 开头有较多通用句式，例如：
  - `This chapter bridges...`
  - `Its purpose is not to...`
  - `This section gives a compact overview...`
  - `The aim is not to document...`
- 这些句子结构很平滑，但个人研究痕迹不够明显。

修改建议：

- 把章节目标改成你自己的分析路径：你是从 `DSYEV` 和 `DSYEVD` 的调用路径中找性能差异。
- 明确说本章只追踪对 Chapter 4 有用的几个节点：`DSYTRD`、`DSTEQR/DSTEDC`、`DORGTR/DORMTR`。
- 删除或压缩 “not to document every internal subroutine” 这种防御性表达。
- 加一句说明：本章的目的不是复述 LAPACK manual，而是为后面的 stage timing 和 profiling 建立解释框架。

可改方向示例：

```tex
In this chapter I trace the two LAPACK driver paths only as far as needed for
the later timing results. The important question is where the two routines stop
sharing work. Both pass through \texttt{DSYTRD}; after that point the
\texttt{DSYEV} path accumulates rotations through \texttt{DSTEQR}, while
\texttt{DSYEVD} moves the tridiagonal solve to \texttt{DSTEDC} and applies the
Householder reflectors later through \texttt{DORMTR}.
```

## 2. Chapter 3 表格和接口说明：加入选择依据

位置：

- `latex/chapters/03_LAPACK_Implementation/03_01_Overview_of_Routine_Structure.tex`

目前问题：

- `Interface-Level View` 部分比较像 routine manual 的摘要。
- 表格里的内容偏通用，缺少“为什么这些参数对本论文重要”的说明。

修改建议：

- 在 `JOBZ` 后面加一句：本论文重点是 `JOBZ='V'`，因为 full eigenpair 才会放大 `DSTEQR` 和 `DSTEDC` 的差别。
- 在 `WORK/LWORK`、`IWORK/LIWORK` 后面加一句：workspace 不是附属细节，而是最后 runtime-memory tradeoff 的一部分。
- 表格后不要只说两个接口类似，要说明“接口相似反而使比较更干净，因为差异主要来自内部算法路径”。

## 3. `DSTEQR` 流程图解释：写出你的性能判断

位置：

- `latex/chapters/03_LAPACK_Implementation/03_02_02_STEQR.tex`

目前问题：

- 图前图后的解释偏概念化。
- `fine-grained sequential work` 这个判断是对的，但还可以更具体。

修改建议：

- 在图后加 1 段解释：为什么 `DSTEQR('V')` 对 full eigenpair 慢。
- 明确写出 `Z=Q` 的含义：旋转不是只作用在小 tridiagonal block 上，还要不断更新 dense eigenvector matrix。
- 连接到 Chapter 4 的证据：后面 `DLASR` 会占很大比例，这不是偶然，而是这个路径结构决定的。

可加入内容：

```tex
For the later measurements, the important detail is the matrix on which the
rotations are accumulated. In the \texttt{DSYEV} path, \texttt{DORGTR} has
already formed the dense matrix \(Q\), so the QR/QL rotations are not confined
to the tridiagonal data. They are repeatedly applied to a dense eigenvector
basis. This is why the profiling in Chapter~4 treats the rotation-application
cost, especially the \texttt{DLASR} path, as a central part of the explanation.
```

## 4. `DSTEDC` 流程图解释：强调你观察到的路径差异

位置：

- `latex/chapters/03_LAPACK_Implementation/03_02_03_STEDC.tex`

目前问题：

- 现在写法比较像标准算法说明。
- 可以更清楚地区分 `DSTEDC` 内部出现 `DSTEQR` 和 `DSYEV` 直接调用 `DSTEQR('V')` 的差别。

修改建议：

- 强调 `DSTEDC` 内部的 `DSTEQR` 只用于小 leaf subproblems，不是 full-size dense eigenvector accumulation。
- 写清楚 `DSTEDC('I') -> DORMTR` 的顺序为什么重要：先在 tridiagonal basis 里完成合并，再统一映射回 dense basis。
- 加一句“这也是为什么 routine name overlap 不能直接说明 cost structure overlap”。

可加入内容：

```tex
This distinction mattered when interpreting the profiles. Seeing
\texttt{DSTEQR} inside the divide-and-conquer routine does not make the
\texttt{DSYEVD} path equivalent to the \texttt{DSYEV} path. In my comparison,
the scale of the call is the important point: \texttt{DSYEV} applies
\texttt{DSTEQR('V')} to the full tridiagonal problem with a dense accumulation
matrix, while \texttt{DSTEDC} only uses QR-style solves after recursive
splitting has made the subproblems small.
```

## 5. Chapter 3 结尾：从“总结”改成“后续实验假设”

位置：

- `latex/chapters/03_LAPACK_Implementation/03_03_Discussion_and_Remarks.tex`

目前问题：

- 结尾段落逻辑清楚，但像自动生成的 chapter summary。

修改建议：

- 把 `This is the bridge to Chapter 4` 改成更具体的实验假设。
- 例如：如果 Chapter 3 的解释正确，那么 Chapter 4 应该看到：
  - `DSYTRD` 时间接近；
  - `DSTEQR` 在 `DSYEV` 中占比很高；
  - `DSTEDC` 和 `DORMTR` 中会出现更多 blocked/BLAS-3 work；
  - `DSYEVD` memory footprint 更高。

这样写会显得后面的实验是由你设计出来验证的，而不是事后总结。

## 6. Chapter 4 benchmark 开头：写清楚为什么先做这个实验

位置：

- `latex/chapters/04_Experiments/04_02_benchmark.tex`

目前问题：

- 开头是标准 “This section presents...” 句式。
- 可以更像实验报告：先说明 control variables，再说明为什么从 end-to-end timing 开始。

修改建议：

- 说明这里固定 OpenBLAS SVE build、`JOBZ='V'`、matrix family、problem sizes。
- 写明这个 benchmark 的作用：先确认差异是否真实存在，再用 later profiling 拆解原因。
- 少用 “we first report...” 这种模板式 roadmap。

可改方向：

```tex
The first experiment fixes the optimized OpenBLAS SVE build and measures the
full \texttt{JOBZ='V'} driver path. I use this as the baseline before adding
heavier instrumentation, because the later profiling only makes sense after the
end-to-end runtime gap has been established under a controlled configuration.
```

## 7. Chapter 4 single-thread analysis：用数字推理替代泛泛结论

位置：

- `latex/chapters/04_Experiments/04_02_benchmark.tex`

目前问题：

- `DSYEVD is consistently faster` 是正确的，但比较普通。
- 建议把分析写成“从表中看出什么”。

修改建议：

- 先比较 `DSYTRD`：`6.574s` vs `6.616s`，说明 shared stage 不是原因。
- 再比较 tri-eig：`55.793s` vs `1.935s`，说明真正差异在第二阶段。
- 再补 back transformation：`DSYEVD` 的 back-transformation 反而更长，但总时间仍然更短，这能增强你的分析深度。

可加入内容：

```tex
The back-transformation column is useful because it prevents an over-simple
reading of the table. At \(n=4096\), \texttt{DSYEVD} spends more time in
back-transformation than \texttt{DSYEV} does, but this extra cost is small
compared with the saving in the tridiagonal eigensolver. The result is therefore
not that every stage of \texttt{DSYEVD} is faster; it is that the stage where
the two algorithms differ most is large enough to dominate the total runtime.
```

## 8. Chapter 4 thread scalability：说明这个实验只是辅助证据

位置：

- `latex/chapters/04_Experiments/04_02_benchmark.tex`

目前问题：

- 当前写法已经说是 secondary confirmation，但可以再具体一点。

修改建议：

- 说明 thread scaling 不是为了做完整 parallel performance study。
- 它只是用来检查 Chapter 3 的结构判断：`DSYEVD` 是否真的暴露更多 useful parallel work。
- 加一句限制：只测 1、2、4 threads，不能推广到所有 core counts。

## 9. Hardware-counter 部分：增加测量限制和解释边界

位置：

- `latex/chapters/04_Experiments/04_05_03_hardware_efficiency.tex`

目前问题：

- 技术分析较完整，但语气仍偏总结式。
- 需要更多“为什么这样看 counter”的个人判断。

修改建议：

- 在开头说明大尺寸只跑一次的原因：counter collection 成本高，主要用于确认方向，不用于统计置信区间。
- 明确说这些 counters 是辅助解释，不是单独证明算法复杂度。
- 对 IPC、miss rate 等 normalized metrics 加解释：为什么它们可能误导。

可加入内容：

```tex
I treat these counters as diagnostic evidence rather than as a replacement for
the timing results. In particular, the large cases were expensive to measure
with hardware counters, so the purpose is to check whether the counter pattern
is consistent with the timing and call-path evidence, not to estimate a full
statistical distribution.
```

## 10. Hardware-counter 结尾：避免过度完美的总结语气

位置：

- `latex/chapters/04_Experiments/04_05_03_hardware_efficiency.tex`

目前问题：

- `Overall, the hardware-counter evidence supports...` 后面比较像自动总结。

修改建议：

- 改成更谨慎的结论。
- 加一句：这些 counters 不能单独说明 `DGEMM` 内部所有 micro-mechanism，但能说明 total instruction/stall cost 的方向。
- 避免 “clean two-step explanation” 这种太规整的表达，可以改成更自然的研究判断。

## 11. Abstract：只做小改，不要大幅重写

位置：

- `latex/main.tex`

目前问题：

- 摘要已经比普通模板好，不建议重写太多。
- 但仍有一些泛泛表达，例如 `central problem`、`well-structured mathematical problem`。

修改建议：

- 保留主要结构。
- 加入一个最关键实验数字，让摘要更像这篇 thesis 的摘要，而不是领域介绍。
- 例如加入：`at n=4096, 66.255 s vs 14.482 s` 或 `55.793 s vs 1.935 s`。
- 删除一两个泛泛背景句，避免摘要太像教科书开头。

## 12. AI acknowledgement：保持透明，但改得更具体

位置：

- `latex/main.tex`

目前问题：

- 当前声明合规，但 prompt 列表较长，且有模板感。

修改建议：

- 不要删除 AI acknowledgement。
- 不要隐瞒 AI 使用。
- 把用途写得更具体、更贴近你的实际工作：
  - language editing;
  - LaTeX formatting help;
  - code cleanup suggestions;
  - explanation checking;
  - structure suggestions.
- 强调最终实验设计、结果解释、数学检查、结论由你负责。
- 可以减少代表性 prompts 的数量，保留 3-4 个即可。

## 13. 全文搜索并替换高频模板句

建议搜索：

```bash
rg -n "This section|This chapter|The key|The important|Overall|By contrast|The results show|In conclusion" latex/chapters latex/main.tex
```

处理方式：

- 不是全部删除。
- 每章保留少量必要的路标句。
- 对重复出现的句子，改成更具体的技术判断。

替换思路：

- `This section presents...`
  - 改成实验设计或分析目的。
- `The key distinction is...`
  - 改成具体差异，例如 routine ordering、workspace、dense accumulation matrix。
- `Overall...`
  - 改成更谨慎的总结，例如 `In this set of measurements...`。

## 14. 加入更多“为什么这样设计实验”的句子

建议插入位置：

- Chapter 4 每个实验小节开头或表格后。

可以补充的问题：

- 为什么选 `512, 1024, 2048, 4096`？
- 为什么先看 single-thread？
- 为什么再看 1、2、4 threads？
- 为什么区分 SVE build 和 128-bit baseline？
- 为什么单独 isolate tridiagonal eigensolver？
- 为什么 memory RSS 要和 runtime 一起讨论？

这类内容最能体现作者自己的研究过程。

## 15. 不建议做的事情

- 不要只做同义词替换。
- 不要故意加入语法错误。
- 不要把学术英语改得过度口语化。
- 不要删除 AI acknowledgement。
- 不要删除数学推导、表格或实验数字。
- 不要为了降低检测率牺牲技术准确性。

## 16. 推荐执行顺序

1. 改 `03_00.tex` 和 `03_01_Overview_of_Routine_Structure.tex`。
2. 改 `03_02_02_STEQR.tex` 和 `03_02_03_STEDC.tex` 的图前图后解释。
3. 改 `03_03_Discussion_and_Remarks.tex`，把总结改成实验假设。
4. 改 `04_02_benchmark.tex` 的 benchmark 开头、single-thread analysis、thread interpretation。
5. 改 `04_05_03_hardware_efficiency.tex` 的 counter 解释和结尾限制。
6. 小改 `main.tex` 的 Abstract。
7. 小改 `main.tex` 的 AI acknowledgement。
8. 用 `rg` 搜索模板句，做最后一轮全篇清理。
9. 重新编译 PDF。
10. 重新检测 AI rate，并记录哪些章节还有高风险。

## 17. 预期效果

如果只做表面替换，效果通常不稳定。更建议实质性重写 Chapter 3 和 Chapter 4 的说明性段落，尤其是：

- 章节开头；
- 图前图后解释；
- 表格后的 analysis；
- profiling/hardware-counter interpretation；
- conclusion-style summary。

目标是让论文更明确地体现：

- 你为什么这样比较；
- 你从代码路径中看到了什么；
- 你如何从数据推出结论；
- 你知道哪些结论不能过度推广。

