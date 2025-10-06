#!/usr/bin/env bash
set -euo pipefail

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export ARMPL_NUM_THREADS=1


TAG="${1:-}"
[ -n "$TAG" ] || { echo "Usage: $0 <case_name>"; exit 1; }

# ====== 1. Base Compiler Setup ======
CC=gcc
#CFLAGS_BASE="-O3 -std=c11 -mcpu=native -mtune=native -D_POSIX_C_SOURCE=199309L"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=199309L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_FORTRAN="-lgfortran"
LIBS_MATH="-lm"

# ====== 2. Library Presets ======
# Netlib (dynamic)
# ===== Netlib (static) =====
CFLAGS_NETLIB="$CFLAGS_BASE -I../../LAPACK/build/include"
LDFLAGS_NETLIB="../../LAPACK/build/lib/liblapack.a ../../LAPACK/build/lib/libblas.a $LIBS_FORTRAN $LIBS_MATH"

# ===== OpenBLAS (static) =====
CFLAGS_OB="$CFLAGS_BASE -I../../openblas/openblas_install/include"
LDFLAGS_OB="../../openblas/openblas_install/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# ArmPL (STATIC THREAD=1)
ARMPL_PREFIX="../../armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl.a -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# ArmPL (STATIC THREAD=2)
#ARMPL_PREFIX="../../armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
#CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
#LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl_mp.a -fopenmp -lgomp -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# ArmPL dynamic (add a new preset)
#export LD_LIBRARY_PATH=../../armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc/lib:$LD_LIBRARY_PATH
#ARMPL_PREFIX="../../armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
#CFLAGS_AP_DYN="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
#LDFLAGS_AP_DYN="-L$ARMPL_PREFIX/lib -larmpl -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"



# ====== 3. Case Selection ======
case "$TAG" in

  dsyev-lapack)
      SRC="../src/dsyev.c"
      CFLAGS="$CFLAGS_NETLIB"
      LDFLAGS="$LDFLAGS_NETLIB"
      ;;

  dsyev_dsyevd_compare-openblas)
      SRC="../src/dsyev_dsyevd_compare.c"
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB"
      ;;

  dsyev-openblas)
      SRC="../src/dsyev.c"
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB"
      ;;

  dsyevd-openblas)
      SRC="../src/dsyevd.c"
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB"
      ;;

  dsyevd-armpl)
      SRC="../src/dsyevd.c"
      CFLAGS="$CFLAGS_AP"
      LDFLAGS="$LDFLAGS_AP"
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
OUT_DIR="../output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"
mkdir -p "$OBJ_DIR" "$BIN_DIR"

BASENAME="$(basename "$SRC" .c)"
OBJ="$OBJ_DIR/${BASENAME}.o"
BIN="$BIN_DIR/$TAG"


echo "[BUILD] CC=$CC | SRC=$SRC | CFLAGS=$CFLAGS"
$CC $CFLAGS -c "$SRC" -o "$OBJ"

echo "[LINK ] $OBJ -> $BIN"
$CC "$OBJ" $LDFLAGS -o "$BIN"

echo "[RUN  ] LIB=$TAG | EXE=$BIN"
echo "[INFO ] OMP_NUM_THREADS=$OMP_NUM_THREADS OPENBLAS_NUM_THREADS=$OPENBLAS_NUM_THREADS ARMPL_NUM_THREADS=$ARMPL_NUM_THREADS"
exec "$BIN"
