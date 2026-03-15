#!/usr/bin/env bash
set -euo pipefail

# NOTE:
# Do NOT force threads globally; we'll set them per-case below.
# export OMP_NUM_THREADS=${OMP_NUM_THREADS:-1}
# export OPENBLAS_NUM_THREADS=${OPENBLAS_NUM_THREADS:-1}
# export ARMPL_NUM_THREADS=${ARMPL_NUM_THREADS:-1}

TAG="${1:-}"
[ -n "$TAG" ] || { echo "Usage: $0 <case_name>"; exit 1; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$ROOT_DIR/../../.." >/dev/null 2>&1 && pwd -P)"

# =============== 1) Compiler setup ===============
CC_DEFAULT="${CC:-gcc}"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=200112L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_FORTRAN="-lgfortran"
LIBS_MATH="-lm"

UNAME_S="$(uname -s || true)"
if [[ "${UNAME_S}" == "Darwin" ]]; then
  if [[ "${CC_DEFAULT}" != *"-fuse-ld="* ]]; then
    CC_DEFAULT="${CC_DEFAULT} -fuse-ld=lld"
  fi
fi
CC="${CC_DEFAULT}"

# =============== 2) Library presets ===============
CFLAGS_NETLIB="$CFLAGS_BASE -I$CODE_DIR/LAPACK/build/include"
LDFLAGS_NETLIB="$CODE_DIR/LAPACK/build/lib/liblapack.a $CODE_DIR/LAPACK/build/lib/libblas.a $LIBS_FORTRAN $LIBS_MATH"

CFLAGS_OB="$CFLAGS_BASE -DOPENBLAS_USE64BITINT -I$CODE_DIR/openblas/openblas_install/include"
LDFLAGS_OB="$CODE_DIR/openblas/openblas_install/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

ARMPL_PREFIX="$CODE_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl.a -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# =============== 3) Sources ===============
SRC_DIR="$ROOT_DIR/src"
SRC_MAIN="$SRC_DIR/syevd_detailed.c"
SRC_WRAP_TIMERS="$SRC_DIR/wrap_timers.c"
SRC_WRAP_TREE="$SRC_DIR/wrap_syevd.c"

SRC_BENCH="$SRC_DIR/syevd_benchmark.c"

# =============== 4) --wrap sets ===============
WRAP_SYMS=(
  dsyevd_ dsytrd_ dorgtr_ dsterf_
  dstedc_ dsteqr_ dlamrg_ dlasrt_ dlacpy_
  dlaed0_ dlaed1_ dlaed2_ dlaed3_ dlaed4_ dlaed5_ dlaed6_ dlaed7_ dlaed8_ dlaed9_ dlaeda_
  dormtr_ dormql_ dormqr_ dlarft_ dlarfb_ dlarf_
  dgemm_ dgemv_ dtrmm_ dtrmv_ dger_ dcopy_ dscal_ drot_
  cblas_dgemm cblas_dgemv
)
WRAP_LDFLAGS=()
for s in "${WRAP_SYMS[@]}"; do WRAP_LDFLAGS+=("-Wl,--wrap=${s}"); done

# ====== benchmark-specific wrap list (used by benchmark build) ======
WRAP3_SYMS=( dsytrd_ dstedc_ dormtr_ )
WRAP3_LDFLAGS=()
for s in "${WRAP3_SYMS[@]}"; do WRAP3_LDFLAGS+=("-Wl,--wrap=${s}"); done
# ===================================================================

# =============== 5) Case selection ===============
case "$TAG" in
  detailed-syevd-openblas)
      # Profile: force single-thread to reduce variance
      export OMP_NUM_THREADS=1
      export OPENBLAS_NUM_THREADS=1
      export ARMPL_NUM_THREADS=1

      SRCS=("$SRC_MAIN" "$SRC_WRAP_TIMERS" "$SRC_WRAP_TREE")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP_LDFLAGS[*]}"
      ;;

  benchmark-syevd-openblas)
      # ====== Variables for benchmark mode ======
      # In benchmark mode we DO NOT pin threads here.
      # The benchmark program sets threads to {1,2,4} internally using:
      #   - setenv("OMP_NUM_THREADS", ...)
      #   - setenv("OPENBLAS_NUM_THREADS", ...)
      #   - openblas_set_num_threads(...) / mkl_set_num_threads(...)
      # This guarantees correct per-run threading, regardless of shell env.
      # Optionally, we can unset any inherited thread envs to be extra safe:
      unset OMP_NUM_THREADS || true
      unset OPENBLAS_NUM_THREADS || true
      unset ARMPL_NUM_THREADS || true
      # ===============================================================

      SRCS=("$SRC_BENCH")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP3_LDFLAGS[*]}"
      ;;

  *)
      echo "[X] Unknown TAG: $TAG"
      echo "    Available: syevd-profile-openblas | benchmark-openblas | syevd-profile-netlib | syevd-profile-armpl"
      exit 1;;
esac

# =============== 6) Build & Run ===============
OUT_DIR="$ROOT_DIR/output"
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
# Info print only (may be empty in benchmark mode since we unset them)
#echo "[INFO ] OMP_NUM_THREADS=${OMP_NUM_THREADS:-} OPENBLAS_NUM_THREADS=${OPENBLAS_NUM_THREADS:-} ARMPL_NUM_THREADS=${ARMPL_NUM_THREADS:-}"
cd "$ROOT_DIR"
exec "$BIN"
