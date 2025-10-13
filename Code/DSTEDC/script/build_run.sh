#!/usr/bin/env bash
set -euo pipefail

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export ARMPL_NUM_THREADS=1

TAG="${1:-}"
[ -n "$TAG" ] || { echo "Usage: $0 <case_name>"; exit 1; }

# ====== 1. Base Compiler Setup ======
CC=${CC:-gcc}
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=199309L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_FORTRAN="-lgfortran"
LIBS_MATH="-lm"


# export CC="clang -fuse-ld=lld"

# ====== 2. Library Presets (kept for future use) ======
# Netlib (static)
CFLAGS_NETLIB="$CFLAGS_BASE -I../../LAPACK/build/include"
LDFLAGS_NETLIB="../../LAPACK/build/lib/liblapack.a ../../LAPACK/build/lib/libblas.a $LIBS_FORTRAN $LIBS_MATH"

# OpenBLAS (static)
#CFLAGS_OB="$CFLAGS_BASE -I../../openblas/openblas_install/include"
CFLAGS_OB="$CFLAGS_BASE -DOPENBLAS_USE64BITINT -I../../openblas/openblas_install/include"

LDFLAGS_OB="../../openblas/openblas_install/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# ArmPL (static, 1 thread)
ARMPL_PREFIX="../../armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl.a -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# ====== 3. Sources ======
SRC_DIR="../src"
SRC_STEDC_RUN="$SRC_DIR/stedc_run.c"
SRC_WRAP_TIMERS="$SRC_DIR/wrap_timers.c"
SRC_WRAP_STEDC="$SRC_DIR/wrap_stedc.c"

# ====== 4. STEDC subtree symbols to wrap ======
WRAP_SYMS=(
  dstedc_
  dlamrg_ dlasrt_ dlacpy_ dsteqr_
  dlaed0_ dlaed1_ dlaed2_ dlaed3_ dlaed4_ dlaed5_ dlaed6_ dlaed7_ dlaed8_ dlaed9_ dlaeda_
  dgemm_ dgemv_ dcopy_ dscal_ drot_
  cblas_dgemm cblas_dgemv

)
WRAP_LDFLAGS=(); for s in "${WRAP_SYMS[@]}"; do WRAP_LDFLAGS+=("-Wl,--wrap=${s}"); done





# ====== 5. Case Selection (ONLY ONE CASE as requested) ======
case "$TAG" in
  # OpenBLAS + STEDC driver + per-subroutine timing wrappers
  stedc-profile-openblas)
      SRCS=("$SRC_STEDC_RUN" "$SRC_WRAP_TIMERS" "$SRC_WRAP_STEDC")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP_LDFLAGS[*]}"
      ;;
  *)
      echo "[X] Unknown TAG: $TAG"
      echo "    Available: stedc-profile-openblas"
      exit 1;;
esac

# ====== 6. Output & Build ======
OUT_DIR="../output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"
mkdir -p "$OBJ_DIR" "$BIN_DIR"

OBJS=()
for f in "${SRCS[@]}"; do
  base="$(basename "$f" .c)"
  obj="$OBJ_DIR/${base}.o"
  echo "[BUILD] CC=$CC | SRC=$f | CFLAGS=$CFLAGS"
  $CC $CFLAGS -c "$f" -o "$obj"
  OBJS+=("$obj")
done

BIN="$BIN_DIR/$TAG"
echo "[LINK ] ${OBJS[*]} -> $BIN"
$CC "${OBJS[@]}" $LDFLAGS -o "$BIN"

echo "[RUN  ] LIB=$TAG | EXE=$BIN"
echo "[INFO ] OMP_NUM_THREADS=$OMP_NUM_THREADS OPENBLAS_NUM_THREADS=$OPENBLAS_NUM_THREADS ARMPL_NUM_THREADS=$ARMPL_NUM_THREADS"
exec "$BIN"
