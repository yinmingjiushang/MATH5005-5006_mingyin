# Chapter 4 Code Map

`Code/chapter4/` is the canonical layout for the Chapter 4 experiments.
Each subdirectory is named after the thesis section it supports and now holds
the runnable implementation for that section.

The older `Code/experiment_4_*` paths are kept as compatibility symlinks to the
new section-oriented directories. They should no longer be treated as the
canonical structure.

## Section Map

| Thesis section | Canonical path | Primary backend |
|---|---|---|
| 4.2 Overall benchmark | `Code/chapter4/04_02_benchmark` | integrated locally |
| 4.3 BLAS optimization | `Code/chapter4/04_03_blas_optimization` | integrated locally |
| 4.4 SVE vectorization | `Code/chapter4/04_04_sve_vectorization` | integrated locally |
| 4.5 Speedup attribution | `Code/chapter4/04_05_speedup_attribution` | integrated locally |
| 4.6.1 DSTEQR profile | `Code/chapter4/04_06_01_dsteqr_profile` | reuses `04_02_benchmark/dsyev_backend` |
| 4.6.2 DSTEDC profile | `Code/chapter4/04_06_02_dstedc_profile` | reuses `04_02_benchmark/dsyevd_backend` |
| 4.6.3 Hardware efficiency | `Code/chapter4/04_06_03_hardware_efficiency` | integrated locally |
| 4.6.4 Synthesis | `Code/chapter4/04_06_04_synthesis` | documentation only |

## Notes

- The old `Code/experiment_4_*` names now resolve to the corresponding
  `Code/chapter4/*` directories.
- The old `Code/DSYEV` and `Code/DSYEVD` names are compatibility symlinks to
  `Code/chapter4/04_02_benchmark/dsyev_backend` and
  `Code/chapter4/04_02_benchmark/dsyevd_backend`.
- Output files for Sections 4.3, 4.4, 4.5, and 4.6.3 now live directly under
  the corresponding `Code/chapter4/<section>/output/` directories.
- Section 4.1 is setup/documentation only, so it does not have its own runnable
  directory here.
