#!/usr/bin/env bash
set -euo pipefail

# Minimal builder for eig_bench.c
# - Only depends on local OpenBLAS
# - No wraps, no netlib/armpl
# - Program internally sets threads = {1,2,4} and N=8000

# ===== 0) User-configurable: where is your OpenBLAS installed? =====
# Example: OB_PREFIX=/home/ec2-user/MATH5005-5006_mingyin/Code/openblas/openblas_install
OB_PREFIX="${OB_PREFIX:-../../openblas/openblas_install}"

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
SRC_DIR="../src"
SRC_MAIN="${SRC_DIR}/main.c"   # <-- use the simplified benchmark source
OUT_DIR="../output"
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
