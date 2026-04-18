# Chapter 4 Result Snapshots

This directory contains small, version-controlled result snapshots for Chapter 4.
It is intended to make the main experiment outcomes visible without committing
the full generated `output/` trees, binaries, or intermediate files.

Included files:

- `04_02_benchmark/`
  - Median benchmark CSVs for `DSYEV` and `DSYEVD` on the OpenBLAS SVE build.
  - These files include the reported median together with `mean/std/min/max`,
    repeat count, and warm-up count.
- `04_03_blas_optimization/`
  - Stacked timing tables comparing the Netlib stack with OpenBLAS.
- `04_04_sve_vectorization/`
  - Stacked timing tables comparing the 128-bit OpenBLAS SIMD baseline with
    the OpenBLAS SVE build.
- `04_06_summary/`
  - Compact tridiagonal eigensolver speedup snapshot used by the final
    synthesis section.
- `04_90_legacy_speedup_attribution/`
  - Earlier attribution snapshot retained for traceability.

These snapshots are generated from the current Chapter 4 experiment scripts
under `Code/chapter4/`. The full reproducible pipelines remain in the chapter
subdirectories themselves.
