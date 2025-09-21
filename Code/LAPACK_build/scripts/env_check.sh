#!/usr/bin/env bash
# Quick sanity check for toolchain availability.

set -e

echo "== Tool versions =="
command -v clang      && clang --version      || echo "clang not found"
command -v gfortran   && gfortran --version   || echo "gfortran not found"
command -v cmake      && cmake --version      || echo "cmake not found"
command -v ninja      && ninja --version      || echo "ninja not found (ok if you use Unix Makefiles)"

echo
echo "== CMake compiler probe =="
cmake -P - <<'CMAKE_EOF'
message(STATUS "CMAKE_C_COMPILER      = ${CMAKE_C_COMPILER}")
message(STATUS "CMAKE_CXX_COMPILER    = ${CMAKE_CXX_COMPILER}")
message(STATUS "CMAKE_Fortran_COMPILER= ${CMAKE_Fortran_COMPILER}")
CMAKE_EOF

echo
echo "Tip (macOS): install Fortran via Homebrew ->  brew install gcc"
