#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "Usage: $0 <case_name>"
  echo "Cases:"
  echo "  benchmark-syev-openblas"
  echo "  detailed-syev-openblas"
  exit 1
fi

# ---------- Compiler ----------
CC="${CC:-gcc}"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=200112L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_FORTRAN="-lgfortran"
LIBS_MATH="-lm"

if [[ "$(uname -s)" == "Darwin" ]]; then
  if [[ "${CC}" != *"-fuse-ld="* ]]; then
    CC="${CC} -fuse-ld=lld"
  fi
fi

# ---------- OpenBLAS paths ----------
CFLAGS_OB="$CFLAGS_BASE -DOPENBLAS_USE64BITINT -I../../openblas/openblas_install/include"
LDFLAGS_OB="../../openblas/openblas_install/lib/libopenblas.a \
  $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

# ---------- Sources ----------
SRC_DIR="../src"
SRC_SYEV_DETAILED="$SRC_DIR/syev_detailed.c"
SRC_WRAP_SYEV="$SRC_DIR/wrap_syev.c"
SRC_WRAP_TIMERS="$SRC_DIR/wrap_timers.c"
SRC_SYEV_BENCH="$SRC_DIR/syev_benchmark.c"

# ---------- Wrap lists ----------
WRAP3_SYEV_SYMS=( dsytrd_ dorgtr_ dsteqr_ )
WRAP3_SYEV_LDFLAGS=()
for s in "${WRAP3_SYEV_SYMS[@]}"; do WRAP3_SYEV_LDFLAGS+=("-Wl,--wrap=${s}"); done

WRAP_SYEV_SYMS=(
  dsyev_ dsytrd_ dorgtr_ dsteqr_
  dlarft_ dlarfb_ dlarf_ dlarfg_
  dlasr_ dlartg_ dlapy2_ dlanst_ dlan2_
  dgemm_ dtrmm_ dgemv_ dtrmv_ dger_ dcopy_ dscal_ drot_
)
WRAP_SYEV_LDFLAGS=()
for s in "${WRAP_SYEV_SYMS[@]}"; do WRAP_SYEV_LDFLAGS+=("-Wl,--wrap=${s}"); done

# ---------- Case selection ----------
case "$TAG" in
  benchmark-syev-openblas)
      unset OMP_NUM_THREADS OPENBLAS_NUM_THREADS ARMPL_NUM_THREADS || true
      SRCS=("$SRC_SYEV_BENCH")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP3_SYEV_LDFLAGS[*]}"
      ;;

  detailed-syev-openblas)
      export OMP_NUM_THREADS=1
      export OPENBLAS_NUM_THREADS=1
      export ARMPL_NUM_THREADS=1
      SRCS=("$SRC_SYEV_DETAILED" "$SRC_WRAP_SYEV" "$SRC_WRAP_TIMERS")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP_SYEV_LDFLAGS[*]}"
      ;;

  *)
      echo "Unknown TAG: $TAG"
      exit 1;;
esac

# ---------- Build & Run ----------
OUT_DIR="../output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"
mkdir -p "$OBJ_DIR" "$BIN_DIR" "$OUT_DIR"

OBJS=()
for f in "${SRCS[@]}"; do
  base="$(basename "$f" .c)"
  obj="$OBJ_DIR/${base}.o"
  echo "[BUILD] $f"
  $CC $CFLAGS -c "$f" -o "$obj"
  OBJS+=("$obj")
done

BIN="$BIN_DIR/$TAG"
echo "[LINK ] -> $BIN"
$CC "${OBJS[@]}" $LDFLAGS -o "$BIN"

echo "[RUN  ] $BIN"
#echo "[INFO ] OMP_NUM_THREADS=${OMP_NUM_THREADS:-} OPENBLAS_NUM_THREADS=${OPENBLAS_NUM_THREADS:-}"
exec "$BIN"
