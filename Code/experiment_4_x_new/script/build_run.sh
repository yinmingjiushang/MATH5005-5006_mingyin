#!/usr/bin/env bash
# Experiment 4.x (new): GEMM latency comparison (OpenBLAS SVE vs OpenBLAS scalar)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd -P)"

TAG="${1:-all}"

# Defaults (can be overridden by env before calling this script)
export GEMM_SIZES="${GEMM_SIZES:-256,512,1024,1536,2048}"
export GEMM_THREADS="${GEMM_THREADS:-1}"
export GEMM_WARMUP="${GEMM_WARMUP:-2}"
export GEMM_REPEATS="${GEMM_REPEATS:-8}"

CC="${CC:-gcc}"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=200112L -mcpu=native -mtune=native -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_BASE="-lgfortran -lm -lpthread -ldl"

OPENBLAS_SVE_PREFIX="$CODE_DIR/openblas/openblas_install"
CFLAGS_OB_SVE="$CFLAGS_BASE -I$OPENBLAS_SVE_PREFIX/include"
LDFLAGS_OB_SVE="$OPENBLAS_SVE_PREFIX/lib/libopenblas.a $LIBS_BASE"

OPENBLAS_SCALAR_PREFIX="$CODE_DIR/openblas_scalar"
OPENBLAS_SCALAR_LIB="$OPENBLAS_SCALAR_PREFIX/lib"
OPENBLAS_SCALAR_A=""
if [[ -d "$OPENBLAS_SCALAR_LIB" ]]; then
  armv8_a="$(find "$OPENBLAS_SCALAR_LIB" -maxdepth 1 -name 'libopenblas_armv8p*.a' -print -quit)"
  if [[ -n "$armv8_a" && -f "$armv8_a" ]]; then
    OPENBLAS_SCALAR_A="$armv8_a"
  else
    OPENBLAS_SCALAR_A="$(find "$OPENBLAS_SCALAR_LIB" -maxdepth 1 -name 'libopenblas*.a' -print -quit)"
  fi
fi
if [[ -z "$OPENBLAS_SCALAR_A" ]]; then
  OPENBLAS_SCALAR_A="$OPENBLAS_SCALAR_LIB/libopenblas.a"
fi
CFLAGS_OB_SCALAR="$CFLAGS_BASE -I$OPENBLAS_SCALAR_PREFIX/include"
LDFLAGS_OB_SCALAR="$OPENBLAS_SCALAR_A $LIBS_BASE"

run_all() {
  local do_clean="${CLEAN_OUTPUT:-1}"
  if [[ "$do_clean" == "1" ]]; then
    rm -rf "$SCRIPT_DIR/../output/openblas_sve" "$SCRIPT_DIR/../output/openblas_scalar" "$SCRIPT_DIR/../output/compare"
  fi
  CLEAN_OUTPUT=0 "$0" benchmark-gemm-openblas-sve
  CLEAN_OUTPUT=0 "$0" benchmark-gemm-openblas-scalar
  "$SCRIPT_DIR/compare_gemm_latency.py"
}

if [[ "$TAG" == "all" ]]; then
  run_all
  exit 0
fi

case "$TAG" in
  benchmark-gemm-openblas-sve)
    SRC="$SCRIPT_DIR/../src/gemm_latency_benchmark.c"
    CFLAGS="$CFLAGS_OB_SVE -DLIB_TAG=\"openblas_sve\""
    LDFLAGS="$LDFLAGS_OB_SVE"
    ;;
  benchmark-gemm-openblas-scalar)
    SRC="$SCRIPT_DIR/../src/gemm_latency_benchmark.c"
    CFLAGS="$CFLAGS_OB_SCALAR -DLIB_TAG=\"openblas_scalar\""
    LDFLAGS="$LDFLAGS_OB_SCALAR"
    ;;
  compare)
    exec "$SCRIPT_DIR/compare_gemm_latency.py"
    ;;
  *)
    echo "[X] Unknown TAG: $TAG"
    echo "Available: all | benchmark-gemm-openblas-sve | benchmark-gemm-openblas-scalar | compare"
    exit 1
    ;;
esac

OUT_DIR="$SCRIPT_DIR/../output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"
mkdir -p "$OBJ_DIR" "$BIN_DIR"

BASENAME="$(basename "$SRC" .c)"
OBJ="$OBJ_DIR/${BASENAME}_${TAG}.o"
BIN="$BIN_DIR/$TAG"

echo "[CFG  ] GEMM_SIZES=$GEMM_SIZES GEMM_THREADS=$GEMM_THREADS GEMM_WARMUP=$GEMM_WARMUP GEMM_REPEATS=$GEMM_REPEATS"
echo "[BUILD] CC=$CC | SRC=$SRC"
$CC $CFLAGS -c "$SRC" -o "$OBJ"

echo "[LINK ] $OBJ -> $BIN"
$CC "$OBJ" $LDFLAGS -o "$BIN"

echo "[RUN  ] EXE=$BIN"
cd "$SCRIPT_DIR"
exec "$BIN"
