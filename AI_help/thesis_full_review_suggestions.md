# Thesis Review Suggestions from a Mathematics Master's Project Perspective

审阅对象：

- `latex/main.pdf`
- 对照源文件：`latex/main.tex` 与 `latex/chapters/**/*.tex`
- 视角：数学系硕士毕业 project，重点看数学自洽性、实验可信度、论证闭环、AI 痕迹和提交前风险。

## 1. 总体判断

这篇 thesis 现在的主线是成立的：

1. Chapter 2 给出数学基础：Householder reduction、implicit QR/QL、divide-and-conquer。
2. Chapter 3 把数学算法映射到 LAPACK 的 `DSYEV` 和 `DSYEVD` 路径。
3. Chapter 4 用实验数据解释 runtime gap 的来源。
4. Chapter 5 回答 routine selection 的实际问题，并说明 runtime--workspace tradeoff。

从数学系硕士 project 的角度看，Chapter 2 偏重数学推导不是问题，反而是项目的合理支撑。后续不建议再为了“数学太多”大幅删 Chapter 2。更重要的是保证：

- 数学符号和例子前后一致；
- 实验结论不过度外推；
- 数据来源、repeat protocol 和 validation 说得足够清楚；
- 文字不像模板化生成，而像作者自己围绕实验得出的判断。

当前页数也满足要求：

- `latex/main.toc` 显示 Chapter 5 从第 47 页开始；
- Future Work 在第 49 页；
- Appendix A 从第 50 页开始；
- 因此正文从 Introduction 到 Future Work 为 49 页，不含 Appendix 控制在 50 页以内。

## 2. 提交前优先修的具体问题

### 2.1 已完成：统一 Chapter 2.2 和 2.3 的代表性特征向量

位置：

- `latex/chapters/02_Mathematical_Foundations/02_02_STEQR.tex` lines 865--878。
- `latex/chapters/02_Mathematical_Foundations/02_03_STEDC.tex` lines 512--523。

问题：

2.2 和 2.3 使用同一个 \(6\times6\) tridiagonal test matrix，并且都报告最小特征值
\[
\lambda_1\approx 0.2538.
\]
2.3 的代表性 eigenvector 是

```tex
[0.7770, -0.5798, 0.2354, -0.0667, 0.0146, -0.0025]^T
```

这和直接数值计算一致。2.2 原先写成

```tex
[0.7800, -0.5800, 0.2400, -0.0700, 0.0100, 0]^T
```

它不是大错，但作为同一个 worked example，会让读者以为 `STEQR` 和 `STEDC` 给出了不同 eigenvector。最稳妥是统一数值；当前正文已经按下面的四位小数版本统一。

建议改法：

```tex
z_1 \approx
\left[\begin{array}{r}
0.7770\\
-0.5798\\
0.2354\\
-0.0667\\
0.0146\\
-0.0025
\end{array}\right].
```

状态：已将 2.2 的代表性 eigenvector 改为与 2.3 一致的四位小数版本。这个前后一致性问题已处理。

### 2.2 给 residual/orthogonality checks 补实际数值

位置：

- `latex/chapters/06_Appendices/06_02_experimental_details.tex` lines 335--341。
- 也可在 `latex/chapters/04_Experiments/04_01_setup.tex` lines 89--98 简短提一句。

当前 Appendix 只写：

```tex
which remained within recommended thresholds for all reported experiments.
```

问题：

这句话太泛。数学系论文里，实验 correctness checks 最好给出实际最大值或至少给出阈值。否则读者只能相信结果“通过了”，但看不到误差量级。

建议增加一个小表或一句话，例如：

```tex
Across the reported runs, the largest observed normalized residual was ...,
and the largest observed orthogonality error was ....
```

如果你已有 CSV/日志，建议填真实最大值。没有的话，至少写明使用的 threshold，例如 `O(10^{-12})` 或 LAPACK-style scaled tolerance，并说明它来自哪一个 check。

优先级：高。它能显著提高实验可信度。

### 2.3 在 Chapter 4 setup 主文补 repeat count 和 raw data pointer

位置：

- `latex/chapters/04_Experiments/04_01_setup.tex` lines 89--98。
- Appendix 已有 repeat protocol：`latex/chapters/06_Appendices/06_02_experimental_details.tex` lines 62--71。

问题：

