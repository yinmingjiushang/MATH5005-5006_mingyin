#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$ROOT_DIR/../.." >/dev/null 2>&1 && pwd -P)"
THIRD_PARTY_DIR="$CODE_DIR/third_party"

CC="${CC:-gcc}"
CFLAGS="-O3 -std=c11 -D_POSIX_C_SOURCE=200112L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast \
  -DOPENBLAS_USE64BITINT -I$THIRD_PARTY_DIR/openblas_sve/include"
LDFLAGS="$THIRD_PARTY_DIR/openblas_sve/lib/libopenblas.a -lgfortran -lm -lpthread -ldl"
WRAP_LDFLAGS=(
  -Wl,--wrap=dorgtr_
  -Wl,--wrap=dsteqr_
  -Wl,--wrap=dstedc_
  -Wl,--wrap=dormtr_
)

mkdir -p "$ROOT_DIR/output/bin" "$ROOT_DIR/output/obj"

SRC="$ROOT_DIR/src/post_reduction_threshold.c"
OBJ="$ROOT_DIR/output/obj/post_reduction_threshold.o"
BIN="$ROOT_DIR/output/bin/post_reduction_threshold"

echo "[BUILD] $SRC"
"$CC" $CFLAGS -c "$SRC" -o "$OBJ"

echo "[LINK ] $BIN"
"$CC" "$OBJ" $LDFLAGS "${WRAP_LDFLAGS[@]}" -o "$BIN"

echo "[OK] $BIN"
