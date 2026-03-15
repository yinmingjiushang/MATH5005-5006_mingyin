# Experiment 4.3 - OpenBLAS SIMD Baseline vs SVE

This experiment supports Chapter 4 Section 4.4, which isolates the incremental
benefit of moving from a 128-bit OpenBLAS SIMD baseline to an SVE-enabled
OpenBLAS build.

## Scope

- focus: same-LAPACK, different kernel target
- default thread count: `1`
- default sizes:
  - `DSYEV`: `512, 1024, 2048, 4096`
  - `DSYEVD`: `512, 1024, 2048, 4096`
- libraries:
  - `openblas_simd`: generic `ARMV8` baseline
  - `openblas_sve`: `NEOVERSEV1` / SVE-capable build

The defaults are kept identical across the two routines so that the thesis
tables can be compared size-by-size without additional filtering.

## Files

- `src/syev_benchmark.c`: `DSYEV` stage-timed driver
- `src/syevd_benchmark.c`: `DSYEVD` stage-timed driver
- `script/build_run.sh`: builds and runs both OpenBLAS variants
- `script/run_all.sh`: full pipeline for build, comparison, and stacked CSVs
- `script/compare_partial.py`: numerical agreement check between the two builds
- `script/stack_timing.py`: converts raw benchmark CSVs into comparison tables

## Quick Start

```bash
cd Code/chapter4/04_04_sve_vectorization/script
./run_all.sh
```

Outputs are written under `Code/chapter4/04_04_sve_vectorization/output/`.
