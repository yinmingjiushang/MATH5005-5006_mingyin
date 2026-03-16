# 实验 4.4：为什么 Tri-eig 阶段 DSYEVD 快、DSYEV 慢？—— 原因分析设计

**前提**：表 4.1 已说明「syevd 比 syev 快的主要原因在解三对角（Tri-eig）」。
**目标**：分析**原因**——为什么 DSTEQR（QR）慢、为什么 DSTEDC（分治）快、**快在哪**。

---

## 一、算法层面：为什么 QR 慢、分治快

### 1.1 DSTEQR（DSYEV 的 Tri-eig）

- **算法**：对称三对角矩阵的 **QR 迭代**（implicit QR）。
- **单次迭代**：对三对角做一次 QR 步，每步 O(n) 的标量/向量运算（Givens 旋转、2×2 特征值 dlae2、应用旋转 dlasr 等）。
- **迭代次数**：与特征值分布有关；最坏或聚类严重时迭代次数可达到 O(n) 量级。
- **总工作量**：约 O(迭代次数 × n)；**没有成规模的 BLAS Level 3（DGEMM）**，主要是标量、Level 1/2 小核（dlasr 等）。
- **结论**：**DSTEQR 慢** = 迭代多 + 每步都是小规模、顺序依赖的运算，无法从 DGEMM 的缓存/向量化中受益。

**参考文献**：LAPACK User's Guide (node48/node70)；Numerical Linear Algebra / Numerical Methods in Matrix Computations 中 QR 法章节。

### 1.2 DSTEDC（DSYEVD 的 Tri-eig）

- **算法**：Cuppen **分治**（divide-and-conquer）：将三对角分成两块，递归求特征对，再用 **rank-1 修正** 合并（解 secular 方程 + 用特征向量做矩阵乘法更新）。
- **合并步**：解 secular 方程（dlaed4 等）是标量/小规模；**把合并后的特征向量写回** 需要 **矩阵–矩阵乘法**，即 **DGEMM**（在 LAPACK 里对应 DLAED3 → DGEMM）。
- **总工作量**：O(n²) 或 O(n² log n) 量级，且**主要时间花在 DGEMM** 上。
- **结论**：**DSTEDC 快** = 算法把主要工作量集中在 **DGEMM** 上，而 DGEMM 在 OpenBLAS 里被高度优化（分块、SIMD、多线程），缓存和向量化利用率高。

**参考文献**：Cuppen’s Divide and Conquer Algorithm；A Serial Implementation of Cuppen's Divide and Conquer Algorithm；LAPACK User's Guide (xSTEDC)。

---

## 二、实验层面：快在哪 —— perf 热点对比

**核心对比**：在**同一 OpenBLAS** 下，对 **DSYEV** 和 **DSYEVD** 分别做 perf 采样，看 **Tri-eig 阶段** 的时间分别花在哪些符号上。

### 2.1 DSYEVD（你已有结果）

`perf report` 下 Tri-eig（`__wrap_dstedc_`）的调用链大致为：

```
__wrap_dstedc_ → dstedc_ → dlaed0_ → dlaed1_ → dlaed3_ → dlaed3_single
    ├── dgemm_ (dgemm_nn) → dgemm_kernel   ← 约 11.58% 总时间
    └── dlaed4_                             ← 约 2.68%（secular 方程）
```

**解读**：Tri-eig 里大部分时间在 **DGEMM**（合并步的矩阵乘法），即「快」在 **BLAS Level 3 的优化**（dgemm_kernel）。

### 2.2 DSYEV（需要补跑）

对 **benchmark-syev-openblas**（或 4.3 的 syev OpenBLAS 可执行文件）做：

```bash
perf record -g -F 99 -- ./benchmark-syev-openblas   # 取足够长运行（如大 N）
perf report -g 'symbol,dso' --stdio
```

**预期**：Tri-eig 的时间几乎全在 `dsteqr_` 及其子调用，例如：

