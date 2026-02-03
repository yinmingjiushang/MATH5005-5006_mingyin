# Experiment 4.4 — 为什么 STEDC 比 STEQR 快 + 各因素加速贡献

本实验在已有 4.2、4.3 数据基础上，**量化各方法/手段的加速程度**，说明 DSTEDC 为何比 DSTEQR 快。

**4.2** = LAPACK vs OpenBLAS。  
**4.3** = SVE vs 标量。  
**4.4** = 各因素加速分解（算法、BLAS、SVE、归因），**复用 4.2/4.3 数据**，无需重跑 benchmark/perf。

---

## 核心问题

1. 为什么 DSTEDC 快、DSTEQR 慢，快在哪（算法结构、perf 热点）  
2. **各因素给到的加速程度**：算法、BLAS 优化、SVE，以及 Tri-eig 对总加速的贡献

---

## src

| 文件 | 说明 |
|------|------|
| **syev_benchmark.c** | DSYEV benchmark，输出 DSYTRD、DSTEQR、DORGTR 分阶段计时 |
| **syevd_benchmark.c** | DSYEVD benchmark，输出 DSYTRD、DSTEDC、DORMTR 分阶段计时 |
| **steqr_clean.c** | Clean C：STEQR 的限制（L1–L4） |
| **stedc_clean.c** | Clean C：STEDC 的结构（A1–A4，合并步 = DGEMM） |
| **README_clean_tri_eig.md** | Clean C 说明 |

---

## Scripts

| Script | 用途 |
|--------|------|
| **accelerate_decompose.py** | **核心**：各因素加速分解（算法、BLAS、SVE、归因），基于 4.2+4.3 数据 |
| **tri_eig_compare.py** | 对比 DSTEQR vs DSTEDC Tri-eig 时间（若需单独表格） |
| **build_run.sh** | 构建 syev/syevd benchmark（若无 4.2/4.3 数据时使用） |
| **perf_syevd.sh** | perf 热点（若需补跑） |
| **analyze_tri_eig.md** | 4.4 原因分析设计文档 |

---

## Quick start

```bash
cd Code/experiment_4_4/script

# 主实验：各因素加速贡献分解（复用 4.2、4.3 实验数据）
python3 accelerate_decompose.py --root4_2 ../../experiment_4_2/output --root4_3 ../../experiment_4_3/output
```

输出包括：
1. 算法贡献：DSTEQR vs DSTEDC 加速比（~10–25×）
2. BLAS 贡献：各阶段 LAPACK→OpenBLAS 加速比（DSTEQR≈1×，DSTEDC≈2–4×）
3. SVE 贡献：scalar→SVE 各阶段加速比（DSTEQR≈1×，DSTEDC≈1.1–1.2×）
4. 归因：Tri-eig 对 syev→syevd 总加速的贡献占比
5. 综合小结表

---

## 实验流程（写进报告）

1. **运行**：`accelerate_decompose.py`，得到各因素加速表格。
2. **算法简述**：DSTEQR = QR、无 DGEMM；DSTEDC = 分治、合并=DGEMM（可引用 clean C）。
3. **数据结论**：算法贡献最大（~15×）；BLAS 对 DSTEDC 有 2–4×，对 DSTEQR 无益；SVE 贡献 modest。
4. **（可选）** Perf 热点、Tri-eig 时间 vs N 图，作为补充。
