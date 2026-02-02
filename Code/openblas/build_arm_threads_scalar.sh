#!/usr/bin/env bash
# install_openblas_arm.sh
# Build & install OpenBLAS on AWS Arm/Graviton (or any aarch64 Linux).
# Focus: reproducible builds, profiling-friendly flags, dynamic post-build checks.
#
# Usage:
#   bash install_openblas_arm.sh
#
# Optional env:
#   PREFIX=/opt/openblas        # install prefix (default: /home/ec2-user/MATH5005-5006_mingyin/Code/openblas_scalar)
#   USE_OPENMP=0                # 0=pthreads backend, 1=OpenMP backend
#   STATIC_ONLY=0               # 1=build static only (.a)
#   DYNAMIC_ARCH=0              # 1=build fat binary (multi-arch); slower build & larger .so
#   TARGET=ARMV8                # scalar build: use ARMV8 + ONLY_C=1 (no NEON/SIMD)
#   WITH_DEBUG=1                # 1=keep symbols & frame pointers (perf/FlameGraph friendly)
#   NUM_THREADS=4               # compile-time max threads (cap)
#   CLEAN_LEVEL=0               # 0=make clean, 1=make distclean, 2=git clean -xdf (deep)
#   RECLONE=0                   # 1=rm -rf SRC_DIR and fresh clone
#   SKIP_BUILD=0                # 1=only clean, skip build (useful for purge)
#   SKIP_DEPS=0                 # 1=skip deps install (no sudo)
#   SRC_DIR=OpenBLAS-src        # git clone target directory

set -euo pipefail

# ========= Config =========
SRC_DIR="${SRC_DIR:-OpenBLAS-src}"                 # Git source dir
PREFIX="${PREFIX:-/home/ec2-user/MATH5005-5006_mingyin/Code/openblas_scalar}" # Install prefix
INSTALL_LIB_DIR="$PREFIX/lib"
INSTALL_INC_DIR="$PREFIX/include"

: "${USE_OPENMP:=0}"                               # 0=pthreads, 1=OpenMP
: "${STATIC_ONLY:=0}"                              # 1=build static only
: "${DYNAMIC_ARCH:=0}"                             # 1=multiple-arch fat binary
: "${TARGET:=ARMV8}"                               # scalar: ARMV8 + ONLY_C=1, no NEON
: "${WITH_DEBUG:=1}"                               # 1=keep symbols for perf
: "${NUM_THREADS:=4}"                              # compile-time thread cap
: "${CLEAN_LEVEL:=0}"                              # 0 clean, 1 distclean, 2 git clean -xdf
: "${RECLONE:=0}"                                  # 1 fresh clone
: "${SKIP_BUILD:=0}"                               # 1 only clean, skip build
: "${SKIP_DEPS:=0}"                                # 1 skip deps install

if command -v nproc >/dev/null 2>&1; then JOBS="$(nproc)"; else JOBS=4; fi

echo "==> PREFIX         : $PREFIX"
echo "==> USE_OPENMP     : $USE_OPENMP"
echo "==> STATIC_ONLY    : $STATIC_ONLY"
echo "==> DYNAMIC_ARCH   : $DYNAMIC_ARCH"
echo "==> TARGET(opt)    : $TARGET (scalar: ARMV8 + ONLY_C=1)"
echo "==> NUM_THREADS    : $NUM_THREADS (compile-time cap)"
echo "==> WITH_DEBUG     : $WITH_DEBUG  (adds -g -fno-omit-frame-pointer; disable strip)"
echo "==> CLEAN_LEVEL    : $CLEAN_LEVEL (0=clean, 1=distclean, 2=git clean -xdf)"
echo "==> RECLONE        : $RECLONE"
echo "==> SKIP_BUILD     : $SKIP_BUILD"
echo "==> JOBS           : $JOBS"
echo

mkdir -p "$INSTALL_LIB_DIR" "$INSTALL_INC_DIR"

# ========= Deps =========
install_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "==> Detected Debian/Ubuntu (apt). Installing deps..."
    sudo apt-get update -y
    sudo apt-get install -y build-essential gfortran git binutils
  elif command -v dnf >/dev/null 2>&1; then
    echo "==> Detected RHEL/Amazon Linux (dnf). Installing deps..."
    sudo dnf -y groupinstall "Development Tools"
    sudo dnf -y install gcc-gfortran git binutils
  else
    echo "ERROR: Unknown distro. Please install: C compiler, gfortran, git, binutils" >&2
    exit 1
  fi
}
if [[ "$SKIP_DEPS" == "1" ]]; then
  echo "==> SKIP_DEPS=1: skipping dependency install"
else
  install_deps
fi

# ========= CPU info =========
print_cpu_info() {
  echo "==> CPU Info (lscpu):"; lscpu || true; echo
  echo "==> /proc/cpuinfo (first 20 lines):"; head -n 20 /proc/cpuinfo || true; echo
}
print_cpu_info

echo "==> Final TARGET   : $TARGET"
echo

# ========= Source =========
if [[ "$RECLONE" == "1" ]]; then
  echo "==> RECLONE=1: removing $SRC_DIR and cloning fresh..."
  rm -rf "$SRC_DIR"
