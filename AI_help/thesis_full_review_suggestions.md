# Thesis Full Review Suggestions for `latex/main.pdf`

审阅对象：

- `latex/main.pdf`
- 对照阅读的源文件：`latex/main.tex` 与 `latex/chapters/**/*.tex`
- 已参考现有记录：`AI_help/ai_2_revision_plan.md`、`AI_help/revision_notes.md`

审阅重点：

- 从 Introduction 到 Conclusion/Future Work 的正文逻辑是否完整；
- 技术论证、实验叙述和结论是否一致；
- 正文从 Introduction 开始、不含 Appendix 是否控制在 50 页以内；
- 哪些修改最值得做，以及哪些修改会带来页数风险。

## 1. 页数和编译状态

当前页数状态是满足要求但没有余量。

- `latex/main.log` 显示整份 PDF 输出为 68 pages。
- `latex/main.toc` 显示：
  - Chapter 1 `Introduction` 从第 1 页开始；
  - Chapter 5 `Future Work` 在第 50 页；
  - Appendix A 从第 51 页开始。
- 因此，按“正文从 Introduction 开始，不带 appendix”计算，Chapter 1 到 Chapter 5 正好是 50 页。

这意味着后续任何新增段落、表格或图说明都可能把 Appendix 推到第 52 页。建议采取“先删减再新增”的修订策略。最安全的目标不是保持 50 页，而是压到 47 到 49 页，给最终排版、图表浮动和导师要求留出缓冲。

编译警告方面，当前没有明显的 undefined reference 或 missing citation 警告。主要排版问题是少量 overfull/underfull：

- `latex/chapters/02_Mathematical_Foundations/02_02_STEQR.tex` lines 590--596 附近有 overfull hbox。
- `latex/chapters/02_Mathematical_Foundations/02_02_STEQR.tex` line 839 附近有 overfull hbox。
- `latex/chapters/06_Appendices/06_02_experimental_details.tex` lines 312--315 附近有轻微 overfull hbox。
- bibliography 里的 GitHub URL 有 underfull hbox，属于长 URL 常见问题。

这些不是内容性错误，但最终提交前建议处理。

## 2. 总体判断

论文主线是清楚的：先讲 dense symmetric eigenproblem 的三阶段结构，再比较 QR/QL 与 divide-and-conquer 的三对关系：

- Chapter 2：数学算法差异；
- Chapter 3：LAPACK driver path 差异；
- Chapter 4：实验和 profiling 证明差异主要来自 tridiagonal eigensolver/eigenvector path；
- Chapter 5：把结论落到 runtime-workspace tradeoff。

目前最大的优点是论证链条已经闭合：`DSYEV`/`DSYEVD` 的总时间差、stage timing、profiling、hardware counters、memory footprint 都指向同一个解释。

最大的风险有四个：

1. 正文刚好 50 页，任何新增都会超页。
2. Chapter 2 太长，数学推导和 worked examples 占了正文的大部分，会压缩实验贡献的空间。
3. 少数技术表述需要更精确，特别是 Householder rank-2 update 的 scaling、D&C secular equation 中 `rho` 的符号约定、Chapter 4 中 Netlib/OpenBLAS stack 的描述。
4. Chapter 1 的 preview timing 与 Chapter 4 benchmark timing 不一致，但没有在 caption 或正文中说明来源，容易让读者误以为数据冲突。

## 3. 最高优先级修改

### 3.1 先释放 2 到 4 页正文空间

当前正文正好 50 页。建议先从 Chapter 2 和 Chapter 4 表格释放空间。

最推荐的删减顺序：

1. 压缩或移出 `latex/chapters/02_Mathematical_Foundations/02_02_STEQR.tex` 的 worked example，尤其是 lines 658--971。
   - 保留矩阵、Wilkinson shift、bulge path、deflation summary 即可。
   - 大量中间矩阵和一个 eigenvector column 可以移到 Appendix 或删去。
   - 预计可节省 2 到 3 页。

