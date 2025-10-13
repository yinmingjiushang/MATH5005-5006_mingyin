#!/usr/bin/env bash
set -euo pipefail

export OMP_NUM_THREADS=${OMP_NUM_THREADS:-1}
export OPENBLAS_NUM_THREADS=${OPENBLAS_NUM_THREADS:-1}
export ARMPL_NUM_THREADS=${ARMPL_NUM_THREADS:-1}

TAG="${1:-}"
[ -n "$TAG" ] || { echo "Usage: $0 <case_name>"; exit 1; }

# ====== 1) Compiler setup ======
CC_DEFAULT="${CC:-gcc}"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=199309L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_FORTRAN="-lgfortran"
LIBS_MATH="-lm"

# macOS: try to use lld so that --wrap works
UNAME_S="$(uname -s || true)"
if [[ "${UNAME_S}" == "Darwin" ]]; then
  # If CC doesn't already contain -fuse-ld, append lld
  if [[ "${CC_DEFAULT}" != *"-fuse-ld="* ]]; then
    CC_DEFAULT="${CC_DEFAULT} -fuse-ld=lld"
  fi
fi
CC="${CC_DEFAULT}"

# ====== 2) Library presets ======
# Netlib (static)
CFLAGS_NETLIB="$CFLAGS_BASE -I../../LAPACK/build/include"
LDFLAGS_NETLIB="../../LAPACK/build/lib/liblapack.a ../../LAPACK/build/lib/libblas.a $LIBS_FORTRAN $LIBS_MATH"

# OpenBLAS (static, ILP64 示例；若是 LP64 可去掉 -DOPENBLAS_USE64BITINT)
CFLAGS_OB="$CFLAGS_BASE -DOPENBLAS_USE64BITINT -I../../openblas/openblas_install/include"
LDFLAGS_OB="../../openblas/openblas_install/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# ArmPL (static, 1 thread)
ARMPL_PREFIX="../../armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl.a -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# ====== 3) Sources ======
SRC_DIR="../src"
SRC_MAIN="$SRC_DIR/syevd.c"
SRC_WRAP_TIMERS="$SRC_DIR/wrap_timers.c"
SRC_WRAP_TREE="$SRC_DIR/wrap_syevd.c"     # 你整合好的 wrapper 文件

# ====== 4) Symbols to --wrap (DSYEVD 全链路 + 回带 + 常见 BLAS) ======
WRAP_SYMS=(
  # top & tridiag/tri eigensolvers
  dsyevd_ dsytrd_ dorgtr_ dsterf_
  # STEDC + helpers
  dstedc_ dsteqr_ dlamrg_ dlasrt_ dlacpy_
  # D&C subtree
  dlaed0_ dlaed1_ dlaed2_ dlaed3_ dlaed4_ dlaed5_ dlaed6_ dlaed7_ dlaed8_ dlaed9_ dlaeda_
  # back-transform chain
  dormtr_ dormql_ dormqr_ dlarft_ dlarfb_ dlarf_
  # BLAS commonly used
  dgemm_ dgemv_ dtrmm_ dtrmv_ dger_ dcopy_ dscal_ drot_
  # if you call CBLAS directly
  cblas_dgemm cblas_dgemv
)
WRAP_LDFLAGS=()
for s in "${WRAP_SYMS[@]}"; do WRAP_LDFLAGS+=("-Wl,--wrap=${s}"); done

# ====== 5) Case selection ======
case "$TAG" in
  # OpenBLAS + DSYEVD driver + per-subroutine timing wrappers
  syevd-profile-openblas)
      SRCS=("$SRC_MAIN" "$SRC_WRAP_TIMERS" "$SRC_WRAP_TREE")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP_LDFLAGS[*]}"
      ;;
  # 可选：Netlib
  syevd-profile-netlib)
      SRCS=("$SRC_MAIN" "$SRC_WRAP_TIMERS" "$SRC_WRAP_TREE")
      CFLAGS="$CFLAGS_NETLIB"
      LDFLAGS="$LDFLAGS_NETLIB ${WRAP_LDFLAGS[*]}"
      ;;
  # 可选：ArmPL
  syevd-profile-armpl)
      SRCS=("$SRC_MAIN" "$SRC_WRAP_TIMERS" "$SRC_WRAP_TREE")
      CFLAGS="$CFLAGS_AP"
      LDFLAGS="$LDFLAGS_AP ${WRAP_LDFLAGS[*]}"
      ;;
  *)
      echo "[X] Unknown TAG: $TAG"
      echo "    Available: syevd-profile-openblas | syevd-profile-netlib | syevd-profile-armpl"
      exit 1;;
esac

# ====== 6) Output & Build ======
OUT_DIR="../output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"
mkdir -p "$OBJ_DIR" "$BIN_DIR"

OBJS=()
for f in "${SRCS[@]}"; do
  base="$(basename "$f" .c)"
  obj="$OBJ_DIR/${base}.o"
  echo "[BUILD] CC=$CC | SRC=$f"
  $CC $CFLAGS -c "$f" -o "$obj"
  OBJS+=("$obj")
done

BIN="$BIN_DIR/$TAG"
echo "[LINK ] ${OBJS[*]} -> $BIN"
$CC "${OBJS[@]}" $LDFLAGS -o "$BIN"

echo "[RUN  ] EXE=$BIN"
echo "[INFO ] OMP_NUM_THREADS=$OMP_NUM_THREADS OPENBLAS_NUM_THREADS=$OPENBLAS_NUM_THREADS ARMPL_NUM_THREADS=$ARMPL_NUM_THREADS"
exec "$BIN"