fi

if [[ ! -d "$SRC_DIR/.git" ]]; then
  echo "==> Cloning OpenBLAS source into: $SRC_DIR"
  # Official mirror under OpenMathLib org
  git clone --depth=1 https://github.com/OpenMathLib/OpenBLAS.git "$SRC_DIR"
fi

cd "$SRC_DIR"

# ========= Clean levels =========
case "$CLEAN_LEVEL" in
  0)
    echo "==> make clean"
    make clean || true
    ;;
  1)
    echo "==> make distclean"
    make distclean || true
    ;;
  2)
    echo "==> Deep clean (git reset --hard && git clean -xdf)"
    git reset --hard
    git clean -xdf
    ;;
  *)
    echo "ERROR: CLEAN_LEVEL must be 0|1|2" >&2
    exit 1
    ;;
esac

if [[ "$SKIP_BUILD" == "1" ]]; then
  echo "==> SKIP_BUILD=1: Clean done. Exiting."
  exit 0
fi

# ========= Build =========
: "${CC:=gcc}"; : "${FC:=gfortran}"; : "${AR:=ar}"; : "${RANLIB:=ranlib}"
export CC FC AR RANLIB

# Scalar build: ONLY_C=1 = C kernels only (no ARM/NEON assembly); -fno-tree-vectorize = no auto-vectorization
MAKE_OPTS=( "NO_AFFINITY=1" "NO_TEST=1" "TARGET=$TARGET" "NUM_THREADS=$NUM_THREADS" "ONLY_C=1" )
MAKE_OPTS+=( 'CFLAGS+=-fno-tree-vectorize' )
MAKE_OPTS+=( 'FCFLAGS+=-fno-tree-vectorize' )
[[ "$DYNAMIC_ARCH" == "1" ]] && MAKE_OPTS+=( "DYNAMIC_ARCH=1" )
[[ "$USE_OPENMP" == "1" ]] && MAKE_OPTS+=( "USE_OPENMP=1" ) || MAKE_OPTS+=( "USE_OPENMP=0" )
[[ "$STATIC_ONLY" == "1" ]] && MAKE_OPTS+=( "NO_SHARED=1" )

# Keep O3, add debug info & frame pointers for better perf/dwarf unwind
if [[ "$WITH_DEBUG" == "1" ]]; then
  MAKE_OPTS+=( 'CFLAGS+=-g -fno-omit-frame-pointer' )
  MAKE_OPTS+=( 'FCFLAGS+=-g -fno-omit-frame-pointer' )
  # prevent install from stripping symbols
  MAKE_OPTS+=( 'STRIP=true' )
fi

echo "==> Build options : ${MAKE_OPTS[*]}"
make -j"$JOBS" "${MAKE_OPTS[@]}"

echo "==> Installing to $PREFIX"
make PREFIX="$PREFIX" install

# ========= Post-build checks =========
STATIC_LIB="$INSTALL_LIB_DIR/libopenblas.a"
SHARED_SO="$INSTALL_LIB_DIR/libopenblas.so"
HDR="$INSTALL_INC_DIR/openblas_config.h"

echo
echo "=== Build Summary ==="
[[ -f "$STATIC_LIB" ]] && echo "  + static : $STATIC_LIB"
[[ -f "$SHARED_SO"  ]] && echo "  + shared : $SHARED_SO"
[[ -f "$HDR"        ]] && echo "  + headers: $HDR"
echo

# Small checker (prints version/config/core and thread caps)
cat > /tmp/check_openblas.c <<'EOF'
#include <stdio.h>
#include <cblas.h>
#include <openblas_config.h>
#ifndef SET_THR
#define SET_THR 4
#endif
int main(void){
  printf("OpenBLAS version : %s\n", OPENBLAS_VERSION);
  printf("OpenBLAS config  : %s\n", openblas_get_config());
  printf("OpenBLAS core    : %s\n", openblas_get_corename());
#ifdef OPENBLAS_NUM_THREADS
  printf("OpenBLAS max(th) : %d (compile-time)\n", OPENBLAS_NUM_THREADS);
#else
  printf("OpenBLAS max(th) : (macro not present in header)\n");
#endif
  openblas_set_num_threads(SET_THR);
  printf("OpenBLAS now(th) : %d (after set=%d)\n", openblas_get_num_threads(), SET_THR);
  return 0;
}
EOF

echo "==> Compiling and running configuration checker..."
# Choose a sensible runtime set value: min(NUM_THREADS, nproc)
if command -v nproc >/dev/null 2>&1; then
  SYS_THREADS="$(nproc)"
else
  SYS_THREADS=4
fi
SET_THR="$NUM_THREADS"
if [[ "$SYS_THREADS" -lt "$SET_THR" ]]; then SET_THR="$SYS_THREADS"; fi
CHECK_BIN=/tmp/check_openblas
gcc /tmp/check_openblas.c -DSET_THR="$SET_THR" \
  -I"$INSTALL_INC_DIR" -L"$INSTALL_LIB_DIR" -lopenblas -lm -o "$CHECK_BIN"

