#!/usr/bin/env bash
# build_run.sh — Minimal script to compile and run with a local static OpenBLAS (single-threaded)

set -euo pipefail

# Local OpenBLAS installation (can be overridden externally)
OPENBLAS_PREFIX="${OPENBLAS_PREFIX:-../../openblas/openblas_install}"
OPENBLAS_LIBDIR="$OPENBLAS_PREFIX/lib"
OPENBLAS_INCDIR="$OPENBLAS_PREFIX/include"

# Source file (can be passed as the first argument)
SRC="${1:-../src/dsyevd.c}"
BIN="${SRC%.*}"

# Enforce single-thread execution (no OpenMP)
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export ARMPL_NUM_THREADS=1

# Basic sanity checks
[[ -f "$OPENBLAS_LIBDIR/libopenblas.a" ]] || { echo "Not found: $OPENBLAS_LIBDIR/libopenblas.a"; exit 2; }
[[ -f "$SRC" ]] || { echo "Source file not found: $SRC"; exit 3; }

# Compile (statically link OpenBLAS, dynamically link everything else)
gcc -O3 -mcpu=native -I"$OPENBLAS_INCDIR" "$SRC" \
  "$OPENBLAS_LIBDIR/libopenblas.a" -lm -ldl -lpthread -lgfortran \
  -o "$BIN"

echo "[OK] Build completed: ./$BIN"
echo "[RUN] Launching (single-thread)..."
./"$BIN"
