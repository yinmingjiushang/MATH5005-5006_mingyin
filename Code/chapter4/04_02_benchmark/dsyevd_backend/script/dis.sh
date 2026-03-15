#!/usr/bin/env bash
set -euo pipefail

# ===== 0) Helpers =====
die(){ echo "[X] $*" >&2; exit 1; }
here="$(cd -- "$(dirname "$0")" && pwd -P)"
root="$(cd "$here/.." && pwd -P)"
code_dir="$(cd "$root/../../.." && pwd -P)"

OUT_DIR="$root/output"
OBJ_DIR="$OUT_DIR/obj"
BIN_DIR="$OUT_DIR/bin"
DIS_DIR="$OUT_DIR/disasm"
mkdir -p "$OBJ_DIR" "$BIN_DIR" "$DIS_DIR"

# ===== 1) Compiler & Flags =====
CC="${CC:-gcc}"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=200112L \
  -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"

OPENBLAS_INC="$code_dir/openblas/openblas_install/include"
OPENBLAS_LIB="$code_dir/openblas/openblas_install/lib/libopenblas.a"

CFLAGS_OB="$CFLAGS_BASE -DOPENBLAS_USE64BITINT -I${OPENBLAS_INC}"
LDFLAGS_OB="${OPENBLAS_LIB} -lpthread -ldl -lgfortran -lm -Wl,-Map,${OUT_DIR}/link.map"

# ===== 2) Sources =====
SRC_DIR="$root/src"
SRC_MAIN="$SRC_DIR/syevd_detailed.c"
SRC_WRAP_TIMERS="$SRC_DIR/wrap_timers.c"
SRC_WRAP_TREE="$SRC_DIR/wrap_syevd.c"
SRC_BENCH="$SRC_DIR/syevd_benchmark.c"

# ===== 3) --wrap list =====
WRAP_SYMS=(
  dsyevd_ dsytrd_ dorgtr_ dsterf_
  dstedc_ dsteqr_ dlamrg_ dlasrt_ dlacpy_
  dlaed0_ dlaed1_ dlaed2_ dlaed3_ dlaed4_ dlaed5_ dlaed6_ dlaed7_ dlaed8_ dlaed9_ dlaeda_
  dormtr_ dormql_ dormqr_ dlarft_ dlarfb_ dlarf_
  dgemm_ dgemv_ dtrmm_ dtrmv_ dger_ dcopy_ dscal_ drot_
  cblas_dgemm cblas_dgemv
)
WRAP_LDFLAGS=(); for s in "${WRAP_SYMS[@]}"; do WRAP_LDFLAGS+=("-Wl,--wrap=${s}"); done

# Only for the benchmark target
WRAP3_SYMS=( dsytrd_ dstedc_ dormtr_ )
WRAP3_LDFLAGS=(); for s in "${WRAP3_SYMS[@]}"; do WRAP3_LDFLAGS+=("-Wl,--wrap=${s}"); done

# ===== 4) Build (OpenBLAS only) =====
build_target() {
  local mode="$1" bin
  case "$mode" in
    detailed)
      export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 ARMPL_NUM_THREADS=1
      local SRCS=("$SRC_MAIN" "$SRC_WRAP_TIMERS" "$SRC_WRAP_TREE")
      local CFLAGS="$CFLAGS_OB"
      local LDFLAGS="$LDFLAGS_OB ${WRAP_LDFLAGS[*]}"
      bin="$BIN_DIR/detailed-syevd-openblas"
      ;;
    bench)
      unset OMP_NUM_THREADS OPENBLAS_NUM_THREADS ARMPL_NUM_THREADS || true
      local SRCS=("$SRC_BENCH")
      local CFLAGS="$CFLAGS_OB"
      local LDFLAGS="$LDFLAGS_OB ${WRAP3_LDFLAGS[*]}"
      bin="$BIN_DIR/benchmark-syevd-openblas"
      ;;
    *)
      die "Unknown build mode: $mode"
      ;;
  esac

  # Compile
  OBJS=()
  for f in "${SRCS[@]}"; do
    base="$(basename "$f" .c)"
    obj="$OBJ_DIR/${base}.o"
    echo "[BUILD] CC=$CC | SRC=$f" >&2
    $CC $CFLAGS -c "$f" -o "$obj"
    OBJS+=("$obj")
  done

  # Link
  echo "[LINK ] ${OBJS[*]} -> $bin" >&2
  test -f "$OPENBLAS_LIB" || die "OpenBLAS static lib not found at: $OPENBLAS_LIB"
  $CC "${OBJS[@]}" $LDFLAGS -o "$bin"
  echo "[OK   ] Built: $bin" >&2
  echo "[INFO ] Link map: $OUT_DIR/link.map" >&2

  # 标准输出只回传二进制路径
  echo "$bin"
}

