# ------------------------------------
# scripts/toolchain.cmake
# Centralized compiler configuration.
# Edit paths if your compilers are not on PATH.
# ------------------------------------

# C/C++: use gcc for consistency with OpenBLAS builds
set(CMAKE_C_COMPILER   gcc)
set(CMAKE_CXX_COMPILER g++)

# Fortran compiler is required for LAPACK.
# On macOS: `brew install gcc` provides gfortran.
set(CMAKE_Fortran_COMPILER gfortran)

# Reasonable defaults; tweak as you like.
set(CMAKE_C_FLAGS_RELEASE           "-O3 -mcpu=native -mtune=native -ffp-contract=fast")
set(CMAKE_CXX_FLAGS_RELEASE         "-O3 -mcpu=native -mtune=native -ffp-contract=fast")
set(CMAKE_Fortran_FLAGS_RELEASE     "-O3 -mcpu=native -mtune=native -ffp-contract=fast")

set(CMAKE_C_FLAGS_DEBUG             "-O0 -g -fno-omit-frame-pointer")
set(CMAKE_CXX_FLAGS_DEBUG           "-O0 -g -fno-omit-frame-pointer")
set(CMAKE_Fortran_FLAGS_DEBUG       "-O0 -g -fno-omit-frame-pointer")
