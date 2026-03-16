# Clean C: STEQR vs STEDC（实验 4.4 教学代码）

两个较为 clean 的 C 实现，用于说明：
1. **steqr_clean.c** — STEQR 的限制与制约（为什么 QR 慢）。
2. **stedc_clean.c** — STEDC 如何贴近现代计算机架构从而获得加速（为什么分治快）。

---

## 文件说明

| 文件 | 说明 |
|------|------|
| **steqr_clean.c** | 对称三对角 QR 迭代（DSTEQR 风格）。注释标出 L1–L4：顺序依赖、无 DGEMM、迭代次数可很大、访存分散。 |
| **stedc_clean.c** | 对称三对角分治（DSTEDC 风格）。注释标出 A1–A4：合并步 = DGEMM、缓存友好、SIMD、可并行。 |

---

## 1. STEQR 的限制与制约（steqr_clean.c）

- **L1（顺序依赖）**：每轮迭代是「bulge chase」——从顶到底依次做 Givens，**必须顺序执行**，无法并行。
- **L2（无 DGEMM）**：每步只更新两列 Z（O(n)），**没有成规模的矩阵乘**，无法调用 DGEMM。
- **L3（迭代次数）**：与特征值分布有关；聚类严重时迭代次数可达 O(n) 量级，总工作量 O(n²) 或更多。
- **L4（访存）**：每步只动两列，**无分块、无高算术强度**，难以利用缓存和 SIMD。

代码中在 `qr_one_sweep` 和主循环旁用 `L1`、`L2` 等标出对应位置。

---

## 2. STEDC 如何贴近现代架构（stedc_clean.c）

- **A1（合并 = DGEMM）**：合并步形成新特征向量为 **Z = [Z1 0; 0 Z2] * X**，即**两次稠密矩阵乘**（Z1*X1、Z2*X2）。LAPACK 中对应 DLAED3 → DGEMM。代码中 `merge_rank1` 的矩阵乘部分用 `dgemm_merge`（或可选 `cblas_dgemm`）实现，并注释「此即 DGEMM 结构」。
- **A2（缓存）**：DGEMM 可分块（L1/L2/L3），算术强度高 O(n³)/O(n²)，访存被摊薄。
- **A3（SIMD）**：DGEMM 内核可用向量指令，每周期浮点吞吐高。
- **A4（并行）**：两个子问题独立；合并步是一次大 DGEMM，均可并行。

---

## 编译与运行

### 仅 STEQR（可单独编译、运行）

```bash
cd Code/chapter4/04_90_legacy_speedup_attribution/src
gcc -DSTEQR_CLEAN_MAIN -o steqr_clean_main steqr_clean.c -lm
./steqr_clean_main
```

### STEQR + STEDC（STEDC 依赖 STEQR 做小规模基例）

```bash
gcc -DSTEDC_CLEAN_MAIN -o stedc_clean_main steqr_clean.c stedc_clean.c -lm
./stedc_clean_main
```

**说明**：`stedc_clean.c` 的递归/合并逻辑在小规模（如 n=2）下可运行；n 较大时若遇内存错误，可先只编译 `steqr_clean_main` 作 STEQR 演示，STEDC 以阅读合并步中的 DGEMM 结构为主。

### 可选：STEDC 合并步用 OpenBLAS DGEMM

```bash
gcc -DSTEDC_CLEAN_MAIN -DSTEDC_USE_CBLAS -o stedc_clean_main steqr_clean.c stedc_clean.c -lm -lopenblas
./stedc_clean_main
```

---

## 在论文/报告中的用法

- **说明 STEQR 限制**：引用 `steqr_clean.c` 中的 L1–L4 注释及对应代码（bulge chase、每步只更新两列 Z、无 DGEMM）。
- **说明 STEDC 加速来源**：引用 `stedc_clean.c` 中的 A1–A4 及 `merge_rank1` 里的 DGEMM 结构（两次矩阵乘），说明「合并步即 DGEMM，故可充分利用缓存、SIMD 与并行」。
