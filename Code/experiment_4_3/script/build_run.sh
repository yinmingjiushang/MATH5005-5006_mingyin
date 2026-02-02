#!/usr/bin/env bash
# Experiment 4.3: OpenBLAS SVE vs scalar performance comparison only.
# Cloned from 4.2; LAPACK/ArmPL leftovers removed.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd -P)"

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

TAG="${1:-}"

run_all() {
  local do_clean="${CLEAN_OUTPUT:-1}"
  if [[ "$do_clean" == "1" ]]; then
    rm -rf "$SCRIPT_DIR/../output/openblas_sve" "$SCRIPT_DIR/../output/openblas_scalar"
  fi
  CLEAN_OUTPUT=0 "$0" benchmark-syev-openblas-sve
  CLEAN_OUTPUT=0 "$0" benchmark-syevd-openblas-sve
  CLEAN_OUTPUT=0 "$0" benchmark-syev-openblas-scalar
  CLEAN_OUTPUT=0 "$0" benchmark-syevd-openblas-scalar
}

if [[ -z "$TAG" || "$TAG" == "all" ]]; then
  run_all
  exit 0
fi

# ====== 1. Base Compiler Setup ======
CC=gcc
#CFLAGS_BASE="-O3 -std=c11 -mcpu=native -mtune=native -D_POSIX_C_SOURCE=199309L"
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

# ====== 2. Library Presets (4.3: OpenBLAS SVE vs scalar only) ======
# - openblas/openblas_install: SVE build — run Code/openblas/build_arm_threads_sve.sh (installs there)
# - openblas_scalar: scalar build — run Code/openblas/build_arm_threads_scalar.sh → Code/openblas_scalar/

# ===== OpenBLAS SVE (static; build_arm_threads_sve.sh → Code/openblas/openblas_install) =====
OPENBLAS_SVE_PREFIX="$CODE_DIR/openblas/openblas_install"
CFLAGS_OB_SVE="$CFLAGS_BASE -I$OPENBLAS_SVE_PREFIX/include"
LDFLAGS_OB_SVE="$OPENBLAS_SVE_PREFIX/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# ===== OpenBLAS scalar (static, Code/openblas_scalar; force ARMV8+ONLY_C build) =====
OPENBLAS_SCALAR_PREFIX="$CODE_DIR/openblas_scalar"
OPENBLAS_SCALAR_LIB="$OPENBLAS_SCALAR_PREFIX/lib"
# Prefer libopenblas_armv8p*.a (ARMV8 + ONLY_C=1 from build_arm_threads_scalar.sh)
if [[ -d "$OPENBLAS_SCALAR_LIB" ]]; then
  armv8_a="$(find "$OPENBLAS_SCALAR_LIB" -maxdepth 1 -name 'libopenblas_armv8p*.a' -print -quit)"
  if [[ -n "$armv8_a" && -f "$armv8_a" ]]; then
    OPENBLAS_SCALAR_A="$armv8_a"
  else
    OPENBLAS_SCALAR_A="$(find "$OPENBLAS_SCALAR_LIB" -maxdepth 1 -name 'libopenblas*.a' -print -quit)"
  fi
fi
OPENBLAS_SCALAR_A="${OPENBLAS_SCALAR_A:-}"
CFLAGS_OB_SCALAR="$CFLAGS_BASE -I$OPENBLAS_SCALAR_PREFIX/include"
LDFLAGS_OB_SCALAR="${OPENBLAS_SCALAR_A:-$OPENBLAS_SCALAR_LIB/libopenblas.a} $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# ArmPL (STATIC THREAD=1)
ARMPL_PREFIX="$CODE_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl.a -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# ArmPL (STATIC THREAD=2)
#ARMPL_PREFIX="../../armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
#CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
#LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl_mp.a -fopenmp -lgomp -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# ArmPL dynamic (add a new preset)
#export LD_LIBRARY_PATH="$CODE_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc/lib:$LD_LIBRARY_PATH"
#ARMPL_PREFIX="$CODE_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
#CFLAGS_AP_DYN="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
#LDFLAGS_AP_DYN="-L$ARMPL_PREFIX/lib -larmpl -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"



# ====== 3. Case Selection ======
case "$TAG" in

  benchmark-syev-openblas-sve)
      SRC="$SCRIPT_DIR/../src/syev_benchmark.c"
      CFLAGS="$CFLAGS_OB_SVE -DLIB_TAG=\"openblas_sve\" -DROUTINE_NAME=\"syev\""
      LDFLAGS="$LDFLAGS_OB_SVE ${WRAP3_LDFLAGS[*]}"
      OUT_LIB="openblas_sve"
      OUT_ROUTINE="syev"
      ;;

  benchmark-syevd-openblas-sve)
      SRC="$SCRIPT_DIR/../src/syevd_benchmark.c"
      CFLAGS="$CFLAGS_OB_SVE -DLIB_TAG=\"openblas_sve\" -DROUTINE_NAME=\"syevd\""
      LDFLAGS="$LDFLAGS_OB_SVE ${WRAP3D_LDFLAGS[*]}"
      OUT_LIB="openblas_sve"
      OUT_ROUTINE="syevd"
      ;;

  benchmark-syev-openblas-scalar)
      SRC="$SCRIPT_DIR/../src/syev_benchmark.c"
      CFLAGS="$CFLAGS_OB_SCALAR -DLIB_TAG=\"openblas_scalar\" -DROUTINE_NAME=\"syev\""
      LDFLAGS="$LDFLAGS_OB_SCALAR ${WRAP3_LDFLAGS[*]}"
      OUT_LIB="openblas_scalar"
      OUT_ROUTINE="syev"
      ;;

  benchmark-syevd-openblas-scalar)
      SRC="$SCRIPT_DIR/../src/syevd_benchmark.c"
      CFLAGS="$CFLAGS_OB_SCALAR -DLIB_TAG=\"openblas_scalar\" -DROUTINE_NAME=\"syevd\""
      LDFLAGS="$LDFLAGS_OB_SCALAR ${WRAP3D_LDFLAGS[*]}"
      OUT_LIB="openblas_scalar"
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


echo "[BUILD] CC=$CC | SRC=$SRC | CFLAGS=$CFLAGS"
$CC $CFLAGS -c "$SRC" -o "$OBJ"

echo "[LINK ] $OBJ -> $BIN"
$CC "$OBJ" $LDFLAGS -o "$BIN"

echo "[RUN  ] LIB=$TAG | EXE=$BIN"
echo "[INFO ] OMP_NUM_THREADS=$OMP_NUM_THREADS OPENBLAS_NUM_THREADS=$OPENBLAS_NUM_THREADS"
cd "$SCRIPT_DIR"
exec "$BIN"