- `dsteqr_` → `dlasr_`、`dlartg_`、`dlae2_`、`dlaebz_`、`dlasrt_` 等
- **没有** 或几乎没有 `dgemm_` / `dgemm_kernel`

**解读**：**DSYEV 的 Tri-eig 慢** = 时间都耗在标量/小核上，无法享受 DGEMM 的缓存与 SIMD，与算法结构一致。

### 2.3 对比小结（写进论文/报告）

| 项目           | DSYEV (Tri-eig)     | DSYEVD (Tri-eig)        |
|----------------|---------------------|--------------------------|
| 主要时间所在   | dsteqr_ 及标量/小核 | dstedc_ → **dgemm_** → dgemm_kernel |
| 是否大量 DGEMM | 否                  | 是（合并步）             |
| 快/慢的原因    | 无 Level 3，难优化  | 以 DGEMM 为主，易优化   |

结论句：**「快在哪」= DSTEDC 把 Tri-eig 的主要工作量放在 DGEMM 上，OpenBLAS 对 DGEMM 的优化（分块、SIMD、缓存）直接带来加速；DSTEQR 没有这类大块 Level 3 运算，因此慢。**

---

## 三、为什么「用 DGEMM」能达到几十倍加速？（缺的这一环）

「DSTEDC 以 DGEMM 为主」只说明了**形态**，没有说明**为什么**这种形态能带来几十倍加速。原因可以拆成两层：**算法做的工作量更少** + **单位工作量执行得更高效**。

### 3.1 因素一：算法工作量更少（算得少）

- **DSTEQR**：QR 迭代，单次迭代 O(n)，但**迭代次数**与特征值分布强相关。最坏或特征值聚类严重时，迭代次数可达 O(n) 甚至更多，总工作量约为 **O(迭代次数 × n)**，实践中常呈 **O(n²) 到 O(n³)** 量级（表 4.1 里 DSYEV 的 Tri-eig 随 n 增长很陡，可画图验证）。
- **DSTEDC**：分治 + 合并。合并步是解 secular 方程（O(n) 或 O(n²)）加上**若干次 DGEMM** 更新特征向量，总合并成本 **O(n²)** 或 O(n² log n)；整体 Tri-eig 阶段 **O(n²)** 或略高。
- **结论**：在相同 n 下，DSTEDC 的 **总运算量（浮点次数）** 通常远小于 DSTEQR——**不是同一份工作「用 DGEMM 算得更快」，而是分治算法本身「要算的东西就少」**。这是几十倍加速里的**第一块**：算得少。

### 3.2 因素二：单位工作量执行得更高效（算得快）

即使工作量相同，**用 DGEMM 表达**也比用标量/小核表达要快得多，原因有三：

1. **缓存与分块**  
   DGEMM 用分块算法，使块内数据尽量留在 L1/L2/L3，**算术强度**高（O(n³) 次运算对 O(n²) 数据），访存能被充分摊薄。DSTEQR 的 dlasr/dlae2 等是逐列/逐元素、顺序依赖，**复用差、算术强度低**，更容易受内存带宽限制。

2. **SIMD 与向量化**  
   OpenBLAS 的 DGEMM 内核用 SIMD（NEON/SVE/AVX），一条指令完成多组乘加，**每周期浮点吞吐高**。DSTEQR 内层多是标量或短向量，编译器难以自动向量化，**每周期浮点吞吐低**。

3. **计算受限 vs 访存受限**  
   分块合适的 DGEMM 在较大 n 下是 **计算受限**（CPU 算力占满）；DSTEQR 的标量链多为 **访存受限** 或 **控制/分支多**，CPU 利用率低。同一块芯片上，前者的「有效 GFLOPS」可以比后者高一个数量级以上。

**结论**：**「用 DGEMM」= 把剩余工作都放在高算术强度、高 SIMD、易成计算受限的核心里执行**，所以**单位工作量执行得更快**。这是几十倍加速里的**第二块**：算得快。

### 3.3 综合：几十倍 ≈ 算得少 × 算得快

