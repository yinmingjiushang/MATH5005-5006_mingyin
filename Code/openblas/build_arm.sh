#!/usr/bin/env bash
# install_openblas_arm.sh
# Build & install OpenBLAS on AWS Arm (Graviton). Optimized for perf profiling.
# Usage:
#   bash install_openblas_arm.sh
# Optional env:
#   PREFIX=/opt/openblas USE_OPENMP=0 STATIC_ONLY=0 DYNAMIC_ARCH=0 TARGET=auto WITH_DEBUG=1

set -euo pipefail

# ========= Config =========
SRC_DIR="${SRC_DIR:-OpenBLAS-src}"                 # Git source dir
PREFIX="${PREFIX:-$PWD/openblas_install}"          # Install prefix
INSTALL_LIB_DIR="$PREFIX/lib"
INSTALL_INC_DIR="$PREFIX/include"

: "${USE_OPENMP:=0}"                               # 0=pthreads, 1=OpenMP
: "${STATIC_ONLY:=0}"                              # 1=build static only
: "${DYNAMIC_ARCH:=0}"                             # 1=multiple-arch fat binary
: "${TARGET:=auto}"                                # auto=detect NEOVERSEN1/NEOVERSEV1/NEOVERSEN2
: "${WITH_DEBUG:=1}"                               # 1=keep symbols for perf/dwarf

if command -v nproc >/dev/null 2>&1; then JOBS="$(nproc)"; else JOBS=4; fi

echo "==> PREFIX         : $PREFIX"
echo "==> USE_OPENMP     : $USE_OPENMP"
echo "==> STATIC_ONLY    : $STATIC_ONLY"
echo "==> DYNAMIC_ARCH   : $DYNAMIC_ARCH"
echo "==> TARGET(opt)    : $TARGET"
echo "==> WITH_DEBUG     : $WITH_DEBUG  (adds -g -fno-omit-frame-pointer; disable strip)"
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
install_deps

# ========= CPU info & target detect =========
print_cpu_info() {
  echo "==> CPU Info (lscpu):"; lscpu || true; echo
  echo "==> /proc/cpuinfo (first 20 lines):"; head -n 20 /proc/cpuinfo || true; echo
}
print_cpu_info

detect_target() {
  local model features has_sve="no"
  model="$(lscpu | awk -F: '/Model name/ {print $2}' | sed 's/^ *//')"
  features="$(lscpu | awk -F: '/Flags|Features/ {print $2}' | tr '[:upper:]' '[:lower:]')"
  [[ "$features" =~ (^|[[:space:]])sve([[:space:]]|$) ]] && has_sve="yes"

  >&2 echo "==> Detected model : ${model:-unknown}"
  >&2 echo "==> Feature flags  : SVE=$has_sve"

  if [[ "$has_sve" == "yes" ]]; then
    if echo "$model" | grep -qi 'v2'; then echo "NEOVERSEN2"; return; fi
    if echo "$model" | grep -qi 'v1'; then echo "NEOVERSEV1"; return; fi
    echo "NEOVERSEV1"
  else
    echo "NEOVERSEN1"
  fi
}
if [[ "$TARGET" == "auto" ]]; then TARGET="$(detect_target)"; fi
echo "==> Final TARGET   : $TARGET"
echo

# ========= Get OpenBLAS source =========
if [[ ! -d "$SRC_DIR/.git" ]]; then
  echo "==> Cloning OpenBLAS source into: $SRC_DIR"
  # Official mirror moved under OpenMathLib org
  git clone --depth=1 https://github.com/OpenMathLib/OpenBLAS.git "$SRC_DIR"
fi

# ========= Build =========
: "${CC:=gcc}"; : "${FC:=gfortran}"; : "${AR:=ar}"; : "${RANLIB:=ranlib}"
export CC FC AR RANLIB

cd "$SRC_DIR"
echo "==> make clean"; make clean || true

# Base make options
MAKE_OPTS=( "NO_AFFINITY=1" "NO_TEST=1" "TARGET=$TARGET" )
[[ "$DYNAMIC_ARCH" == "1" ]] && MAKE_OPTS+=( "DYNAMIC_ARCH=1" )
[[ "$USE_OPENMP" == "1" ]] && MAKE_OPTS+=( "USE_OPENMP=1" ) || MAKE_OPTS+=( "USE_OPENMP=0" )
[[ "$STATIC_ONLY" == "1" ]] && MAKE_OPTS+=( "NO_SHARED=1" )

# Keep O3 but add debug info & frame pointers for better perf/dwarf unwind
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

# Small checker (prints version/config/core)
cat > /tmp/check_openblas.c <<'EOF'
#include <stdio.h>
#include <cblas.h>
#include <openblas_config.h>
int main(void){
  printf("OpenBLAS version : %s\n", OPENBLAS_VERSION);
  printf("OpenBLAS config  : %s\n", openblas_get_config());
  printf("OpenBLAS core    : %s\n", openblas_get_corename());
  return 0;
}
EOF

echo "==> Compiling and running configuration checker..."
gcc /tmp/check_openblas.c -I"$INSTALL_INC_DIR" -L"$INSTALL_LIB_DIR" -lopenblas -lm -o /tmp/check_openblas
LD_LIBRARY_PATH="$INSTALL_LIB_DIR:${LD_LIBRARY_PATH:-}" /tmp/check_openblas || true
echo

# Optional: quick SVE opcode probe in shared lib (if present)
if [[ -f "$SHARED_SO" ]]; then
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

echo "==> Done."
echo "Tips:"
echo "  WITH_DEBUG=1            # keep symbols for perf (default)"
echo "  STATIC_ONLY=1           # build static .a only"
echo "  DYNAMIC_ARCH=1          # build fat binary (slower compile, bigger lib)"
echo "  TARGET=NEOVERSEV1       # override auto detect if需要"
echo "  export OPENBLAS_NUM_THREADS=8   # control threads"
echo "  export OMP_NUM_THREADS=8        # if USE_OPENMP=1"