Chapter 4 主文多处 caption 写 `median over repeated runs`，但 repeat count 主要在 Appendix。主文读者可能看完表格后还不知道 median 是几个 run 的 median。

建议在 Chapter 4 setup 的 performance measurement 段落后加一句：

```tex
For the benchmark and controlled-comparison tables, one warm-up run is discarded;
the reported medians use five measured runs for \(n\le 2048\) and three measured
runs for \(n=4096\), with CSV result snapshots stored under
\texttt{Code/chapter4/results/}.
```

优先级：高。这个改动小，但对 reproducibility 很有帮助。

### 2.4 把 KMS matrix 的外推边界提前到 Chapter 4 setup

位置：

- `latex/chapters/04_Experiments/04_01_setup.tex` lines 104--120。
- Conclusion limitations 已经有类似内容：`latex/chapters/05_Conclusion/05_03_limitations.tex` lines 17--23。

问题：

Chapter 5 已经说明 KMS matrix 不代表所有谱分布，但 Chapter 4 setup 里还可以更早提醒一次。否则读者看到 Chapter 4 数据时，可能会把结论理解成覆盖所有 dense symmetric matrices。

建议在 test matrices 段落末尾加一句：

```tex
The KMS family is used here as a controlled dense SPD test family, not as a
representative sample of all possible spectra or conditioning patterns.
```

优先级：中高。它能防止实验结论被误读为 universal claim。

## 3. 数学章节的优化建议

### 3.1 Chapter 2 的数学占比可以保留

Chapter 2 从第 4 页到第 28 页，确实是全文最大的一章。但这是数学系 project，可以接受。现在不建议继续压缩数学主干。保留原因：

- Householder reduction 解释了 dense-to-tridiagonal 的第一阶段；
- QR/QL section 解释了 `DSTEQR` 的 rotation-heavy 来源；
- D&C section 解释了 `DSTEDC` 的 split--merge 和 secular equation；
- Chapter 4 的性能解释依赖这些数学结构。

后续只做精修，不做大删。

### 3.2 QR subspace convergence 的假设可以更严谨

位置：

- `latex/chapters/02_Mathematical_Foundations/02_02_STEQR.tex` lines 50--112。

问题：

这里用 power/subspace convergence 引入 QR iteration。现在写了条件
\[
|\lambda_m|>|\lambda_{m+1}|.
\]
但还应说明初始 subspace 对目标 eigenspace 有非零投影，或者说这是 generic starting subspace 下的 motivation。否则严格数学上，若初始 subspace 与某些 eigenvectors 正交，结论不完整。

建议补一句：

```tex
This statement assumes a generic starting subspace whose projection onto
\(E_m\) has full rank; it is used here as motivation for QR iteration rather
than as a full convergence theorem.
```

优先级：中。

### 3.3 `6n^3` 和 D&C recurrence 的常数要说清楚是 model

位置：

- `latex/chapters/02_Mathematical_Foundations/02_03_STEDC.tex` lines 8--14。
- `latex/chapters/02_Mathematical_Foundations/02_03_STEDC.tex` lines 577--599。
- `latex/chapters/02_Mathematical_Foundations/02_04.tex` lines 61--78。

问题：

2.3 开头说 QR/QL full-eigenpair cost 的 standard estimate 是 \(6n^3\)。后面 D&C 用
\[
C(n)=n^3+2C(n/2)\sim \frac{4}{3}n^3.
\]
这作为解释可以，但从数学严格性看，常数依赖实现、deflation、leaf solver、是否形成全部 eigenvectors。建议把这些都写成 simplified cost model，而不是像精确 flop theorem。

建议补一句：

```tex
The constants here are used as a simplified leading-order model; LAPACK timings
also depend on deflation, leaf solvers, memory traffic, and BLAS kernels.
```

优先级：中。

### 3.4 Householder 和 transpose notation 最后统一

位置：

- `latex/chapters/02_Mathematical_Foundations/02_01_SYTRD.tex` lines 6--30。
- 全文多处混用 `^T`、`^\top`、`^\mathsf{T}`。

问题：

数学内容可以读懂，但 notation polish 不够统一。现在 Chapter 2 后半和 Abstract 多用 `^\mathsf{T}`，Chapter 2.1 和 Chapter 3 仍有 `^T`、`\top`。

建议最终统一成 `^\mathsf{T}` 或 `^\top`。如果只做小范围，优先统一 Chapter 2 的公式。

