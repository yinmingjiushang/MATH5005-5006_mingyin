#!/usr/bin/env bash
set -euo pipefail

# Resolve paths relative to this script (works from any CWD)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$SCRIPT_DIR/../../.." >/dev/null 2>&1 && pwd -P)"
THIRD_PARTY_DIR="$CODE_DIR/third_party"

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export ARMPL_NUM_THREADS=1


TAG="${1:-}"

run_all() {
  local do_clean="${CLEAN_OUTPUT:-1}"
  if [[ "$do_clean" == "1" ]]; then
    rm -rf "$SCRIPT_DIR/../output/openblas" "$SCRIPT_DIR/../output/lapack"
  fi
  CLEAN_OUTPUT=0 "$0" benchmark-syev-openblas
  CLEAN_OUTPUT=0 "$0" benchmark-syevd-openblas
  CLEAN_OUTPUT=0 "$0" benchmark-syev-lapack
  CLEAN_OUTPUT=0 "$0" benchmark-syevd-lapack
}

if [[ -z "$TAG" || "$TAG" == "all" ]]; then
  run_all
  exit 0
fi

# ====== 1. Base Compiler Setup ======
CC=gcc
#CFLAGS_BASE="-O3 -std=c11 -mcpu=native -mtune=native -D_POSIX_C_SOURCE=199309L"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=200112L \
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

# ====== 2. Library Presets ======
# Netlib (dynamic)
# ===== Netlib (static) =====
LAPACK_PREFIX="$THIRD_PARTY_DIR/LAPACK/install"
CFLAGS_NETLIB="$CFLAGS_BASE -I$LAPACK_PREFIX/include"
LDFLAGS_NETLIB="$LAPACK_PREFIX/lib64/liblapack.a $LAPACK_PREFIX/lib64/libblas.a $LIBS_FORTRAN $LIBS_MATH"

# ===== OpenBLAS (static) =====
OPENBLAS_PREFIX="$THIRD_PARTY_DIR/openblas_sve"
CFLAGS_OB="$CFLAGS_BASE -I$OPENBLAS_PREFIX/include"
LDFLAGS_OB="$OPENBLAS_PREFIX/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# ArmPL (STATIC THREAD=1)
ARMPL_PREFIX="$THIRD_PARTY_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl.a -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# ArmPL (STATIC THREAD=2)
#ARMPL_PREFIX="$THIRD_PARTY_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
#CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
#LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl_mp.a -fopenmp -lgomp -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# ArmPL dynamic (add a new preset)
#export LD_LIBRARY_PATH="$THIRD_PARTY_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc/lib:$LD_LIBRARY_PATH"
#ARMPL_PREFIX="$THIRD_PARTY_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
#CFLAGS_AP_DYN="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
#LDFLAGS_AP_DYN="-L$ARMPL_PREFIX/lib -larmpl -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"



# ====== 3. Case Selection ======
case "$TAG" in

  benchmark-syev-openblas|benchmark-syev-syevd-openblas)
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

  benchmark-syev-lapack)
      SRC="$SCRIPT_DIR/../src/syev_benchmark.c"
      CFLAGS="$CFLAGS_NETLIB -DLIB_TAG=\"lapack\" -DROUTINE_NAME=\"syev\""
      LDFLAGS="$LDFLAGS_NETLIB ${WRAP3_LDFLAGS[*]}"
      OUT_LIB="lapack"
      OUT_ROUTINE="syev"
      ;;

  benchmark-syevd-lapack)
      SRC="$SCRIPT_DIR/../src/syevd_benchmark.c"
      CFLAGS="$CFLAGS_NETLIB -DLIB_TAG=\"lapack\" -DROUTINE_NAME=\"syevd\""
      LDFLAGS="$LDFLAGS_NETLIB ${WRAP3D_LDFLAGS[*]}"
      OUT_LIB="lapack"
      OUT_ROUTINE="syevd"
      ;;

#  dsyevd-armpl-dyn)
#    SRC="../src/dsyevd.c"
#    CFLAGS="$CFLAGS_AP_DYN"
#    LDFLAGS="$LDFLAGS_AP_DYN"
#    ;;



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


echo "[BUILD] CC=$CC | SRC=$SRC | CFLAGS=$CFLAGS"
$CC $CFLAGS -c "$SRC" -o "$OBJ"

echo "[LINK ] $OBJ -> $BIN"
$CC "$OBJ" $LDFLAGS -o "$BIN"

echo "[RUN  ] LIB=$TAG | EXE=$BIN"
echo "[INFO ] OMP_NUM_THREADS=$OMP_NUM_THREADS OPENBLAS_NUM_THREADS=$OPENBLAS_NUM_THREADS ARMPL_NUM_THREADS=$ARMPL_NUM_THREADS"
cd "$SCRIPT_DIR"
exec "$BIN"
