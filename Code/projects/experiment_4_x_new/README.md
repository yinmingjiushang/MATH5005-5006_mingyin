# Experiment 4.x (new): GEMM latency, OpenBLAS SVE vs SIMD baseline

这个实验独立测量 `dgemm`，用来验证：
- 为什么在 `syev` 里看到的 SVE 提升可能不明显
- 在纯 `GEMM` 场景下，SVE 相对 SIMD baseline 的真实时延差异

## 目录

- `src/gemm_latency_benchmark.c`: GEMM 基准程序
- `script/build_run.sh`: 编译与运行入口
- `script/compare_gemm_latency.py`: 汇总 SVE/SIMD 对比
- `script/disasm_gemm.sh`: 反汇编 GEMM 路径并分类指令集
- `output/`: 结果输出目录

## 默认配置

- 矩阵规模: `256,512,1024,1536,2048`
- 线程: `1`
- warmup: `2`
- repeats: `8`
- GEMM 形式: `C = A * B` (`NoTrans`, `ColMajor`)

## 运行

```bash
cd Code/projects/experiment_4_x_new/script
./build_run.sh all
```

只跑单边：

```bash
./build_run.sh benchmark-gemm-openblas-sve
./build_run.sh benchmark-gemm-openblas-simd
```

只做对比汇总：

```bash
./build_run.sh compare
```

做 GEMM 指令级反汇编对比（看是否是 SVE 指令）：

```bash
./disasm_gemm.sh
```

## 自定义参数

通过环境变量覆盖默认值：

```bash
GEMM_SIZES=512,1024,2048 GEMM_THREADS=1,2 GEMM_WARMUP=3 GEMM_REPEATS=10 ./build_run.sh all
```

## 输出文件

- `output/openblas_sve/gemm/gemm_latency.csv`
- `output/openblas_simd/gemm/gemm_latency.csv`
- `output/compare/gemm_latency_compare.csv`
- `output/disasm/summary.txt`
- `output/disasm/openblas_sve_dgemm_kernel.s`
- `output/disasm/openblas_simd_dgemm_kernel.s`

`gemm_latency_compare.csv` 关键列：
- `speedup_simd_over_sve = simd_avg_s / sve_avg_s`
  - 大于 1：SVE 更快
  - 小于 1：SIMD baseline 更快
- `speedup_sve_over_simd = sve_avg_s / simd_avg_s`
  - 大于 1：SIMD baseline 更快