优先级：中低。

## 4. LAPACK 和实验解释的优化建议

### 4.1 Chapter 3 中 “bandwidth pressure” 表述略强

位置：

- `latex/chapters/03_LAPACK_Implementation/03_02_03_STEDC.tex` lines 111--118。

当前说法大意是 D&C reduces both arithmetic complexity and bandwidth pressure。问题是 Chapter 4.5.3 的 deep counters 显示 `DSTEDC` 的 L1 miss rate 和 stall-per-instruction 可能更高，只是累计 instruction/stall 更低。因此 “bandwidth pressure” 容易被反问。

建议改成更稳妥：

```tex
Compared with the traditional QR iteration, the D\&C approach reduces the
cumulative work in the eigenvector path and exposes more of that work through
blocked Level-3 BLAS kernels.
```

优先级：中高。这个能避免 Chapter 3 和 Chapter 4 counters 的细微冲突。

### 4.2 Hardware counters 的最后一句再限定一次 scope

位置：

- `latex/chapters/04_Experiments/04_05_03_hardware_efficiency.tex` lines 107--120。

前文已经多次说 isolated tridiagonal eigensolver stage，但最后一句又写到 “far less total hardware work than the rotation-dominated DSYEV path”。这里仍可能被理解成 end-to-end hardware work。

建议把最后一句明确为：

```tex
... for the isolated tridiagonal eigensolver stage.
```

优先级：中。

### 4.3 Deep-counter tables 是否放 Appendix

位置：

- `latex/chapters/04_Experiments/04_05_03_deep_candidate_tables.tex`。
- 现在正文 Chapter 4.5.3 直接 `\input` 这两张表。

判断：

正文现在 49 页，没有页数压力，所以不是必须移动。但从阅读流畅度看，这两张表是 supporting evidence，不是主证据。主证据是 instruction count、stall count 和 RSS。

建议：

- 如果最终想让 Chapter 4 更紧凑，把 deep-counter tables 移到 Appendix；
- 正文保留一句 “normalized deep-counter views are reported in Appendix ...”；
- 如果不想动结构，现在保留也可以。

优先级：低。

## 5. AI 痕迹和作者 voice

### 5.1 不要追求“骗过 AI detector”，要让论证更像自己的实验判断

现在已经减少了一批模板句，但全文仍有一些常见结构，例如：

- `This section provides...`
- `This section returns...`
- `The aim is not to...`
- `The point of Figure...`

这些不是错误，也不必全部改。更有效的做法是加入少量具体实验判断，例如：

- 为什么 sizes 选 \(512,1024,2048,4096\)；
- 为什么 KMS \(\rho=0.95\)；
- 为什么 thread test 只做 1, 2, 4；
- 为什么 hardware counters 只作为 explanatory evidence；
- 为什么 Chapter 1 Python-wrapper timing 只作为 motivation。

这些内容和你的实验绑定，比单纯换连接词更能降低 AI 式泛泛感。

### 5.2 AI acknowledgement 建议检查是否过宽

位置：

- `latex/main.tex` lines 360--378。

问题：

现在 AI acknowledgement 很完整，但也比较宽，尤其是：

- “helping form and refine ideas”
- “suggesting improvements to the design and presentation of experiments”
- “representative prompts included ...”

如果课程允许这样的 disclosure，则可以保留。但从提交风险角度，建议确认学院或课程对 AI acknowledgement 的要求。最稳妥的原则是：准确、具体、不夸大 AI 的作用，也不隐藏真实使用。

建议：

- 保留 AI 使用声明；
- 把 wording 收紧到实际使用过的范围；
- 强调 author independently verified mathematics, code, experiments, and conclusions；
- 避免让读者误解为 AI 参与了核心 mathematical argument 或 experimental interpretation 的原创性。

优先级：中高，因为你现在关心 AI 率和 AI 使用风险。

## 6. 逐章建议

### Chapter 1 Introduction

优点：

- 研究问题清楚：dense real symmetric full-eigenpair setting。
- Python-wrapper preview timing 已经和 Chapter 4 controlled benchmark 区分。
- Scope 明确，不再像泛泛 survey。

建议：

- `latex/chapters/01_Introduction/01_introduction.tex` lines 128--147 的 preview timing 可以保留。
- 若想进一步降低 AI 感，可在 Table 1.1 前补一句为什么先用 wrapper timing：它是 quick motivation，不是最终 benchmark。
- Chapter 1 不需要再加长。

