# Code

`Code/` contains the runnable experiment code for the LAPACK symmetric
eigenproblem study in this repository. The main comparison is between
`DSYEV` and `DSYEVD`, with additional experiments that isolate BLAS effects,
SVE vectorization, and the tridiagonal solvers `DSTEQR` and `DSTEDC`.

## What Is In Here

- `chapter4/`
  Canonical experiment tree used for the Chapter 4 measurements. If you want
  the current benchmark and profiling pipelines, start here.
- `projects/`
  Standalone or exploratory projects that are still useful, but are not the
  canonical Chapter 4 entry points.
- `third_party/`
  Local library dependencies and source drops, including Netlib LAPACK,
  OpenBLAS builds, OpenBLAS source, and Arm Performance Libraries.
- `legacy/`
  Retained older experiment code kept for provenance and reference.

## Recommended Starting Points

The current experiment workflow is organized by thesis section under
`Code/chapter4/`.

| Section | Path | Purpose |
|---|---|---|
| 4.2 | `Code/chapter4/04_02_benchmark/` | End-to-end `DSYEV` vs `DSYEVD` benchmark |
| 4.3 | `Code/chapter4/04_03_blas_optimization/` | Netlib LAPACK vs OpenBLAS comparison |
| 4.4 | `Code/chapter4/04_04_sve_vectorization/` | OpenBLAS SIMD baseline vs OpenBLAS SVE |
| 4.5.1 | `Code/chapter4/04_05_01_dsteqr_profile/` | Profile the QR tridiagonal path |
| 4.5.2 | `Code/chapter4/04_05_02_dstedc_profile/` | Profile the divide-and-conquer path |
| 4.5.3 | `Code/chapter4/04_05_03_hardware_efficiency/` | `perf stat` and memory evidence |
| 4.6 | `Code/chapter4/04_06_summary/` | Summary-only support files |

Version-controlled result snapshots live in `Code/chapter4/results/`. Full
generated outputs stay inside each experiment's local `output/` directory.

## Quick Start

There is no single top-level build system for `Code/`. Each experiment owns its
own `run_all.sh`, `build_run.sh`, or `run.sh`.

Typical entry points:

```bash
# Section 4.2 benchmark
cd Code/chapter4/04_02_benchmark
./run_all.sh

# Section 4.3 BLAS comparison
cd Code/chapter4/04_03_blas_optimization
./run_all.sh

# Section 4.4 SVE vs SIMD comparison
cd Code/chapter4/04_04_sve_vectorization
./run_all.sh

# Section 4.5.3 hardware counters and memory
cd Code/chapter4/04_05_03_hardware_efficiency
./build_all.sh
./run_perf.sh
./run_mem.sh
```

## Toolchain And Runtime Assumptions

Most scripts assume:

- `gcc` and `gfortran` are available.
- Static BLAS/LAPACK libraries exist under `Code/third_party/`.
- Python 3 is available for CSV aggregation and comparison scripts.
- Linux `perf` is available for the hardware-efficiency runs.

Many profiling scripts explicitly pin to single-thread execution with
`OMP_NUM_THREADS=1` and `OPENBLAS_NUM_THREADS=1` to reduce variance. Benchmark
drivers may manage thread counts internally instead of inheriting shell
settings.

## Third-Party Dependencies

`Code/third_party/` contains the local dependency layout expected by the
experiment scripts:

- `LAPACK/`
  Netlib LAPACK build and install tree.
- `openblas_sve/`
  OpenBLAS build used as the main optimized backend on Arm/SVE.
- `openblas_simd/`
  Baseline OpenBLAS build used for vectorization comparison.
- `openblas_src/`
  OpenBLAS source checkout plus build scripts such as
  `build_arm_threads_sve.sh`.
- `armpl/`
  Arm Performance Libraries used by some standalone comparisons.

Several scripts link directly against these static archives, so moving the
directories will break the default paths unless the scripts are updated.

## Standalone Projects

`Code/projects/` contains smaller or older self-contained experiments, for
example:

- `DSYEV_DSYEVD/`
  Earlier direct comparison code and helper scripts.
- `DSTEDC/`
  Focused runs around the divide-and-conquer tridiagonal solver.
- `DSYEVD_openmp/`
  OpenMP-oriented `DSYEVD` experiments.
- `GEEV_DSYEV_DSYEVD/`
  Broader eigenproblem comparison code.
- `experiment_4_x_new/`
  GEMM latency benchmark used to interpret the SVE results.

These are useful reference points, but for the current thesis experiment
pipeline, prefer `Code/chapter4/`.

## Legacy Code

`Code/legacy/experiment_4_x_useless/` is kept only as an archived source
snapshot. It is not part of the current Chapter 4 workflow.
