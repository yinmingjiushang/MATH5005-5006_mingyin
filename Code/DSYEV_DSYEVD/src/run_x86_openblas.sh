#!/usr/bin/env bash
# Build & run syev_dsyevd_compare on Windows (MSYS2 + MinGW-w64, UCRT64)
# Usage:
#   bash build_and_run_win.sh
set -euo pipefail

# ---- Config (edit these if needed) ----
SRC="${SRC:-syev_dsyevd_compare.c}"          # source file
OUT="${OUT:-syev_dsyevd_compare}"            # output name (we'll add .exe)
CC="${CC:-gcc}"
FC="${FC:-gfortran}"

# Point this to your OpenBLAS install prefix (contains lib/ and include/)
OPENBLAS_PREFIX="${OPENBLAS_PREFIX:-/d/python_cuda/MATH5005-5006_mingyin/Code/openblas/install}"
OPENBLAS_INC="${OPENBLAS_INC:-$OPENBLAS_PREFIX/include}"
OPENBLAS_LIBDIR="${OPENBLAS_LIBDIR:-$OPENBLAS_PREFIX/lib}"

# Choose link mode: 0 = dynamic (-lopenblas), 1 = static (libopenblas.a + runtimes)
STATIC_LINK="${STATIC_LINK:-0}"

# Optional disassembler: prefer llvm-objdump if available, fall back to objdump
if command -v llvm-objdump >/dev/null 2>&1; then
  OBJDUMP="${OBJDUMP:-llvm-objdump}"
elif command -v objdump >/dev/null 2>&1; then
  OBJDUMP="${OBJDUMP:-objdump}"
else
  OBJDUMP=""
fi

# Default threads (you can override by env OPENBLAS_NUM_THREADS=...)
THREADS="${OPENBLAS_NUM_THREADS:-1}"

echo "==> OPENBLAS_PREFIX: $OPENBLAS_PREFIX"
echo "==> include dir    : $OPENBLAS_INC"
echo "==> lib dir        : $OPENBLAS_LIBDIR"
echo "==> STATIC_LINK    : $STATIC_LINK"

# ---- Prepare output dir ----
echo "==> Creating ../output"
mkdir -p ../output

# ---- Compile ----
echo "==> Compiling: $SRC"
"$CC" -O3 -D_POSIX_C_SOURCE=200112L -I"$OPENBLAS_INC" -c "$SRC" -o "${OUT}.o"

# ---- Link ----
if [ "$STATIC_LINK" = "1" ]; then
  echo "==> Linking (static): libopenblas.a + Fortran/threads runtimes"
  # Note: static link typically needs these extra libs on MinGW
  "$FC" "${OUT}.o" "$OPENBLAS_LIBDIR/libopenblas.a" \
      -lquadmath -lgfortran -lwinpthread -lm -o "${OUT}.exe"
else
  echo "==> Linking (dynamic): -lopenblas"
  "$CC" "${OUT}.o" -L"$OPENBLAS_LIBDIR" -lopenblas -lwinpthread -lm -o "${OUT}.exe"
fi

# ---- Run ----
echo "==> Running with OPENBLAS_NUM_THREADS=$THREADS"
# Ensure DLL is found when dynamically linking (add lib dir to PATH for this process)
if [ "$STATIC_LINK" = "0" ]; then
  PATH="$OPENBLAS_LIBDIR:$PATH" OPENBLAS_NUM_THREADS="$THREADS" ./"${OUT}.exe"
else
  OPENBLAS_NUM_THREADS="$THREADS" ./"${OUT}.exe"
fi

# ---- Optional Disassembly ----
if [ -n "$OBJDUMP" ] && command -v "$OBJDUMP" >/dev/null 2>&1; then
  echo "==> Disassembling: $OBJDUMP -d ${OUT}.exe"
  "$OBJDUMP" -d "${OUT}.exe" > "../output/${OUT}.asm.txt" || true
  echo "    Disassembly saved to ../output/${OUT}.asm.txt"
else
  echo "==> (Skip disassembly: objdump not found)"
fi

echo "==> Done. Results in ../output/"