### Chapter 2 Mathematical Foundations

优点：

- 对数学系硕士论文来说，这是最有学术分量的一章。
- 2.2 和 2.3 现在都保留了同一个 matrix 的 eigenvalues 和一个 representative eigenvector，便于 2.4 对比。

建议：

- 优先修 2.2 和 2.3 eigenvector 数值一致性。
- 对 subspace convergence 和 complexity constants 加两句限定，避免被问严格条件。
- 最终统一 transpose notation。

### Chapter 3 LAPACK Implementation

优点：

- 这一章起到很好的桥梁作用，把 Chapter 2 的算法和 Chapter 4 的 routine timings 接起来。
- `DSYEV`/`DSYEVD` 的 data flow 现在比较清楚。

建议：

- 把 `DSTEDC` “reduces bandwidth pressure” 类似说法改成 “reduces cumulative work / exposes blocked BLAS work”。
- 图的 caption 可以稍微更数据流导向，少用 “important feature” 这类模板词，但这不是必须。

### Chapter 4 Experiments

优点：

- 证据链完整：end-to-end timing -> stage timing -> BLAS backend -> SVE -> profile -> hardware counters -> memory tradeoff。
- Chapter 4 的核心结论可信：差距主要来自 tridiagonal eigensolver path，而不是 shared `DSYTRD`。

建议：

- 在 setup 主文补 repeat count 和 `Code/chapter4/results/` pointer。
- 在 setup 主文提前说明 KMS 是 controlled dense SPD family，不代表所有谱分布。
- Appendix 的 residual checks 补实际数值或 threshold。
- Hardware-counter section 的最后结论再限定为 isolated tri-eig stage。

### Chapter 5 Conclusion

优点：

- 结论没有过度宣称 `DSYEVD` universally better。
- runtime--workspace tradeoff 说得清楚。
- limitations 和 future work 合理。

建议：

- `latex/chapters/05_Conclusion/05_01_main_findings.tex` lines 5--25 仍有一点“总结式模板”语气，但内容正确。若有时间，可以把 “This thesis set out...” 改成更直接的 result-first opening。
- Practical guidance 很适合保留，因为它把 project 从纯算法说明落到 routine selection。

### Appendix, References, and Front Matter

建议：

- Appendix B 的 correctness checks 补 actual maxima 或 threshold。
- `latex/references.bib` 中 `MartinReinschWilkinson1968` 条目比较粗，建议补 volume/pages/doi 或至少完整 bibliographic fields。
- `gu1994rank`、`li1994secular` 如果正文没有引用，可以保留但不影响最终 bibliography，因为 BibTeX 通常只列 cited entries。
- `main.tex` 中 UNSW template 留下了很多未使用 macro 和注释，不影响 PDF，但最终版本如果时间充足可清理。不要在临交前大幅清理，避免引入 LaTeX 问题。

## 7. 建议执行顺序

如果只做一轮提交前修改，建议按这个顺序：

1. 修 2.2/2.3 eigenvector 数值一致性。
2. Appendix 或 Chapter 4 setup 补 residual/orthogonality 最大值或 threshold。
3. Chapter 4 setup 补 repeat count、warm-up、CSV result path。
4. Chapter 4 setup 补 KMS matrix scope。
5. Chapter 3 修 `bandwidth pressure` 的过强表述。
6. Hardware-counter conclusion 最后再限定 isolated tri-eig stage。
7. 检查 AI acknowledgement 是否符合课程要求。
8. 最后做 notation/overfull/reference polish。

## 8. 最终评价

以数学系硕士 project 标准看，当前 thesis 不需要重写，也不需要再压缩数学主体。它的强项是：数学算法、LAPACK routine path 和实验数据之间有清楚对应关系。

现在最大的改进空间不是“加更多内容”，而是把少数容易被 examiner 抓住的地方补严谨：

- 同一 worked example 的 eigenvector 要一致；
- correctness checks 要有实际误差量级；
- experimental protocol 要在主文中足够透明；
- KMS 和 4-vCPU thread study 的 scope 要说清楚；
- AI acknowledgement 和正文 voice 要准确、自然、不过度模板化。

完成这些之后，论文会更像一个完整的数学硕士 project：有理论推导，有可复现实验，有限制说明，也有明确的 routine-selection 结论。