# ===== 5) Disassembly helpers =====
# Count SVE mnemonics in a given text file
sve_hits(){
  local file="$1"
  grep -E '(^|[^a-z])z[0-9]|(^|[[:space:]])ptrue([[:space:]]|$)|while(lo|ls)|\bfmla[[:space:]]+z' -n "$file" | wc -l | tr -d ' '
}

# Try to resolve a symbol spelling inside a binary (returns the picked symbol)
resolve_sym_in_bin(){
  local bin="$1" base="$2"
  # Try common Fortran/--wrap variants
  local cands=(
    "${base}_" "__wrap_${base}_" "__real_${base}_"
    "${base}"  "__wrap_${base}"  "__real_${base}"
  )
  local nm_names
  nm_names="$(nm --defined-only "$bin" 2>/dev/null | awk '{print $3}' || true)"
  for s in "${cands[@]}"; do
    if printf '%s\n' "$nm_names" | grep -qx "$s"; then
      echo "$s"; return 0
    fi
  done
  return 1
}

# Robust symbol-range extraction via sed (works across objdump variants)
dis_symbol(){
  local bin="$1" base="$2"
  local picked out
  if ! picked="$(resolve_sym_in_bin "$bin" "$base")"; then
    echo "[warn] Exact symbol for '$base' not found in $bin; falling back to '${base}_' pattern..." >&2
    picked="${base}_"
  fi
  out="$DIS_DIR/symbol_${picked}.txt"

  # Dump whole .text once to avoid repeated objdump cost (ok to stream)
  # Use sed to extract from "<symbol>:" to the first blank line boundary.
  # This is resilient even when --disassemble-symbols is unsupported.
  objdump -d "$bin" | sed -n "/<${picked}>:/,/^$/p" > "$out" || true

  echo "[DISASM] symbol '$picked' -> $out"
  echo "[SVE   ] hits in '$picked': $(sve_hits "$out")"
}

dis_full(){
  local bin="$1" out="$DIS_DIR/full_$(basename "$bin").txt"
  objdump -d "$bin" > "$out"
  echo "[DISASM] full -> $out"
  echo "[SVE   ] hits in full: $(sve_hits "$out")"
}

# ===== 6) CLI =====
cmd="${1:-}"
case "$cmd" in
  build)
    build_target detailed >/dev/null
    ;;

  full)
    bin="$(build_target detailed)"
    dis_full "$bin"
    ;;

  symbol)
    sym="${2:-}"; [ -n "$sym" ] || die "Usage: $0 symbol <name>"
    bin="$(build_target detailed)"
    dis_symbol "$bin" "$sym"
    ;;

  gemm)
    bin="$(build_target detailed)"
    dis_symbol "$bin" "dgemm"
    ;;

  dlaed0)
    bin="$(build_target detailed)"
    dis_symbol "$bin" "dlaed0"
    ;;

  kernel)
    # 一键反汇编 dgemm_kernel
    bin="$(build_target detailed)"
    dis_symbol "$bin" "dgemm_kernel"
    ;;

  *)
    cat <<USAGE
Usage:
  $0 build            # 只编译
  $0 full             # 编译后反汇编整个可执行文件 -> ../output/disasm/full_*.txt
  $0 symbol <name>    # 编译后只反汇编某个符号(智能匹配 _ / __wrap_ / __real_) -> ../output/disasm/symbol_*.txt
  $0 gemm             # 等价于: symbol dgemm
  $0 dlaed0           # 等价于: symbol dlaed0
  $0 kernel           # 反汇编 dgemm_kernel

说明：
- 仅使用相对路径链接 OpenBLAS: ${OPENBLAS_LIB}
- 生成 link map: ${OUT_DIR}/link.map
- 反汇编输出目录: ${DIS_DIR}
USAGE
    ;;
esac
