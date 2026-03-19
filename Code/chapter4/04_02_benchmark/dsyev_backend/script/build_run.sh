#!/usr/bin/env bash
set -euo pipefail

# ============================================
# DSYEV build/run script (aligned with syevd)
# Cases:
#   benchmark-syev-openblas
#   detailed-syev-openblas
# ============================================

TAG="${1:-}"
[ -n "$TAG" ] || { echo "Usage: $0 <case_name>"; echo "Cases: benchmark-syev-openblas | detailed-syev-openblas"; exit 1; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$ROOT_DIR/../../.." >/dev/null 2>&1 && pwd -P)"
THIRD_PARTY_DIR="$CODE_DIR/third_party"

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

# =============== 2) Library preset (OpenBLAS) ===============
CFLAGS_OB="$CFLAGS_BASE -DOPENBLAS_USE64BITINT -I$THIRD_PARTY_DIR/openblas_sve/include"
LDFLAGS_OB="$THIRD_PARTY_DIR/openblas_sve/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# =============== 3) Sources ===============
SRC_DIR="$ROOT_DIR/src"
SRC_MAIN="$SRC_DIR/syev_detailed.c"
SRC_BENCH="$SRC_DIR/syev_benchmark.c"
SRC_WRAP_TREE="$SRC_DIR/wrap_syev.c"
SRC_WRAP_TIMERS="$SRC_DIR/wrap_timers.c"



# =============== 4) --wrap sets ===============
# Full wrap set for "detailed" profiling (mirrors syevd layout but for syev/QR path)
WRAP_SYMS=(
  dsyev_ dsytrd_ dorgtr_ dsteqr_ dsterf_
  # STEQR helpers
  dlae2_ dlaev2_ dlartg_ dlasr_ dlasrt_ dswap_ dlaset_
  # ORGTR chain
  dorgqr_ dorg2r_ dorgql_ dorg2l_ dlarft_ dlarfb_
  # BLAS kernels commonly hit
  dgemm_ dgemv_ dtrmm_ dtrmv_ dger_ dcopy_ dscal_ drot_
  # (optional) cblas symbols if your code calls them
  cblas_dgemm cblas_dgemv
)
WRAP_LDFLAGS=()
for s in "${WRAP_SYMS[@]}"; do WRAP_LDFLAGS+=("-Wl,--wrap=${s}"); done

# Minimal wrap set for benchmark binary (lightweight)
WRAP3_SYMS=( dsytrd_ dsteqr_ dorgtr_ )
WRAP3_LDFLAGS=()
for s in "${WRAP3_SYMS[@]}"; do WRAP3_LDFLAGS+=("-Wl,--wrap=${s}"); done

# =============== 5) Case selection ===============
case "$TAG" in
  detailed-syev-openblas)
      # Profile: single-thread to reduce variance
      export OMP_NUM_THREADS=1
      export OPENBLAS_NUM_THREADS=1
      export ARMPL_NUM_THREADS=1

      SRCS=("$SRC_MAIN" "$SRC_WRAP_TIMERS" "$SRC_WRAP_TREE")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP_LDFLAGS[*]}"
      ;;

  benchmark-syev-openblas)
      # Benchmark: do NOT pin threads here (your benchmark program should manage it)
      unset OMP_NUM_THREADS || true
      unset OPENBLAS_NUM_THREADS || true
      unset ARMPL_NUM_THREADS || true

      SRCS=("$SRC_BENCH")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP3_LDFLAGS[*]}"
      ;;

  *)
      echo "[X] Unknown TAG: $TAG"
      echo "    Available: benchmark-syev-openblas | detailed-syev-openblas"
      exit 1;;
esac

# =============== 6) Build & Run ===============
OUT_DIR="$ROOT_DIR/output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"
mkdir -p "$OBJ_DIR" "$BIN_DIR" "$OUT_DIR"

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
# echo "[INFO ] OMP_NUM_THREADS=${OMP_NUM_THREADS:-} OPENBLAS_NUM_THREADS=${OPENBLAS_NUM_THREADS:-} ARMPL_NUM_THREADS=${ARMPL_NUM_THREADS:-}"
cd "$ROOT_DIR"
exec "$BIN"
