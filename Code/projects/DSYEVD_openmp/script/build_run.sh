#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
find_code_dir() {
  local dir="$SCRIPT_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/third_party" && -d "$dir/chapter4" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}
CODE_DIR="$(find_code_dir)" || { echo "Failed to locate Code root from $SCRIPT_DIR" >&2; exit 1; }
THIRD_PARTY_DIR="$CODE_DIR/third_party"

# NOTE:
# 不在此处全局强行钉线程；各 case 自己设置。
# export OMP_NUM_THREADS=${OMP_NUM_THREADS:-1}
# export OPENBLAS_NUM_THREADS=${OPENBLAS_NUM_THREADS:-1}
# export ARMPL_NUM_THREADS=${ARMPL_NUM_THREADS:-1}

TAG="${1:-}"
[ -n "$TAG" ] || { echo "Usage: $0 <case_name>"; exit 1; }

# =============== 1) Compiler setup ===============
CC_DEFAULT="${CC:-gcc}"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=200112L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
LIBS_FORTRAN="-lgfortran"
LIBS_MATH="-lm"

UNAME_S="$(uname -s || true)"
if [[ "${UNAME_S}" == "Darwin" ]]; then
  # macOS: 优先用 lld，才能使用 --wrap
  if [[ "${CC_DEFAULT}" != *"-fuse-ld="* ]]; then
    CC_DEFAULT="${CC_DEFAULT} -fuse-ld=lld"
  fi
fi
CC="${CC_DEFAULT}"

# ---------- helper: OpenMP flags ----------
CFLAGS_OMP="-fopenmp"
LDFLAGS_OMP="-fopenmp"
if [[ "${UNAME_S}" == "Darwin" ]]; then
  # AppleClang 需要 libomp；若用 brew gcc/llvm，一般 -fopenmp 即可
  if "${CC%% *}" --version 2>&1 | grep -qi "apple clang"; then
    CFLAGS_OMP="-Xpreprocessor -fopenmp"
    LDFLAGS_OMP="-lomp"
  fi
fi

# =============== 2) Library presets ===============
CFLAGS_NETLIB="$CFLAGS_BASE -I$THIRD_PARTY_DIR/LAPACK/build/include"
LDFLAGS_NETLIB="$THIRD_PARTY_DIR/LAPACK/build/lib/liblapack.a $THIRD_PARTY_DIR/LAPACK/build/lib/libblas.a $LIBS_FORTRAN $LIBS_MATH"

CFLAGS_OB="$CFLAGS_BASE -I$THIRD_PARTY_DIR/openblas_sve/include"
LDFLAGS_OB="$THIRD_PARTY_DIR/openblas_sve/lib/libopenblas.a $LIBS_FORTRAN $LIBS_MATH -lpthread -ldl"

ARMPL_PREFIX="$THIRD_PARTY_DIR/armpl/arm-performance-libraries_25.07_rpm/armpl_local/armpl_25.07_gcc"
CFLAGS_AP="$CFLAGS_BASE -I$ARMPL_PREFIX/include"
LDFLAGS_AP="$ARMPL_PREFIX/lib/libarmpl.a -lpthread -ldl $LIBS_FORTRAN $LIBS_MATH"

# =============== 3) Sources ===============
SRC_DIR="$ROOT_DIR/src"
SRC_MAIN="$SRC_DIR/syevd_detailed.c"
SRC_WRAP_TIMERS="$SRC_DIR/wrap_timers.c"
SRC_WRAP_TREE="$SRC_DIR/wrap_syevd.c"   # 计时 wrap（你提供的 wrap_syevd.c）
SRC_BENCH="$SRC_DIR/syevd_benchmark.c"
# 仅 STEDC 并行版（你的并行实现）
SRC_OMP_STEDC="$SRC_DIR/syevd_omp.c"

# =============== 4) --wrap sets ===============
# （A）历史通用大表（给老的 detailed-syevd-openblas 用）
WRAP_SYMS=(
  dsytrd_ dorgtr_
  dstedc_ dlaed0_ dlaed1_ dlaed2_ dlaed3_ dlaed4_ dlaed5_ dlaed6_ dlaed7_ dlaed8_ dlaed9_ dlaeda_
  dsteqr_ dsterf_
  dlasrt_ dlamrg_ dlacpy_
  dormtr_ dlarft_ dlarfb_ dlarf_
  dgemm_ dgemv_ dtrmm_ dtrmv_ dger_ dcopy_ dscal_ drot_
  cblas_dgemm cblas_dgemv
)
WRAP_LDFLAGS=()
for s in "${WRAP_SYMS[@]}"; do WRAP_LDFLAGS+=("-Wl,--wrap=${s}"); done