echo "==> OpenBLAS self-check:"
CHECK_OUT="$(LD_LIBRARY_PATH="$INSTALL_LIB_DIR:${LD_LIBRARY_PATH:-}" "$CHECK_BIN" 2>&1)"
echo "$CHECK_OUT"
echo

# Parse MAX_THREADS from config string if present
DETECTED_MAX="$(printf '%s\n' "$CHECK_OUT" | grep -Eo 'MAX_THREADS=[0-9]+' | head -n1 | cut -d= -f2 || true)"
# Parse runtime threads after set
DETECTED_RUN="$(printf '%s\n' "$CHECK_OUT" | grep -Eo 'now\(th\) : [0-9]+' | awk '{print $3}' | head -n1 || true)"
# Fallback compile-time cap from header print
if [[ -z "$DETECTED_MAX" ]]; then
  DETECTED_MAX="$(printf '%s\n' "$CHECK_OUT" | grep -Eo 'max\(th\) : [0-9]+' | awk '{print $3}' | head -n1 || true)"
fi

# Backend-driven runtime variable name
if [[ "$USE_OPENMP" == "1" ]]; then
  RUNTIME_VAR="OMP_NUM_THREADS"
  BACKEND="OpenMP"
else
  RUNTIME_VAR="OPENBLAS_NUM_THREADS"
  BACKEND="Pthreads"
fi

# Recommended runtime threads: min(NUM_THREADS, nproc)
rec_threads="$NUM_THREADS"
if [[ "$SYS_THREADS" -lt "$rec_threads" ]]; then
  rec_threads="$SYS_THREADS"
fi
(( rec_threads < 1 )) && rec_threads=1

echo "=== Validation ==="
if [[ -n "$DETECTED_MAX" ]]; then
  if [[ "$DETECTED_MAX" -eq "$NUM_THREADS" ]]; then
    echo "  ✓ Detected MAX_THREADS=$DETECTED_MAX matches requested NUM_THREADS=$NUM_THREADS"
  else
    echo "  ⚠ Detected MAX_THREADS=$DETECTED_MAX, but you requested NUM_THREADS=$NUM_THREADS"
    echo "    -> Likely linked an old library or stale build artifacts:"
    echo "       1) Check link path:   ldd $CHECK_BIN | grep -i openblas"
    echo "       2) Inspect the .so:   strings \"$INSTALL_LIB_DIR/libopenblas.so\" | grep -i MAX_THREADS"
    echo "       3) If mismatched:     set RECLONE=1 or CLEAN_LEVEL=2 and rebuild, ensure LD_LIBRARY_PATH uses the new lib"
  fi
else
  echo "  ℹ Could not parse MAX_THREADS from output (some builds omit this tag)."
  echo "    You can still run: strings \"$INSTALL_LIB_DIR/libopenblas.so\" | grep -i NUM_THREADS"
fi

if [[ -n "$DETECTED_RUN" ]]; then
  echo "  ℹ Observed runtime threads after set: $DETECTED_RUN"
fi
echo

# Dynamic Tips
echo "==> Done."
echo "Tips (auto-generated):"
echo "  • Build-time cap         : NUM_THREADS=$NUM_THREADS"
[[ -n "$DETECTED_MAX" ]] && echo "  • Detected in library    : MAX_THREADS=$DETECTED_MAX"
echo "  • Backend                : $BACKEND"
echo "  • Runtime var to set     : $RUNTIME_VAR"
echo "  • Suggested runtime      : export $RUNTIME_VAR=$rec_threads   # min(NUM_THREADS=$NUM_THREADS, nproc=$SYS_THREADS)"
echo "  • Useful toggles         : WITH_DEBUG=$WITH_DEBUG, STATIC_ONLY=$STATIC_ONLY, DYNAMIC_ARCH=$DYNAMIC_ARCH, TARGET=$TARGET"
echo

# Optional: quick SVE opcode peek (first match)
if [[ -f "$SHARED_SO" ]]; then
  echo "==> Library signature peek:"
  if command -v strings >/dev/null 2>&1; then
    strings "$SHARED_SO" | grep -E -m1 'OpenBLAS|NUM_THREADS|MAX_THREADS' || true
  fi
  echo
  echo "==> Quick SVE scan in libopenblas.so (first match):"
  if command -v objdump >/dev/null 2>&1; then
    objdump -dC "$SHARED_SO" | grep -E -m1 '\bz([0-9]|[12][0-9]|3[01])\b|\bp([0-9]|[12][0-9]|3[01])\b|ptrue|whilelt|movprfx' \
      && echo "Found SVE-like ops." || echo "No obvious SVE ops found (not all kernels use SVE)."
  elif command -v llvm-objdump >/dev/null 2>&1; then
    llvm-objdump -d "$SHARED_SO" | grep -E -m1 '\bz([0-9]|[12][0-9]|3[01])\b|\bp([0-9]|[12][0-9]|3[01])\b|ptrue|whilelt|movprfx' \
      && echo "Found SVE-like ops." || echo "No obvious SVE ops found (not all kernels use SVE)."
  else
    echo "objdump not found; skipping opcode scan."
  fi
  echo
fi
