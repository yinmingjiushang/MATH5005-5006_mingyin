# MATH5005-5006 Project Repository

This repository contains the code, supporting material, and working notes for a
MATH5005/MATH5006 project on dense symmetric eigenvalue solvers in LAPACK. The
main practical comparison is between `DSYEV` and `DSYEVD`, and the broader goal
is to explain not only which routine is faster in practice, but why the gap
appears and how much of it is attributable to algorithmic structure, BLAS
backend quality, and SVE-aware implementations on Arm hardware.

This README is the main entry point for the repository as a whole. It focuses
on the code and support material and intentionally does not document the
`latex/` tree.

## Project Overview

The repository is organized around a dense symmetric eigenproblem study with
three linked concerns:

- algorithmic comparison
  How `DSYEV` and `DSYEVD` differ mathematically and computationally
- implementation comparison
  How the LAPACK paths, BLAS backend, and vectorization strategy influence
  observed runtime
- experimental attribution
  How much of the end-to-end difference comes from the tridiagonal stage,
  blocked BLAS-3 kernels, and hardware-level execution behaviour

At a high level, the code in this repository supports:

- end-to-end `DSYEV` versus `DSYEVD` benchmarks
- backend comparisons between Netlib LAPACK and OpenBLAS
- vectorization comparisons between OpenBLAS SIMD baseline and OpenBLAS SVE
- focused profiling for `DSTEQR` and `DSTEDC`
- hardware-counter and peak-memory measurements
- smaller standalone experiments retained outside the main Chapter 4 pipeline

## What This Repository Contains

```text
.
├── Code/        runnable experiment code and local third-party libraries
├── Resources/   papers, extracted reference material, and code notes
├── Thesis/      earlier notes, small examples, and intermediate outputs
├── README.md
└── update_latex.sh
```

The main directories are:

- `Code/`
  The primary code area. This is where the reproducible experiment scripts,
  C sources, output trees, and local BLAS/LAPACK dependencies live.
- `Resources/`
  Supporting papers and routine-oriented reference notes used during the study.
- `Thesis/`
  Older examples and working material outside the current `latex/` thesis tree.
  These files are still useful for provenance and small demonstrators, but they
  are not the main experiment entry point.

## Recommended Reading Order

If you are new to the repository, the most efficient path is:

1. Read [Code/README.md](/home/ec2-user/MATH5005-5006_mingyin/Code/README.md)
   for the code-level layout.
2. Read [Code/chapter4/README.md](/home/ec2-user/MATH5005-5006_mingyin/Code/chapter4/README.md)
   for the canonical experiment map.
3. Enter the specific Chapter 4 section directory you want to run or inspect.

The current canonical workflow is under `Code/chapter4/`. If your goal is to
rerun the measurements that support the main study, start there rather than in
`Code/projects/` or `Code/legacy/`.

## Canonical Experiment Layout

`Code/chapter4/` is the main experiment tree used by the current project. Each
subdirectory corresponds to a thesis section or a closely related retained
analysis.

| Section | Path | Main purpose |
|---|---|---|
| 4.2 | `Code/chapter4/04_02_benchmark/` | End-to-end `DSYEV` vs `DSYEVD` benchmark |
| 4.3 | `Code/chapter4/04_03_blas_optimization/` | Netlib LAPACK vs OpenBLAS comparison |
| 4.4 | `Code/chapter4/04_04_sve_vectorization/` | OpenBLAS SIMD baseline vs OpenBLAS SVE |
| 4.5.1 | `Code/chapter4/04_05_01_dsteqr_profile/` | QR-path profiling |
| 4.5.2 | `Code/chapter4/04_05_02_dstedc_profile/` | Divide-and-conquer profiling |
| 4.5.3 | `Code/chapter4/04_05_03_hardware_efficiency/` | `perf stat` and memory evidence |
| 4.6 | `Code/chapter4/04_06_summary/` | Summary-only support files |
| retained legacy analysis | `Code/chapter4/04_90_legacy_speedup_attribution/` | Earlier attribution pass kept for reference |

Two additional directories in `Code/chapter4/` are worth knowing:

- `Code/chapter4/results/`
  Small version-controlled result snapshots that summarize the main outcomes.
- `Code/chapter4/output/`
  Older generated output retained at the chapter level.

In general, newer section-local outputs live under each experiment's own
`output/` directory.

## Other Code Areas

Not all code in this repository belongs to the canonical Chapter 4 workflow.

### `Code/projects/`

`Code/projects/` contains standalone or exploratory projects that remain useful
for reference:

- `DSYEV_DSYEVD/`
  Earlier direct-comparison code and helper scripts
- `DSTEDC/`
  Focused divide-and-conquer tridiagonal solver runs
- `DSYEVD_openmp/`
  OpenMP-oriented experiments
- `GEEV_DSYEV_DSYEVD/`
  Broader eigenproblem comparison code
