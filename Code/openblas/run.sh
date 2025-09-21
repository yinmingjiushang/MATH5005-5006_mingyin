#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
SRC_DIR="${SRC_DIR:-OpenBLAS-src}"       # Where to put sources (will clone if missing)
PREFIX="$(pwd)"                          # Install into ./lib and ./include here
INSTALL_LIB_DIR="$PREFIX/lib"
INSTALL_INC_DIR="$PREFIX/include"

: "${USE_OPENMP:=0}"                     # 0=pthreads (default), 1=OpenMP
: "${STATIC_ONLY:=0}"                    # 1 = build static only (NO_SHARED=1)
: "${TARGET:=ARMV8}"                     # Default architecture target

# Add Homebrew gfortran lib path automatically if available
if [ -d "/opt/homebrew/lib/gcc/current" ]; then
  export LDFLAGS="-L/opt/homebrew/lib/gcc/current ${LDFLAGS:-}"
fi

# Parallel jobs
if command -v sysctl >/dev/null 2>&1; then
  NPROC="$(sysctl -n hw.physicalcpu 2>/dev/null || echo 4)"
elif command -v getconf >/dev/null 2>&1; then
  NPROC="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
else
  NPROC=4
fi

echo "==> Install prefix: $PREFIX"
echo "==> lib dir       : $INSTALL_LIB_DIR"
echo "==> include dir   : $INSTALL_INC_DIR"
echo "==> jobs          : $NPROC"
echo "==> TARGET        : $TARGET"
echo "==> USE_OPENMP    : $USE_OPENMP"
echo "==> STATIC_ONLY   : $STATIC_ONLY"
echo "==> LDFLAGS       : ${LDFLAGS:-<none>}"

mkdir -p "$INSTALL_LIB_DIR" "$INSTALL_INC_DIR"

# Ensure gfortran exists
if ! command -v gfortran >/dev/null 2>&1; then
  echo "ERROR: gfortran not found. Please install it first (brew install gcc)." >&2
  exit 1
fi

# Fetch sources if missing
if [ ! -d "$SRC_DIR/.git" ]; then
  echo "==> Cloning OpenBLAS into $SRC_DIR"
  git clone --depth=1 https://github.com/xianyi/OpenBLAS.git "$SRC_DIR"
fi

cd "$SRC_DIR"

# Compose make options
MAKE_OPTS=( "TARGET=$TARGET" "NO_TEST=1" ) # Skip tests by default
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

# Summary
STATIC_LIB="$INSTALL_LIB_DIR/libopenblas.a"
if [[ "$OSTYPE" == "darwin"* ]]; then
  SHARED_LIB="$INSTALL_LIB_DIR/libopenblas.dylib"
else
  SHARED_LIB="$INSTALL_LIB_DIR/libopenblas.so"
fi

echo
echo "=== Build Summary ==="
[ -f "$STATIC_LIB" ] && echo "  + static : $STATIC_LIB"
[ -f "$SHARED_LIB" ] && echo "  + shared : $SHARED_LIB"
echo "  + headers: $INSTALL_INC_DIR/openblas_config.h"
echo
echo "Linking example:"
echo "  cc -O2 -D_POSIX_C_SOURCE=200112L your_prog.c \"$STATIC_LIB\" -lm -o your_prog"
echo "Or:"
echo "  cc -O2 -D_POSIX_C_SOURCE=200112L -c your_prog.c -o your_prog.o"
echo "  gfortran your_prog.o \"$STATIC_LIB\" -lm -o your_prog"
echo
echo "Run with threads:"
echo "  OPENBLAS_NUM_THREADS=$(printf %s "$NPROC") ./your_prog"
