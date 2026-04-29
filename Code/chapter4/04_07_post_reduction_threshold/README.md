# Post-Reduction Speedup Threshold Probe

This directory contains a narrow benchmark for the slide-12
`Post-reduction speedup` column.

It measures only the post-reduction branch:

- `DSYEV`: `DORGTR + DSTEQR`
- `DSYEVD`: `DSTEDC + DORMTR`
- speedup: `(DORGTR + DSTEQR) / (DSTEDC + DORMTR)`

The driver uses the same KMS matrix setup as the existing Chapter 4 benchmark:
`A_ij = rho^|i-j|`, with `rho = 0.95`, `JOBZ='V'`, `UPLO='U'`.

Each requested matrix size is measured once. This is intended for quickly
observing whether the post-reduction speedup is approaching a plateau, not for
publication-quality timing statistics.

## Build

```bash
./script/build.sh
```

## Run

```bash
./script/run_threshold.sh
```

The default size set is:

```text
512 1024 2048 4096 6144 8192
```

To add larger sizes without changing the code:

```bash
./script/run_threshold.sh 512 1024 2048 4096 6144 8192 10240 12288 16384
```

The binary also accepts sizes directly:

```bash
./output/bin/post_reduction_threshold 512 1024 2048 4096 6144 8192
```

The CSV is written to:

```text
output/post_reduction_threshold.csv
```

The default thread count is 1. Override it with:

```bash
POST_REDUCTION_THREADS=4 ./script/run_threshold.sh 4096 8192
```
