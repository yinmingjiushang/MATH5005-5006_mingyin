# Experiment 4.4 — 为什么 STEDC 比 STEQR 快 + 各因素加速贡献

本实验在已有 4.2、4.3 数据基础上，量化 Chapter 4 中使用的几类
受控比较，并把它们整理成可直接写进论文的归因结果。

**4.2** = LAPACK vs OpenBLAS。  
**4.3** = SVE vs SIMD baseline。  
**4.4** = 各因素加速分解（算法、BLAS、SVE、归因），**复用 4.2/4.3
数据**，无需默认重跑 benchmark/perf。

---

## 核心问题

1. 为什么 DSTEDC 快、DSTEQR 慢，快在哪（算法结构、perf 热点）
2. 各因素给到的加速程度：算法、BLAS 优化、SVE，以及 Tri-eig 对总净节省的归因

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
cd Code/chapter4/04_90_legacy_speedup_attribution/script

# 主实验：各因素加速贡献分解（复用 4.2、4.3 实验数据）
python3 accelerate_decompose.py --root4_2 ../../04_03_blas_optimization/output --root4_3 ../../04_04_sve_vectorization/output
```

输出包括：
1. 算法层面的 stage-local speedup：DSTEQR vs DSTEDC（约 10--25x）
2. BLAS 层面的 stage-local speedup：Reference BLAS 到 OpenBLAS
3. SIMD 层面的 stage-local speedup：128-bit SIMD baseline 到 SVE
4. end-to-end net-saving attribution：Tri-eig 对总净节省的占比
5. 综合小结表

---

## 实验流程（写进报告）

1. **运行**：`accelerate_decompose.py`，得到各因素加速表格。
2. **算法简述**：DSTEQR = QR、无 DGEMM；DSTEDC = 分治、合并=DGEMM（可引用 clean C）。
3. **数据结论**：算法贡献最大；BLAS 对 DSTEDC 有明显帮助，对
   DSTEQR 基本无帮助；SVE 是增量收益，不是主因。
4. **（可选）** Perf 热点、Tri-eig 时间 vs N 图，作为补充。