2. 删除 Chapter 2.2 中重复的 implicit shifted QR equivalence 推导。
   - lines 444--525 已经通过 Implicit Q theorem 解释 equivalence；
   - lines 527--635 又以 “Core Derivation” 重讲一遍。
   - 建议二选一，保留 theorem + 简短 derivation。
   - 预计可节省约 1 页。

3. 压缩 `latex/chapters/02_Mathematical_Foundations/02_03_STEDC.tex` 的 running example。
   - 现在在 split、subproblem、merge、secular equation、eigenvector reconstruction 多处重复展开。
   - 建议保留 split 和 secular equation 两处，其余用一句话连接。
   - 预计可节省 1 到 2 页。

4. 把 `latex/chapters/04_Experiments/04_05_03_deep_candidate_tables.tex` 的 deep-counter tables 移到 Appendix。
   - Chapter 4 主文已经有 compact instruction/stall table。
   - deep-counter tables 是 supporting evidence，不是核心论证必需。
   - 预计可节省半页到 1 页。

这样做以后，正文可以从 50 页降到约 46 到 48 页。之后再补少量必要解释也不会超页。

### 3.2 给 Chapter 1 的 preview table 加实验来源

位置：`latex/chapters/01_Introduction/01_introduction.tex` Table `tab:timing`。

问题：Chapter 1 preview table 的 full eigenpair timing 与 Chapter 4 OpenBLAS SVE benchmark 不同。例如：

- Chapter 1: at `n=4096`, `DSYEV` eigpairs = `106.606` s, `DSYEVD` eigpairs = `19.804` s。
- Chapter 4: at `n=4096`, `DSYEV` = `66.255` s, `DSYEVD` = `14.482` s。

这不一定错，但目前没有说明 Table 1.1 是哪个 backend、thread setting、run protocol 或 preliminary run。读者可能以为同一实验给了两组不同结果。

建议二选一：

- 最稳妥：把 Chapter 1 preview table 换成 Chapter 4 的 OpenBLAS SVE data，并说明 eigenvalues-only 只是 preview。
- 或者：保留现有数据，但 caption 加上 backend/thread/repetition 信息，例如 `preliminary single-thread timing under ...`，并在正文说 Chapter 4 uses a separately controlled OpenBLAS SVE benchmark。

### 3.3 修正 Householder rank-2 update 的 scaling 说明

位置：`latex/chapters/02_Mathematical_Foundations/02_01_SYTRD.tex` lines 76--88。

当前写法：

```tex
A^{(j+1)} = A^{(j)} - u y^T - y u^T,
\qquad
y = A^{(j)} u - \frac{1}{2}(u^T A^{(j)}u)\,u.
```

这个公式依赖于 `u` 的归一化约定。前面 Householder reflector 写成

```tex
H = I - 2 vv^T/(v^Tv)
```

如果这里的 `u` 不是普通未归一化 Householder vector，而是满足 `H = I - uu^T` 的 scaled vector，则公式成立。现在文本只说 “Let `u` denote the Householder vector”，容易造成 scaling 不清。

建议改成：

- 明确 `u` 是 scaled Householder vector, chosen so that `H_j = I - u u^T`；
- 或者改用 LAPACK-style `tau` 形式：`H = I - tau v v^T`，再写对应的 symmetric rank-2 update。

这是技术准确性优先项，建议一定改。

### 3.4 明确 divide-and-conquer 中 `rho` 的符号约定

位置：`latex/chapters/02_Mathematical_Foundations/02_03_STEDC.tex`，特别是 lines 28--31、89--123、461--498。

当前 split 定义 `rho := b_m`，但后面 secular equation/interlacing proposition 假设 `rho > 0`。对于一般实对称 tridiagonal matrix，`b_m` 可能为负。当前 KMS example 里是正的，所以例子没问题，但一般理论表述需要补一句。

建议：

- 在 notation 处说明 “for the exposition below we take `rho > 0`; if the removed coupling is negative, its sign can be absorbed into the splitting vector or the interlacing intervals are adjusted accordingly”。
- 或者定义 `rho = |b_m|` 并把 sign absorbed into `u`。

