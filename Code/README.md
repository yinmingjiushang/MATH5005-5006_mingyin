# Code Layout

`Code/` is organized around runnable experiment code plus a small number of support areas:

- `chapter4/`: canonical implementation for the thesis Chapter 4 experiments.
- `projects/`: standalone experiment code that is not part of the `chapter4/` canonical tree.
- `third_party/`: external libraries, source drops, installers, and build outputs such as OpenBLAS, LAPACK, and ArmPL.
- `legacy/`: retained older or superseded experiments that are no longer the main entry points.

Current legacy note:

- `legacy/experiment_4_x_useless/`: retained legacy source snapshot for historical reference only. It is not the current Chapter 4 entry point and is not the replacement for `projects/experiment_4_x_new/`; keep it for source provenance while continuing to ignore generated outputs.

OpenBLAS layout under `Code/third_party/`:

- `openblas_src/`: OpenBLAS source checkout and build scripts.
- `openblas_sve/`: installed SVE-oriented OpenBLAS build.
- `openblas_simd/`: installed generic SIMD baseline OpenBLAS build.