# （B）与 wrap_syevd.c 精确一致的列表（包含 dorgtr_）
WRAP_SYEVD_SYMS=(
  dsyevd_ dsytrd_ dorgtr_ dsterf_
  dstedc_ dsteqr_ dlamrg_ dlasrt_ dlacpy_
  dlaed0_ dlaed1_ dlaed2_ dlaed3_ dlaed4_ dlaed5_ dlaed6_ dlaed7_ dlaed8_ dlaed9_ dlaeda_
  dormtr_ dormql_ dormqr_ dlarft_ dlarfb_ dlarf_
  dgemm_ dgemv_ dtrmm_ dtrmv_ dger_ dcopy_ dscal_ drot_
  cblas_dgemm cblas_dgemv
)
WRAP_SYEVD_LDFLAGS=()
for s in "${WRAP_SYEVD_SYMS[@]}"; do WRAP_SYEVD_LDFLAGS+=("-Wl,--wrap=${s}"); done

# 精简版（benchmark 用）
WRAP3_SYMS=( dsytrd_ dstedc_ dormtr_ )
WRAP3_LDFLAGS=()
for s in "${WRAP3_SYMS[@]}"; do WRAP3_LDFLAGS+=("-Wl,--wrap=${s}"); done

# =============== 5) Case selection ===============
case "$TAG" in
  # ===== 现有：详细 profile 版（wrap，走通用大表） =====
  detailed-syevd-openblas)
      export OMP_NUM_THREADS=1
      export OPENBLAS_NUM_THREADS=1
      export ARMPL_NUM_THREADS=1
      SRCS=("$SRC_MAIN" "$SRC_WRAP_TIMERS" "$SRC_WRAP_TREE")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP_LDFLAGS[*]}"
      ;;

  # ===== 现有：benchmark 版（程序内自行设线程）=====
  benchmark-syevd-openblas)
      unset OMP_NUM_THREADS || true
      unset OPENBLAS_NUM_THREADS || true
      unset ARMPL_NUM_THREADS || true
      SRCS=("$SRC_BENCH")
      CFLAGS="$CFLAGS_OB"
      LDFLAGS="$LDFLAGS_OB ${WRAP3_LDFLAGS[*]}"
      ;;

  # ===== 新增：仅 STEDC 用 OpenMP 并行（OpenBLAS 后端）=====
  detailed-syevd-openblas-omp)
      export OMP_NUM_THREADS=2
      export OPENBLAS_NUM_THREADS=1
      export ARMPL_NUM_THREADS=1
      SRCS=("$SRC_OMP_STEDC")
      CFLAGS="$CFLAGS_OB $CFLAGS_OMP"
      LDFLAGS="$LDFLAGS_OB $LDFLAGS_OMP"
      ;;

  # ===== 新增：仅 STEDC 用 OpenMP 并行 + wrap计时（OpenBLAS 后端；使用与 wrap_syevd.c 一致的列表）=====
  detailed-syevd-openblas-omp-wrap)
      export OMP_NUM_THREADS=2
      export OPENBLAS_NUM_THREADS=1
      export ARMPL_NUM_THREADS=1
      # 编进 syevd_omp.c + wrap_timers.c + wrap_syevd.c
      SRCS=("$SRC_OMP_STEDC" "$SRC_WRAP_TIMERS" "$SRC_WRAP_TREE")
      CFLAGS="$CFLAGS_OB $CFLAGS_OMP"
      LDFLAGS="$LDFLAGS_OB $LDFLAGS_OMP ${WRAP_SYEVD_LDFLAGS[*]}"
      ;;

  # ===== 新增：仅 STEDC 用 OpenMP 并行（Netlib 后端）=====
  omp-stedc-netlib)
      export OMP_NUM_THREADS=2
      unset OPENBLAS_NUM_THREADS || true
      unset ARMPL_NUM_THREADS || true
      SRCS=("$SRC_OMP_STEDC")
      CFLAGS="$CFLAGS_NETLIB $CFLAGS_OMP"
      LDFLAGS="$LDFLAGS_NETLIB $LDFLAGS_OMP"
      ;;

  # ===== 新增：仅 STEDC 用 OpenMP 并行（ArmPL 后端）=====
  omp-stedc-armpl)
      export OMP_NUM_THREADS=2
      export ARMPL_NUM_THREADS=1
      SRCS=("$SRC_OMP_STEDC")
      CFLAGS="$CFLAGS_AP $CFLAGS_OMP"
      LDFLAGS="$LDFLAGS_AP $LDFLAGS_OMP"
      ;;

  *)
      echo "[X] Unknown TAG: $TAG"
      echo "    Available:"
      echo "      detailed-syevd-openblas"
      echo "      benchmark-syevd-openblas"
      echo "      detailed-syevd-openblas-omp"
      echo "      detailed-syevd-openblas-omp-wrap"
      echo "      omp-stedc-netlib"
      echo "      omp-stedc-armpl"
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
exec "$BIN"