这样可以避免 theorem 的假设和前面定义不完全一致。

### 3.5 澄清 Netlib-to-OpenBLAS 比较到底改变了什么

位置：`latex/chapters/04_Experiments/04_03_blas.tex` lines 7--12；也关联 `latex/chapters/04_Experiments/04_01_setup.tex`。

当前 Chapter 4 setup 表示三种配置的 LAPACK layer 都是 Reference LAPACK lineage，OpenBLAS SIMD/SVE 主要差别在 BLAS kernels。可是 Section 4.3 写道 “both the LAPACK and BLAS layers change”。这容易被认为与 Table 4.1 矛盾。

建议改成更精确的说法：

- 如果实际是 Reference LAPACK linked against different BLAS libraries，就写 “the LAPACK source lineage is kept fixed, while the BLAS backend and build configuration change”。
- 如果实际 OpenBLAS build also supplies LAPACK objects，那么需要在 setup 表格里说清楚 OpenBLAS 的 LAPACK objects 与 Netlib objects 的关系。

这关系到实验 attribution，建议优先处理。

### 3.6 SVE section 的 table scope 要收紧或补全

位置：`latex/chapters/04_Experiments/04_04_simd.tex` lines 21--22 和 table `tab:simd-speedup`。

正文说 “for each computational stage”，但表格只列了：

- `DSYTRD` for `DSYEV`
- `DSTEQR`
- `DSYTRD` for `DSYEVD`
- `DSTEDC`

没有列 `DORGTR` 和 `DORMTR`，而这两个 back-transformation stages 在前文中非常重要，尤其 `DORMTR` 在 `DSYEVD` end-to-end profile 中占比很高。

建议二选一：

- 补上 `DORGTR` 和 `DORMTR` 的 SIMD speedup columns；
- 或者把文字改成 “selected stages”/“the stages measured in this SIMD experiment”，并解释为什么 back-transformation 不在此表中。

如果数据已经有，建议补列；如果没有，建议收紧措辞。

## 4. 逐章建议

### 4.1 Front Matter and Abstract

整体不错。Abstract 能从数学问题讲到 LAPACK 实验，再落到 runtime-workspace tradeoff。

小建议：

- `main.tex` lines 262--264: “eigenvectors may be chosen orthogonally” 建议改为 “eigenvectors may be chosen to form an orthonormal basis”。数学上更自然。
- Abstract 已经包含具体 `n=4096` timing 和 RSS，信息量较大但可接受。如果正文页数紧张，Abstract 不计入正文，可以保留。
- AI acknowledgement 内容比较完整，但它现在放在 `\appendix` 之后。若学校要求 AI acknowledgement 属于 back matter 而不是 appendix，建议调整位置或命令结构，见第 6 节。

### 4.2 Chapter 1 Introduction

优点：

- 开头直接建立三阶段路线：dense reduction, tridiagonal eigensolver, back transformation。
- Scope 比较清楚，没有试图泛泛 survey 全部 eigensolvers。
- Project aims 与后文结构一致。

建议：

- Table 1.1 必须说明数据来源或替换为 Chapter 4 一致数据，见第 3.2 节。
- lines 128--132 和 Section 1.2 中对 `DSYEV`/`DSYEVD` 的介绍有少量重复。如果需要省空间，可以压缩 Section 1.3 开头两句。
- Section 1.4 的 aims 可以更明确地写 “full eigenpair case (`JOBZ='V'`) is the main experimental object”。现在要到后文才完全明确。
- Figure 1.1 有帮助，但若最终页数超了，可以考虑缩小 vertical spacing，而不是删除图。

### 4.3 Chapter 2 Mathematical Foundations

这是当前最需要控制篇幅的章节。它从第 4 页到第 30 页，约 27 页，占正文超过一半。对于一篇以 implementation/performance comparison 为核心的 thesis，数学基础足够扎实，但比例偏重。

#### Householder section

