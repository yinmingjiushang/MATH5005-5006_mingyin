# Experiment 4.6.3 - Hardware-Efficiency Evidence

This experiment collects direct hardware-oriented evidence for the claim that
`DSTEQR` is relatively memory-bound while `DSTEDC` is more hardware-friendly on
modern ARM systems.

The experiment is intentionally narrower than the earlier timing chapters:

- fixed backend: OpenBLAS SVE
- fixed thread count: `1`
- fixed matrix family: SPD KMS matrices with `rho = 0.95`
- fixed sizes: `512, 1024, 2048, 4096`

## Structure

`src/`

- `syev_hw.c`: end-to-end `DSYEV`
- `syevd_hw.c`: end-to-end `DSYEVD`
- `dsteqr_hw.c`: isolated tridiagonal eigensolver path for `DSTEQR`
- `dstedc_hw.c`: isolated tridiagonal eigensolver path for `DSTEDC`
- `hw_common.h`: shared helpers

`script/`

- `build_run.sh`: build all binaries into `output/bin`
- `run_perf_stat.sh`: collect `perf stat` counters for all sizes/cases
- `run_perf_stat.sh deep-tri`: collect a deeper counter set for `DSTEQR` and `DSTEDC`
- `run_mem.sh`: collect peak RSS with `/usr/bin/time -v`
- `summarize_hw.py`: convert raw logs into CSV summaries

## Design

Two measurement layers are kept separate:

1. End-to-end solver runs: `DSYEV` vs `DSYEVD`
2. Isolated tri-eig runs: `DSTEQR` vs `DSTEDC`

For the isolated tri-eig binaries, the dense KMS matrix is first reduced once to
tridiagonal form using `DSYTRD`. The target stage is then repeated on copies of
that tridiagonal input. This keeps the code close to the real LAPACK path while
amortizing setup overhead.

## Quick Start

```bash
cd Code/experiment_4_6_3/script
./build_run.sh all
./run_perf_stat.sh all
./run_mem.sh end2end

# quick sanity pass on a subset
SIZE_LIST="512 1024" ./run_perf_stat.sh tri

# deeper tri-eig hardware counters
./run_perf_stat.sh deep-tri
```

Outputs are written under:

- `Code/experiment_4_6_3/output/bin`
- `Code/experiment_4_6_3/output/perf`
- `Code/experiment_4_6_3/output/perf_deep`
- `Code/experiment_4_6_3/output/mem`

## Expected use in Section 4.6.3

Recommended tables/figures:

- end-to-end counters: `DSYEV` vs `DSYEVD`
- isolated tri-eig counters: `DSTEQR` vs `DSTEDC`
- peak RSS comparison: `DSYEV` vs `DSYEVD`
- derived metrics: IPC, cache-refill-per-instruction, cache-miss-rate when available