- **加速比** 可粗估为：  
  **（DSTEQR 总工作量 / DSTEDC 总工作量）×（DSTEDC 单位工作量效率 / DSTEQR 单位工作量效率）**  
  两项都可以是数倍到十余倍（例如 5×5 ≈ 25×，或 3×10 ≈ 30×），合起来就是**几十倍**。
- **论文/报告中的一句话总结**：  
  「STEDC 用 DGEMM 能达到几十倍加速，一方面因为分治算法在 Tri-eig 阶段的总运算量远小于 QR 迭代（算得少），另一方面因为 DGEMM 以分块、SIMD 和高算术强度在硬件上执行得远优于 QR 的标量/小核（算得快）；二者相乘，得到观测到的加速比。」

### 3.4 可选：用数据支撑「算得少」和「算得快」

- **算得少**：用表 4.1 的 Tri-eig 时间画 **时间 vs n**（或 vs n²、n³）；DSYEV 曲线更陡、DSYEVD 更缓 → 与「DSTEQR 工作量随 n 增长更快」一致。若能从文献或 LAPACK 注释得到每步浮点次数，可粗略估计 DSTEQR 与 DSTEDC 的运算量比。
- **算得快**：对 **同一 n**，用 Tri-eig 时间与（估计的）浮点次数算 **有效 GFLOPS**：DSYEVD 的 Tri-eig 有效 GFLOPS 远高于 DSYEV，即「单位工作量执行得更高效」。若有 perf 在 DSTEDC 路径下 DGEMM 的占比，可再说明这部分时间对应的是高 GFLOPS 的 DGEMM 内核。

---

## 四、可选：Tri-eig 时间随 N 的增长（复杂度直观）

用表 4.1 中「Tri-eig」列的数据（或 4.3 的 stage CSV）：

- 对 **DSYEV**：画 Tri-eig 时间 vs n（或 vs n²、n³），看增长趋势（预期接近或超过二次、甚至接近三次）。
- 对 **DSYEVD**：画 Tri-eig 时间 vs n，预期近似 **O(n²)** 或略高。

**目的**：用实测曲线支撑「DSTEQR 随 n 增长更陡、DSTEDC 更缓」，与理论复杂度一致，作为「为什么 QR 慢、分治快」和「算得少」的补充证据。

---

## 五、实验 4.4 建议流程（只做「原因」）

1. **算法简述**（文字 + 文献）：DSTEQR = QR 迭代、无成规模 DGEMM；DSTEDC = 分治、合并步用 DGEMM。说明「为什么从算法上 DSTEDC 更容易快」。
2. **Perf 热点**：
   - DSYEVD：沿用现有 `benchmark-syevd-openblas.perf.txt`，指出 Tri-eig 中 DGEMM 占比高。
   - DSYEV：对 **benchmark-syev-openblas** 跑一次 `perf_syevd.sh` 或等价命令，得到 Tri-eig 在 dsteqr_ 内、无 DGEMM。
3. **对比表**：如上「对比小结」表格，写进正文。
4. **可选**：表 4.1 的 Tri-eig 列画图（时间 vs n），简要说明复杂度差异。

**不需要**：LAPACK vs OpenBLAS 的库级对比、DGEMM 微基准、perf stat 等。

---

## 六、4.4 需要准备的二进制

- **DSYEVD**：已有 `benchmark-syevd-openblas`（4.4 或 4.2 构建）。
- **DSYEV**：需要能跑 OpenBLAS 的 **syev** benchmark。若 4.4 当前只构建了 syevd，可：
  - 用 **4.3** 的 `benchmark-syev-openblas`（若有），或
  - 在 4.4 的 `build_run.sh` 里增加 **benchmark-syev-openblas** 的构建与运行，再用同一脚本对两个可执行文件跑 perf。

这样 4.4 的叙事就是：**表 4.1 说明「主因在 Tri-eig」→ 本实验说明「原因」= DSTEQR 无 DGEMM、DSTEDC 以 DGEMM 为主；几十倍加速则进一步解释为「算得少」（分治工作量远小于 QR）+「算得快」（DGEMM 的缓存、SIMD、计算受限），二者相乘。**
