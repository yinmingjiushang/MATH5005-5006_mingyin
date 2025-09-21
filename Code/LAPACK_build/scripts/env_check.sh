#!/usr/bin/env bash
# Robust toolchain sanity check that actually configures a tiny CMake project
# using scripts/toolchain.cmake so compilers are detected properly.

set -euo pipefail

echo "== Tool versions =="
command -v clang      && clang --version      || echo "clang not found"
command -v gfortran   && gfortran --version   || echo "gfortran not found"
command -v cmake      && cmake --version      || echo "cmake not found"
command -v ninja      && ninja --version      || echo "ninja not found (ok if you use Unix Makefiles)"

# Resolve repo root and toolchain
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLCHAIN="$ROOT_DIR/scripts/toolchain.cmake"

echo
echo "== Probing compilers via a minimal CMake configure =="
TMP_SRC="$(mktemp -d -t cm_probe_src.XXXX)"
TMP_BIN="$(mktemp -d -t cm_probe_bin.XXXX)"

# Create a minimal CMakeLists that requests C/CXX/Fortran and prints compilers
cat > "$TMP_SRC/CMakeLists.txt" <<'CMAKE_EOF'
cmake_minimum_required(VERSION 3.18)
project(Probe C CXX Fortran)
message(STATUS "CMAKE_C_COMPILER      = ${CMAKE_C_COMPILER}")
message(STATUS "CMAKE_CXX_COMPILER    = ${CMAKE_CXX_COMPILER}")
message(STATUS "CMAKE_Fortran_COMPILER= ${CMAKE_Fortran_COMPILER}")
CMAKE_EOF

# Prefer Ninja; fall back to Unix Makefiles if Ninja missing
GEN="Ninja"
if ! command -v ninja >/dev/null 2>&1; then GEN="Unix Makefiles"; fi

cmake -S "$TMP_SRC" -B "$TMP_BIN" \
  -G "${GEN}" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE=Release

# Clean up temp dirs
rm -rf "$TMP_SRC" "$TMP_BIN"

echo
echo "Tip (macOS): if gfortran shows empty above, set absolute path in toolchain.cmake, e.g."
echo '  set(CMAKE_Fortran_COMPILER /opt/homebrew/bin/gfortran)'
