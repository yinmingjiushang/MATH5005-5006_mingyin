#!/usr/bin/env bash
# build_run.sh — Minimal script to compile and run with a local static OpenBLAS (single-threaded)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
find_code_dir() {
  local dir="$SCRIPT_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/third_party" && -d "$dir/chapter4" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}
CODE_DIR="$(find_code_dir)" || { echo "Failed to locate Code root from $SCRIPT_DIR" >&2; exit 1; }
THIRD_PARTY_DIR="$CODE_DIR/third_party"

# Local OpenBLAS installation (can be overridden externally)
OPENBLAS_PREFIX="${OPENBLAS_PREFIX:-$THIRD_PARTY_DIR/openblas_sve}"
OPENBLAS_LIBDIR="$OPENBLAS_PREFIX/lib"
OPENBLAS_INCDIR="$OPENBLAS_PREFIX/include"

# Source file (can be passed as the first argument)
SRC="${1:-$SCRIPT_DIR/../src/dsyevd.c}"
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
