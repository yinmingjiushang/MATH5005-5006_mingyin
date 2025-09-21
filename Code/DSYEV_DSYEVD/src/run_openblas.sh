#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
SRC="${SRC:-syev_dsyevd_compare.c}"          # source file
OUT="${OUT:-syev_dsyevd_compare}"            # output binary
CC="${CC:-cc}"
FC="${FC:-gfortran}"
OPENBLAS_LIB="../../openblas/lib/libopenblas.a"
OBJDUMP="${OBJDUMP:-/opt/homebrew/opt/llvm/bin/llvm-objdump}"  # optional

echo "==> Creating ../output"
mkdir -p ../output

# ---- Compile & Link ----
echo "==> Compiling: $SRC"
"$CC" -O3 -D_POSIX_C_SOURCE=200112L -c "$SRC" -o "${OUT}.o"

echo "==> Linking with OpenBLAS:"
echo "    $FC ${OUT}.o $OPENBLAS_LIB -lm -o $OUT"
$FC "${OUT}.o" "$OPENBLAS_LIB" -lm -o "$OUT"

# ---- Run ----
THREADS="${OPENBLAS_NUM_THREADS:-$(sysctl -n hw.physicalcpu 2>/dev/null || echo 1)}"
echo "==> Running with OPENBLAS_NUM_THREADS=$THREADS"
OPENBLAS_NUM_THREADS="$THREADS" ./"$OUT"

# ---- Optional Disassembly ----
if [ -x "$OBJDUMP" ]; then
  echo "==> Disassembling: $OBJDUMP -d $OUT"
  "$OBJDUMP" -d "$OUT" > "../output/${OUT}.asm.txt" || true
  echo "    Disassembly saved to ../output/${OUT}.asm.txt"
else
  echo "==> (Skip disassembly: $OBJDUMP not found)"
fi

echo "==> Done. Results in ../output/"
