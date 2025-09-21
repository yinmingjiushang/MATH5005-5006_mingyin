#!/usr/bin/env bash
set -euo pipefail

# ---- Config (can be overridden via env) ----
SRC="${SRC:-syev_dsyevd_compare.c}"
OUT="${OUT:-syev_dsyevd_compare}"
CC="${CC:-cc}"
FC="${FC:-gfortran}"

# Local LAPACK/BLAS (your defaults)
LAPACK_LIB="${LAPACK_LIB:-../../LAPACK_build/build/lib/liblapack.a}"
BLAS_LIB="${BLAS_LIB:-../../LAPACK_build/build/lib/libblas.a}"

OBJDUMP="${OBJDUMP:-/opt/homebrew/opt/llvm/bin/llvm-objdump}"  # optional

# ---- Build ----
echo "==> Creating ../output"
mkdir -p ../output

echo "==> Compiling (C -> .o): $SRC"
"$CC" -O3 -c "$SRC" -o "${OUT}.o"

echo "==> Linking with gfortran (pulls Fortran runtime):"
echo "    $FC ${OUT}.o $LAPACK_LIB $BLAS_LIB -lm -o $OUT"
"$FC" "${OUT}.o" "$LAPACK_LIB" "$BLAS_LIB" -lm -o "$OUT"

# ---- Run ----
echo "==> Running: ./$OUT"
./"$OUT"

# ---- Optional: disassembly if llvm-objdump exists ----
if [ -x "$OBJDUMP" ]; then
  echo "==> Disassembling with: $OBJDUMP -d $OUT"
  "$OBJDUMP" -d "$OUT" > "../output/${OUT}.asm.txt" || true
  echo "    Disassembly written to ../output/${OUT}.asm.txt"
else
  echo "==> (Skip disassembly: $OBJDUMP not found/executable)"
fi

echo "==> Done. Check ../output/ for files."
