#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd -P)"
OUT_DIR="$SCRIPT_DIR/../output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export ARMPL_NUM_THREADS=1

mkdir -p "$OBJ_DIR" "$BIN_DIR"

TAG="${1:-all}"

CC=gcc
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=200809L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_FORTRAN="-lgfortran"
LIBS_MATH="-lm"

OPENBLAS_PREFIX="$CODE_DIR/openblas/openblas_install"
CFLAGS_OB="$CFLAGS_BASE -I$OPENBLAS_PREFIX/include"
LDFLAGS_OB="$OPENBLAS_PREFIX/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

build_one() {
  local src="$1"
  local bin_name="$2"
  local obj_name
  obj_name="$(basename "$src" .c).o"

  echo "[BUILD] $src"
  $CC $CFLAGS_OB -c "$src" -o "$OBJ_DIR/$obj_name"
  echo "[LINK ] $BIN_DIR/$bin_name"
  $CC "$OBJ_DIR/$obj_name" $LDFLAGS_OB -o "$BIN_DIR/$bin_name"
}

case "$TAG" in
  syev-hw)
    build_one "$SCRIPT_DIR/../src/syev_hw.c" "benchmark-syev-openblas-sve-hw"
    ;;
  syevd-hw)
    build_one "$SCRIPT_DIR/../src/syevd_hw.c" "benchmark-syevd-openblas-sve-hw"
    ;;
  dsteqr-hw)
    build_one "$SCRIPT_DIR/../src/dsteqr_hw.c" "benchmark-dsteqr-openblas-sve-hw"
    ;;
  dstedc-hw)
    build_one "$SCRIPT_DIR/../src/dstedc_hw.c" "benchmark-dstedc-openblas-sve-hw"
    ;;
  all)
    build_one "$SCRIPT_DIR/../src/syev_hw.c" "benchmark-syev-openblas-sve-hw"
    build_one "$SCRIPT_DIR/../src/syevd_hw.c" "benchmark-syevd-openblas-sve-hw"
    build_one "$SCRIPT_DIR/../src/dsteqr_hw.c" "benchmark-dsteqr-openblas-sve-hw"
    build_one "$SCRIPT_DIR/../src/dstedc_hw.c" "benchmark-dstedc-openblas-sve-hw"
    ;;
  *)
    echo "Unknown tag: $TAG" >&2
    exit 1
    ;;
esac

echo "[DONE ] Binaries are in $BIN_DIR"