- `experiment_4_x_new/`
  GEMM latency benchmark used to interpret the SVE observations

These projects are still valuable, but they are not the first place to look if
you want the final Chapter 4 experiment pipeline.

### `Code/third_party/`

`Code/third_party/` stores the local dependency layout assumed by many build
scripts:

- `LAPACK/`
  Netlib LAPACK build and install tree
- `openblas_sve/`
  OpenBLAS build used as the main optimized backend on Arm/SVE
- `openblas_simd/`
  Baseline OpenBLAS build used in the vectorization comparison
- `openblas_src/`
  OpenBLAS source checkout plus build scripts such as
  `build_arm_threads_sve.sh`
- `armpl/`
  Arm Performance Libraries used by some comparison scripts

Many experiment scripts link directly against these local static archives, so
the directory structure matters. If you relocate `Code/third_party/`, expect to
update hard-coded paths in the shell scripts.

### `Code/legacy/`

`Code/legacy/experiment_4_x_useless/` is an archived source snapshot kept for
historical reference only. It is not part of the current canonical workflow.

## Supporting Material

Outside `Code/`, the repository also preserves supporting context:

- `Resources/References/`
  PDF papers and books relevant to symmetric eigensolvers, divide-and-conquer,
  and tridiagonal reduction
- `Resources/code/`
  Routine-level notes extracted for `dsyev` and `dsyevd`
- `Thesis/chapter1/`
  Earlier timing outputs and a small Python script used during thesis drafting
- `Thesis/chapter2/section2_2/`
  `DSTEQR` example material
- `Thesis/chapter2/section2_3/`
  `DSTEDC` example material

This material is helpful for understanding the background of the experiments,
but it is not required to run the current Chapter 4 code.

## Environment And Assumptions

The repository is built around a Linux-oriented workflow. Most runnable
experiments assume:

- `gcc`
- `gfortran`
- Python 3
- local BLAS/LAPACK libraries under `Code/third_party/`
- `perf` for hardware-counter collection in Section 4.5.3

Most C builds use aggressive optimization flags and static library linkage.
Several profiling scripts also assume that single-thread execution is enforced
to reduce measurement variance.

In practice, many scripts either:

- export `OMP_NUM_THREADS=1` and `OPENBLAS_NUM_THREADS=1`, or
- explicitly unset inherited thread settings and let the benchmark program
  control threading itself

That means results are not meant to be interpreted as generic out-of-the-box
multithreaded LAPACK timings without understanding the local thread policy of
the specific experiment.

## Running The Main Experiments

There is no single top-level build command for the repository. Each experiment
owns its own shell entry point such as `run_all.sh`, `build_run.sh`, or
`run.sh`.

The most important entry points are:

```bash
# Section 4.2: overall DSYEV vs DSYEVD benchmark
cd Code/chapter4/04_02_benchmark
./run_all.sh

# Section 4.3: Netlib LAPACK vs OpenBLAS comparison
cd Code/chapter4/04_03_blas_optimization
./run_all.sh

# Section 4.4: OpenBLAS SIMD baseline vs OpenBLAS SVE
cd Code/chapter4/04_04_sve_vectorization
./run_all.sh

# Section 4.5.1: DSTEQR profile
cd Code/chapter4/04_05_01_dsteqr_profile
./run.sh

# Section 4.5.2: DSTEDC profile
cd Code/chapter4/04_05_02_dstedc_profile
./run.sh

# Section 4.5.3: hardware counters and memory
cd Code/chapter4/04_05_03_hardware_efficiency
./build_all.sh
./run_perf.sh
./run_mem.sh
```

If you only want the main end-to-end comparison, Section 4.2 is the right place
to start. If you want the explanatory follow-up measurements, continue with
Sections 4.3, 4.4, and 4.5.

## Outputs And Result Locations

The repository uses two broad kinds of result storage:

- experiment-local `output/`
  Full generated binaries, raw logs, CSV files, intermediate traces, and local
  artifacts
- `Code/chapter4/results/`
  Small version-controlled snapshots of selected Chapter 4 outcomes

The first is the working output area for reruns. The second is the compact
checked-in summary area intended to preserve representative results without
committing every generated artifact.

## Practical Notes

- Directory names are case-sensitive. The main code root is `Code/`, not
  `code/`.
- The current thesis-facing workflow is `Code/chapter4/`, not `Code/projects/`.
- Several shell scripts assume they are run from their own directory or use
  paths relative to their script location.
- Some scripts use local library paths directly instead of relying on system
  package managers.
- If you are reproducing measurements on a different machine, inspect the
  relevant `build_run.sh` script before assuming the environment is portable.

## If You Only Need One Mental Model

Treat the repository as having three layers:

- `Code/chapter4/`
  The final experiment pipeline
- `Code/projects/` and `Code/legacy/`
  Earlier or sidecar experiments
- `Resources/` and `Thesis/`
  Supporting context and historical material

If you follow that model, the repository is much easier to navigate.
