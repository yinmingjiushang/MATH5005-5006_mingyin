# Chapter 4 Code Map

`Code/chapter4/` is the canonical layout for the Chapter 4 experiments.
Each subdirectory is named after the thesis section it supports and now holds
the runnable implementation for that section.

The section-oriented `Code/chapter4/` layout is the canonical structure.
Older top-level `Code/experiment_4_*` shortcuts have been removed.

## Section Map

| Thesis section | Canonical path | Primary backend |
|---|---|---|
| 4.2 Overall benchmark | `Code/chapter4/04_02_benchmark` | integrated locally |
| 4.3 BLAS optimization | `Code/chapter4/04_03_blas_optimization` | integrated locally |
| 4.4 SVE vectorization | `Code/chapter4/04_04_sve_vectorization` | integrated locally |
| 4.5.1 DSTEQR profile | `Code/chapter4/04_05_01_dsteqr_profile` | reuses `04_02_benchmark/dsyev_backend` |
| 4.5.2 DSTEDC profile | `Code/chapter4/04_05_02_dstedc_profile` | reuses `04_02_benchmark/dsyevd_backend` |
| 4.5.3 Hardware efficiency | `Code/chapter4/04_05_03_hardware_efficiency` | integrated locally |
| 4.6 Final synthesis and summary | `Code/chapter4/04_06_summary` | documentation only |
| legacy attribution analysis | `Code/chapter4/04_90_legacy_speedup_attribution` | integrated locally |

## Notes

- Third-party dependencies now live under `Code/third_party/`.
- Use the explicit `Code/chapter4/<section>/...` paths directly; the old top-level Chapter 4 shortcut names are no longer kept.
- Output files for Sections 4.3, 4.4, and 4.5.3 now live directly under the
  corresponding `Code/chapter4/<section>/output/` directories.
- `Code/chapter4/04_90_legacy_speedup_attribution` is kept as a retained
  intermediate analysis from an earlier Chapter 4 outline. It is no longer a
  current thesis section, but its scripts and compact result snapshot remain
  useful for reference.
- Section 4.1 is setup/documentation only, so it does not have its own runnable
  directory here.
