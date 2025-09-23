#!/usr/bin/env bash
# Windows build script for OpenBLAS (MSYS2 + MinGW-w64, UCRT64 environment)
# Usage:
#   bash build_openblas_windows.sh

set -euo pipefail

# ========= Configuration =========
SRC_DIR="${SRC_DIR:-OpenBLAS-src}"      # Source directory (git clone if missing)
PREFIX="${PREFIX:-$PWD/install}"        # Install prefix (contains lib/ and include/)
INSTALL_LIB_DIR="$PREFIX/lib"
INSTALL_INC_DIR="$PREFIX/include"

: "${USE_OPENMP:=0}"                    # 0 = pthreads (winpthreads), 1 = OpenMP
: "${STATIC_ONLY:=0}"                   # 1 = static only (NO_SHARED=1)
: "${DYNAMIC_ARCH:=1}"                  # 1 = runtime CPU detection (recommended)
: "${TARGET:=HASWELL}"                  # Target CPU if DYNAMIC_ARCH=0
: "${NO_AVX512:=0}"                     # 1 = disable AVX-512 kernels

# Parallel jobs
if command -v nproc >/dev/null 2>&1; then
  NPROC="$(nproc)"
else
  NPROC=4
fi

echo "==> Prefix        : $PREFIX"
echo "==> lib dir       : $INSTALL_LIB_DIR"
echo "==> include dir   : $INSTALL_INC_DIR"
echo "==> jobs          : $NPROC"
echo "==> DYNAMIC_ARCH  : $DYNAMIC_ARCH"
echo "==> TARGET        : $TARGET"
echo "==> USE_OPENMP    : $USE_OPENMP"
echo "==> STATIC_ONLY   : $STATIC_ONLY"
echo "==> NO_AVX512     : $NO_AVX512"

mkdir -p "$INSTALL_LIB_DIR" "$INSTALL_INC_DIR"

# ========= Toolchain check =========
: "${CC:=gcc}"
: "${FC:=gfortran}"
: "${AR:=ar}"
: "${RANLIB:=ranlib}"
export CC FC AR RANLIB

if ! command -v "$FC" >/dev/null 2>&1; then
  echo "ERROR: gfortran not found."
  echo "Install it in MSYS2 UCRT64 with:"
  echo "  pacman -S --needed mingw-w64-ucrt-x86_64-gcc-fortran"
  exit 1
fi

# ========= Get sources =========
if [ ! -d "$SRC_DIR/.git" ]; then
  echo "==> Cloning OpenBLAS into $SRC_DIR"
  git clone --depth=1 https://github.com/xianyi/OpenBLAS.git "$SRC_DIR"
fi

cd "$SRC_DIR"

# ========= Build options =========
MAKE_OPTS=( "NO_TEST=1" )

if [ "$DYNAMIC_ARCH" = "1" ]; then
  MAKE_OPTS+=( "DYNAMIC_ARCH=1" )
  [ "$NO_AVX512" = "1" ] && MAKE_OPTS+=( "NO_AVX512=1" )
else
  MAKE_OPTS+=( "DYNAMIC_ARCH=0" "TARGET=$TARGET" )
fi

if [ "$USE_OPENMP" = "1" ]; then
  MAKE_OPTS+=( "USE_OPENMP=1" )
else
  MAKE_OPTS+=( "USE_OPENMP=0" )
fi

if [ "$STATIC_ONLY" = "1" ]; then
  MAKE_OPTS+=( "NO_SHARED=1" )
fi

echo "==> make clean (ignore errors if first build)"
make clean || true

echo "==> Building OpenBLAS with: ${MAKE_OPTS[*]}"
make -j"$NPROC" "${MAKE_OPTS[@]}"

echo "==> Installing to $PREFIX"
make PREFIX="$PREFIX" install

# ========= Build summary =========
STATIC_LIB="$INSTALL_LIB_DIR/libopenblas.a"
SHARED_DLL="$INSTALL_LIB_DIR/libopenblas.dll"
IMPORT_LIB="$INSTALL_LIB_DIR/libopenblas.dll.a"
HDR="$INSTALL_INC_DIR/openblas_config.h"

echo
echo "=== Build Summary ==="
[ -f "$STATIC_LIB" ] && echo "  + static : $STATIC_LIB"
[ -f "$SHARED_DLL" ] && echo "  + shared : $SHARED_DLL"
[ -f "$IMPORT_LIB" ] && echo "  + implib : $IMPORT_LIB"
[ -f "$HDR" ]        && echo "  + headers: $HDR"

cat <<'EOF'

=== Usage Notes ===

Linking (MinGW, choose one):

1) Dynamic linking (recommended):
   gcc -O2 your_prog.c -I"./install/include" -L"./install/lib" -lopenblas -lwinpthread -lm -o your_prog.exe

2) Static linking (requires Fortran runtime):
   gcc -O2 your_prog.c "./install/lib/libopenblas.a" -lquadmath -lgfortran -lwinpthread -lm -o your_prog.exe

Control threads at runtime:
   set OPENBLAS_NUM_THREADS=8 && .\your_prog.exe

Check which kernel is used (example program):

#include <stdio.h>
#include <cblas.h>
#include <openblas_config.h>
int main(void){
  printf("OpenBLAS version : %s\n", OPENBLAS_VERSION);
  printf("OpenBLAS config  : %s\n", openblas_get_config());
  printf("OpenBLAS core    : %s\n", openblas_get_corename());
  return 0;
}

Compile test:
   gcc check_openblas.c -I"./install/include" -L"./install/lib" -lopenblas -o check.exe && ./check.exe

EOF