- 技术重点是 rank-2 update scaling，见第 3.3 节。
- `Q^T`、`Q^\top`、`Q^{\mathsf T}` 混用较多。建议全篇统一为 `^\mathsf T` 或 `^\top`。
- `\tag{$\star$}` 可以换成 `\label{eq:householder-rank2}`，后文引用更正式。

#### QR/QL section

当前内容很完整，但有明显压缩空间。

建议：

- 删除或合并 “Spectral Decomposition and Subspace Convergence” 与 “Block Iteration and the QR Iteration” 中与主线关系较远的推导。你的 thesis 不需要完整从 subspace iteration 推导到 QR algorithm，保留 one-page motivation 足够。
- Implicit Q theorem 与 “Core Derivation of the Implicit--Shift QR Step” 重复。保留 theorem + short explanation 即可。
- Worked example 过长。建议压缩为：
  - 6x6 matrix；
  - Wilkinson shift；
  - first Givens creates bulge；
  - bulge path table；
  - subdiagonal decay summary；
  - 一句说明 eigenvectors are accumulated when requested。
  中间大矩阵可以移到 Appendix。
- lines 919--971 的 eigenvector discussion 可以删短。因为 D&C section 也给了同一个 smallest eigenvector，两个近似值略有差别，反而可能让读者分心。

#### Divide-and-conquer section

优点是 split, rank-one merge, secular equation, reconstruction 的逻辑很清楚。

建议：

- 补 `rho` 符号约定，见第 3.4 节。
- Running example 出现次数较多。保留能说明 rank-one merge 的关键数值，其他细节可移到 Appendix。
- Secular equation 的 derivation 很好，建议保留。
- `li1994secular` 和 `gu1994rank` 在 bibliography 中存在，但正文似乎主要引用 `gu1995divide` 与 `parlett1998symmetric`。如果你讨论 stable secular equation solving，可以增加对 Li 1994 或 Gu-Eisenstat rank-one paper 的引用；如果不打算展开，可以保持现状。

#### Algorithm comparison section

建议把 `\texttt{STEQR}`/`\texttt{STEDC}` 改成 “QR/QL route”/“divide-and-conquer route”，或者明确说这些 names are used as shorthand for the mathematical routines before Chapter 3。否则 Chapter 2 “mathematical foundations” 与 LAPACK routine names 有一点混杂。

### 4.4 Chapter 3 LAPACK Implementation

这一章总体比较强，页数也合适。它很好地把 Chapter 2 的算法差异转成 driver path。

建议：

- `DSTEQR` figure 和 `DSTEDC` figure 都有帮助，但两张 vertical flowcharts 占空间。如果正文超页，优先保留其中一张，另一张改成 table or prose。
- `latex/chapters/03_LAPACK_Implementation/03_02_03_STEDC.tex` lines 328--338: “reduces both arithmetic complexity and bandwidth pressure” 建议稍微收紧。D&C 不一定总是降低 bandwidth pressure，它主要降低 total work 并把 work 组织成更 BLAS-friendly blocked operations。可改为 “reduces total work in the eigenvector path and makes memory traffic more amenable to blocked kernels”。
- Chapter 3 结尾现在是清楚的，但可以把最后一段更明确地写成 Chapter 4 的实验假设：
  - `DSYTRD` should be similar；
  - `DSTEQR` should dominate `DSYEV`；
  - `DSTEDC`/`DORMTR` should show more blocked work；
  - `DSYEVD` should use more memory。
  这会让 Chapter 4 看起来更像验证前面结构判断，而不是事后解释。

### 4.5 Chapter 4 Experiments

这是论文贡献最核心的章节，整体方向正确。主要建议是让实验控制和表格范围更精确。

#### Setup

- `04_01_setup.tex` 对 hardware/software/matrix family 的说明足够。
- 建议在 main text 中也直接写出 repeat count：`five measured runs for n <= 2048 and three for n=4096`。现在这个信息在 Appendix，有些读者只看 Chapter 4 时会不知道 “median over repeated runs” 具体是多少。
- KMS matrix 的选择解释较好。可以再加一句 limitation：KMS is a controlled dense SPD family, not a representative sample of all spectral distributions。Conclusion 已经有类似内容，所以这里不一定要加。

