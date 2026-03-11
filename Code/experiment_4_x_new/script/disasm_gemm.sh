#!/usr/bin/env bash
# Disassemble GEMM path in OpenBLAS SVE vs SIMD-baseline builds and classify ISA usage.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd -P)"
OUT_DIR="$SCRIPT_DIR/../output/disasm"
mkdir -p "$OUT_DIR"

SVE_LIB="$CODE_DIR/openblas/openblas_install/lib/libopenblas.a"
SIMD_LIB_GLOB="$CODE_DIR/openblas_simd/lib/libopenblas_armv8p"'*.a'

# resolve SIMD-baseline lib path
SIMD_LIB=""
for f in $SIMD_LIB_GLOB; do
  if [[ -f "$f" ]]; then
    SIMD_LIB="$f"
    break
  fi
done
if [[ -z "$SIMD_LIB" ]]; then
  SIMD_LIB="$CODE_DIR/openblas_simd/lib/libopenblas.a"
fi

if [[ ! -f "$SVE_LIB" ]]; then
  echo "[X] Missing SVE library: $SVE_LIB"
  exit 1
fi
if [[ ! -f "$SIMD_LIB" ]]; then
  echo "[X] Missing SIMD-baseline library: $SIMD_LIB"
  exit 1
fi

SYMS=(cblas_dgemm dgemm_ dgemm_nn dgemm_kernel dgemm_itcopy dgemm_oncopy)

summarize_sym() {
  local asm_file="$1"

  local sve_hits
  local neon_hits
  local fmla_hits

  sve_hits=$(rg -n '\bz[0-9]+\b|\bp[0-9]+\b|\bptrue\b|\bwhilelo\b|\bld1d\b|\bst1d\b|\bld1rd\b' "$asm_file" | wc -l | tr -d ' ')
  neon_hits=$(rg -n '\bv[0-9]+\.[0-9]*[bhsdq]\b|\bldr\s+q[0-9]+\b|\bstr\s+q[0-9]+\b' "$asm_file" | wc -l | tr -d ' ')
  fmla_hits=$(rg -n '\bfmla\b|\bfmul\b' "$asm_file" | wc -l | tr -d ' ')

  local klass="non-sve-or-unknown"
  if [[ "$sve_hits" -gt 0 ]]; then
    klass="SVE"
  elif [[ "$neon_hits" -gt 0 ]]; then
    klass="NEON/ASIMD"
  fi

  printf "%s,%s,%s,%s\n" "$klass" "$sve_hits" "$neon_hits" "$fmla_hits"
}

dump_one_lib() {
  local tag="$1"
  local lib="$2"
  local summary_csv="$OUT_DIR/${tag}_summary.csv"

  echo "symbol,class,sve_hits,neon_hits,fma_hits" > "$summary_csv"

  for sym in "${SYMS[@]}"; do
    local asm="$OUT_DIR/${tag}_${sym}.s"
    objdump -d --disassemble="$sym" "$lib" > "$asm"

    local summary
    summary=$(summarize_sym "$asm")
    echo "$sym,$summary" >> "$summary_csv"
  done

  {
    echo "=== $tag ==="
    echo "lib: $lib"
    column -s, -t "$summary_csv"
    echo
    echo "--- key instructions from ${tag} dgemm_kernel ---"
    rg -n '\bz[0-9]+\b|\bp[0-9]+\b|\bptrue\b|\bwhilelo\b|\bld1d\b|\bst1d\b|\bld1rd\b|\bv[0-9]+\.[0-9]*[bhsdq]\b|\bfmla\b|\bfmul\b' "$OUT_DIR/${tag}_dgemm_kernel.s" | sed -n '1,80p'
    echo
  } > "$OUT_DIR/${tag}_report.txt"
}

dump_one_lib "openblas_sve" "$SVE_LIB"
dump_one_lib "openblas_simd" "$SIMD_LIB"

{
  echo "GEMM ISA disassembly summary"
  echo "generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  echo
  cat "$OUT_DIR/openblas_sve_report.txt"
  cat "$OUT_DIR/openblas_simd_report.txt"
} > "$OUT_DIR/summary.txt"

cat "$OUT_DIR/summary.txt"
echo
echo "Saved files under: $OUT_DIR"
