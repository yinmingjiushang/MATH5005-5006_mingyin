#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
find_code_dir() {
  local dir="$SCRIPT_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/third_party" && -d "$dir/chapter4" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}
CODE_DIR="$(find_code_dir)" || { echo "Failed to locate Code root from $SCRIPT_DIR" >&2; exit 1; }
THIRD_PARTY_DIR="$CODE_DIR/third_party"

# Minimal builder for eig_bench.c
# - Only depends on local OpenBLAS
# - No wraps, no netlib/armpl
# - Program internally sets threads = {1,2,4} and N=8000

# ===== 0) User-configurable: where is your OpenBLAS installed? =====
# Example: OB_PREFIX=/path/to/repo/Code/third_party/openblas_sve
OB_PREFIX="${OB_PREFIX:-$THIRD_PARTY_DIR/openblas_sve}"

# ===== 1) Compiler & flags =====
CC="${CC:-gcc}"
CFLAGS_BASE="-O3 -std=c11 -D_POSIX_C_SOURCE=200112L -mcpu=native -mtune=native \
  -fno-math-errno -fno-trapping-math -ffp-contract=fast"
CFLAGS="$CFLAGS_BASE -I${OB_PREFIX}/include"

# Link against OpenBLAS (prefer shared if present; fallback to static)
LIB_DIR="${OB_PREFIX}/lib"
LIBS_FORTRAN="-lgfortran"
LIBS_SYS="-lpthread -ldl -lm"

if [[ -f "${LIB_DIR}/libopenblas.so" ]]; then
  LDFLAGS="-L${LIB_DIR} -Wl,-rpath,${LIB_DIR} -lopenblas ${LIBS_FORTRAN} ${LIBS_SYS}"
  USE_LIB="${LIB_DIR}/libopenblas.so"
elif [[ -f "${LIB_DIR}/libopenblas.a" ]]; then
  LDFLAGS="${LIB_DIR}/libopenblas.a ${LIBS_FORTRAN} ${LIBS_SYS}"
  USE_LIB="${LIB_DIR}/libopenblas.a"
else
  echo "[X] Could not find libopenblas.{so,a} under ${LIB_DIR}"
  echo "    Set OB_PREFIX to your OpenBLAS prefix, e.g.:"
  echo "    OB_PREFIX=/path/to/openblas_install ./build_run.sh"
  exit 1
fi

# ===== 2) Sources & output =====
SRC_DIR="$SCRIPT_DIR/../src"
SRC_MAIN="${SRC_DIR}/main.c"   # <-- use the simplified benchmark source
OUT_DIR="$SCRIPT_DIR/../output"
OBJ_DIR="${OUT_DIR}/obj"
BIN_DIR="${OUT_DIR}/bin"
BIN="${BIN_DIR}/main"

mkdir -p "${OBJ_DIR}" "${BIN_DIR}"

# ===== 3) Build =====
echo "[BUILD] CC=${CC}"
echo "[INFO ] OB_PREFIX=${OB_PREFIX}"
echo "[INFO ] Using OpenBLAS: ${USE_LIB}"
echo "[INFO ] CFLAGS=${CFLAGS}"
echo "[INFO ] LDFLAGS=${LDFLAGS}"

OBJ="${OBJ_DIR}/$(basename "${SRC_MAIN}" .c).o"
echo "[CC   ] ${SRC_MAIN} -> ${OBJ}"
${CC} ${CFLAGS} -c "${SRC_MAIN}" -o "${OBJ}"

echo "[LINK ] ${OBJ} -> ${BIN}"
${CC} "${OBJ}" ${LDFLAGS} -o "${BIN}"

# ===== 4) Run (unset env threads to avoid noise; program sets {1,2,4}) =====
unset OMP_NUM_THREADS || true
unset OPENBLAS_NUM_THREADS || true
unset ARMPL_NUM_THREADS || true

echo "[RUN  ] ${BIN}"
exec "${BIN}"