#### Overall benchmark

- `04_02_benchmark.tex` analysis 里说 `DSYEVD` is already faster once `n >= 1024`，但表中 `n=512` 也更快。建议改成 “faster at all tested sizes, with the gap becoming more meaningful from n >= 1024”。
- 建议补一句 back-transformation nuance：在 `n=4096`，`DSYEVD` 的 back-transformation `5.914` s 比 `DSYEV` 的 `3.853` s 更长，但 tri-eig saving 远大于这个额外成本。这能避免读者误读为 `DSYEVD` 每个 stage 都更快。
- Thread scalability 已经写得稳妥。可再加一句 “This is not intended as a full parallel scaling study”，避免被问为什么只到 4 threads。

#### Netlib-to-OpenBLAS section

- 重点见第 3.5 节：要澄清 comparison stack。
- Table `tab:blas-speedup` 很有价值，建议保留。
- Interpretation 很好，尤其 `DSTEQR` 约 `1.0x` 与 `DSTEDC`/back-transform 的 contrast。

#### SVE vectorization section

- 重点见第 3.6 节：table scope 与正文不完全匹配。
- 如果补不上 `DORGTR/DORMTR`，把 “each computational stage” 改成 “the measured reduction and tridiagonal-solver stages”。
- 结论 “SVE is secondary” 是合理的，因为最大变化已经来自算法路径和 blocked work availability。

#### Profiling and hardware counters

- Profiling section 的 hot-path table 很强，建议保留。
- Appendix 中已有 detailed call trees，正文里不需要再展开过多 tree details。
- Hardware section 的 compact instruction/stall table 很有说服力，建议保留。
- Deep-counter tables 可以移到 Appendix。正文只保留一句 “normalized counters are reported in Appendix and do not overturn the cumulative-count interpretation”。
- `04_05_03_hardware_efficiency.tex` lines 225--239 附近句子有语法问题：`Table ... reports ..., DSTEQR executes ...` 中间应断句。建议改为 “Table ... reports ... . In this isolated stage, ...”。
- 同一节中 “total hardware cost” 建议限定为 “for the isolated tridiagonal eigensolver stage”，避免被理解为 end-to-end hardware cost。

### 4.6 Chapter 5 Conclusion and Future Work

这一章现在比较成熟，和 Chapter 4 数据对得上。

优点：

- 结论没有说成 universal ranking，而是 runtime-workspace tradeoff。
- Limitations 讲了 platform、matrix family、single-node CPU、criteria，这些边界是必要的。
- Future work 自然：libraries/machines、more input families、runtime-memory-accuracy-energy、GPU/distributed。

建议：

- `05_02_practical_guidance.tex` 中 “dense SPD KMS matrices” 很准确，但可以再强调 recommendation applies to `JOBZ='V'` full eigenpairs，不适用于 eigenvalues-only routine choice。
- Conclusion 中重复了多次 `n=4096` numbers。可以接受，因为这是核心证据；如果需要省半页，可以减少一次重复。
- “The faster driver is therefore not simply the one with better BLAS tuning” 这类句子很有辨识度，建议保留。

## 5. 正文压缩方案

如果导师要求必须严格低于 50 页，建议按以下顺序执行。

### 方案 A：最小改动，目标 49 页

- 删除 QR worked example 中的一个或两个大矩阵展示。
- 把 deep-counter tables 移到 Appendix。
- 合并 Chapter 4 thread scalability 的两张表，或者只保留 `n=4096` speedup table。

风险低，但释放空间有限。

### 方案 B：推荐方案，目标 47 到 48 页

- QR worked example 压缩 50% 以上。
- 删除重复 implicit QR equivalence derivation。
- D&C running example 只保留 split 和 secular equation 两个数值点。
- deep-counter tables 移到 Appendix。

