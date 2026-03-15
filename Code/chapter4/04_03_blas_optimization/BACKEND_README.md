# Experiment 4.2 - Library-Stack Comparison

This experiment supports Chapter 4 Section 4.3, which compares a Netlib
LAPACK/reference-BLAS stack against an optimized OpenBLAS stack.

## Scope

- focus: stage-by-stage library-stack comparison
- default thread count: `1`
- default sizes: `512, 1024, 2048, 4096`
- routines: `DSYEV` and `DSYEVD`

The defaults are intentionally narrower than the chapter's top-level benchmark.
They are chosen so that both library stacks can be collected under the same
wrappers and output format without turning the reference-BLAS runs into a
multi-hour batch.

## Files

- `src/syev_benchmark.c`: `DSYEV` with wrapped `DSYTRD`, `DORGTR`, `DSTEQR`
- `src/syevd_benchmark.c`: `DSYEVD` with wrapped `DSYTRD`, `DSTEDC`, `DORMTR`
- `script/build_run.sh`: builds and runs Netlib and OpenBLAS cases
- `script/stack_timing.py`: stacks stage timings for thesis-ready CSV output
- `script/compare_partial.py`: compares partial eigenpairs across library stacks

## Quick Start

```bash
cd Code/chapter4/04_03_blas_optimization/script
./build_run.sh all
python3 stack_timing.py --routine syev --root ../output
python3 stack_timing.py --routine syevd --root ../output
```

Outputs are written under `Code/chapter4/04_03_blas_optimization/output/`.
