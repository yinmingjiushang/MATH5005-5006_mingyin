#!/usr/bin/env bash
# Experiment 4.4: Why STEDC is faster than STEQR (OpenBLAS only).
# Builds syev and syevd with OpenBLAS for Tri-eig comparison and perf hotspot.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$SCRIPT_DIR/../../.." >/dev/null 2>&1 && pwd -P)"

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

TAG="${1:-}"

run_all() {
  local do_clean="${CLEAN_OUTPUT:-1}"
  if [[ "$do_clean" == "1" ]]; then
    rm -rf "$SCRIPT_DIR/../output/openblas"
  fi
  CLEAN_OUTPUT=0 "$0" benchmark-syev-openblas
  CLEAN_OUTPUT=0 "$0" benchmark-syevd-openblas
}

if [[ -z "$TAG" || "$TAG" == "all" ]]; then
  run_all
  exit 0
fi

# ====== 1. Base Compiler Setup ======
CC=gcc
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=199309L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_FORTRAN="-lgfortran"
LIBS_MATH="-lm"

# ====== 1.5 Wrap sets (for subroutine timing) ======
WRAP3_SYMS=( dsytrd_ dorgtr_ dsteqr_ )
WRAP3_LDFLAGS=()
for s in "${WRAP3_SYMS[@]}"; do WRAP3_LDFLAGS+=("-Wl,--wrap=${s}"); done

WRAP3D_SYMS=( dsytrd_ dstedc_ dormtr_ )
WRAP3D_LDFLAGS=()
for s in "${WRAP3D_SYMS[@]}"; do WRAP3D_LDFLAGS+=("-Wl,--wrap=${s}"); done

# ====== 2. OpenBLAS (single library for 4.4) ======
OPENBLAS_PREFIX="$CODE_DIR/openblas/openblas_install"
CFLAGS_OB="$CFLAGS_BASE -I$OPENBLAS_PREFIX/include"
LDFLAGS_OB="$OPENBLAS_PREFIX/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# ====== 3. Case Selection ======
case "$TAG" in

  benchmark-syev-openblas)
      SRC="$SCRIPT_DIR/../src/syev_benchmark.c"
      CFLAGS="$CFLAGS_OB -DLIB_TAG=\"openblas\" -DROUTINE_NAME=\"syev\""
      LDFLAGS="$LDFLAGS_OB ${WRAP3_LDFLAGS[*]}"
      OUT_LIB="openblas"
      OUT_ROUTINE="syev"
      ;;

  benchmark-syevd-openblas)
      SRC="$SCRIPT_DIR/../src/syevd_benchmark.c"
      CFLAGS="$CFLAGS_OB -DLIB_TAG=\"openblas\" -DROUTINE_NAME=\"syevd\""
      LDFLAGS="$LDFLAGS_OB ${WRAP3D_LDFLAGS[*]}"
      OUT_LIB="openblas"
      OUT_ROUTINE="syevd"
      ;;

  *)
      echo "[X] Unknown TAG: $TAG"; exit 1;;
esac

# ====== 4. Output & Build ======
OUT_DIR="$SCRIPT_DIR/../output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"
mkdir -p "$OBJ_DIR" "$BIN_DIR"

if [[ "${CLEAN_OUTPUT:-1}" == "1" && -n "${OUT_LIB:-}" && -n "${OUT_ROUTINE:-}" ]]; then
  rm -rf "$OUT_DIR/$OUT_LIB/$OUT_ROUTINE"
fi

BASENAME="$(basename "$SRC" .c)"
OBJ="$OBJ_DIR/${BASENAME}.o"
BIN="$BIN_DIR/$TAG"

echo "[BUILD] CC=$CC | SRC=$SRC"
$CC $CFLAGS -c "$SRC" -o "$OBJ"

echo "[LINK ] $OBJ -> $BIN"
$CC "$OBJ" $LDFLAGS -o "$BIN"

echo "[RUN  ] LIB=$TAG | EXE=$BIN"
cd "$SCRIPT_DIR"
exec "$BIN"
