# lapack_build

Build **Reference LAPACK** from source as static libraries
(`liblapack.a`, `libblas.a`) for downstream experiments (C drivers,
disassembly, performance tests).

## Prerequisites

- CMake ≥ 3.18
- A C compiler (`clang` or `gcc`)
- **Fortran compiler** (`gfortran`)
- Optional: Ninja (faster builds)

**macOS (Homebrew):**
```bash
brew install cmake gcc ninja
# gfortran comes with Homebrew's gcc




make check          # optional: verify toolchain
make                # fetch + configure + build (Release, static)
# optional:
make install        # installs into ./install