这是最平衡的方案：保留数学完整性，同时让实验章显得更突出。

### 方案 C：大幅精简，目标 45 到 46 页

- Chapter 2.2 只保留 QR/QL 的必要概念：shift, deflation, bulge chasing, eigenvector accumulation, cost。
- 把大部分 derivations 和 both worked examples 移到 Appendix。
- Chapter 3 flowcharts 改成一个 compact comparison table。

这个方案页数最稳，但数学 exposition 会明显变短，只有在页数压力很大时采用。

## 6. LaTeX 和结构性排版建议

### 6.1 References 和 AI acknowledgement 的位置

当前 `main.tex` 的顺序是：

```tex
\include{chapters/05_Conclusion/05_main}
\appendix
\include{chapters/06_Appendices/06_main}
...
\addcontentsline{toc}{chapter}{References}
\bibliography{references}
...
\chapter*{Acknowledgement of AI Use}
```

也就是说 References 和 AI acknowledgement 都出现在 `\appendix` 之后。它们不会变成 numbered appendix chapter，但在结构上属于 appendix 之后的 back matter。

建议确认学校格式要求。如果 References 应该在 Appendices 之前，就改为：

```tex
\include{chapters/05_Conclusion/05_main}
\clearpage
\addcontentsline{toc}{chapter}{References}
\bibliographystyle{unsrt}
\bibliography{references}
\appendix
\include{chapters/06_Appendices/06_main}
\clearpage
\chapter*{Acknowledgement of AI Use}
```

如果学校要求 AI acknowledgement 放在 front matter 或 before references，也需要相应调整。这个不一定影响正文 50 页，但影响最终提交结构。

### 6.2 Float placement

正文里有较多 `[H]`。它能固定表格位置，但容易造成空白和页数不稳定。建议：

- 核心小表可以继续 `[H]`；
- 大表、worked example 表、profiling 表尽量用 `[htbp]`；
- Chapter 2 的大矩阵展示如果保留，避免连续多个 display math + `[H]` figure/table。

### 6.3 统一 notation 和 typography

建议统一以下写法：

- transpose: 统一 `^\mathsf T` 或 `^\top`；
- divide-and-conquer: 统一 `divide--and--conquer`，缩写 `D\&C` 只在首次定义后使用；
- eigenpair/eigenpairs: `full eigenpair case` 可以保留，但有些地方用 `full eigenpairs` 更自然；
- `QR/QL` 与 `QR` viewpoint：若一节主要采用 QR viewpoint，开头说清楚 QL 只是 LAPACK implementation variant。

## 7. 建议执行顺序

1. 先处理技术准确性：
   - Householder rank-2 scaling；
   - D&C `rho` sign convention；
   - Netlib/OpenBLAS stack wording；
   - SVE table scope。

2. 再处理数据一致性：
   - Chapter 1 timing table source；
   - Chapter 4 benchmark interpretation 中 back-transformation nuance；
   - repeat count 是否需要进 main text。

3. 然后压缩页数：
   - QR worked example；
   - duplicate Implicit Q derivation；
   - D&C repeated running example；
   - deep-counter tables。

4. 最后跑一次 LaTeX 编译，检查：
   - Appendix 是否仍从第 51 页或更早开始；
   - 是否仍无 undefined references/citations；
   - overfull hbox 是否减少；
   - References/AI acknowledgement 顺序是否符合提交要求。

## 8. 最终建议摘要

当前 thesis 已经具备完整闭环，不需要推倒重写。最值得做的是“减法”和“精确化”：

- 减少 Chapter 2 中过长的推导和 worked examples，让正文给实验贡献留出空间；
- 明确 Chapter 1 preview timing 的来源，避免与 Chapter 4 数据看起来冲突；
- 修正少数数学和实验 attribution 的精确性问题；
- 保持 Chapter 4 的核心证据链：stage timing -> profiling -> counters -> memory tradeoff；
- 把正文压到 47 到 49 页，而不是卡在 50 页。

如果只做一轮修改，建议优先完成第 3 节列出的六项。
