#!/usr/bin/env bash
# disasm.sh — Build dsyevd test (linking static OpenBLAS) and dump disassembly.
# All default paths are resolved relative to THIS SCRIPT, not $PWD.
# No absolute paths required; supports OPENBLAS_A override.

set -euo pipefail

# -------------------- Resolve paths relative to script --------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"

# User-overridable (all default to locations relative to SCRIPT_DIR)
OPENBLAS_PREFIX="${OPENBLAS_PREFIX:-$SCRIPT_DIR/../../openblas/openblas_install}"
OPENBLAS_LIBDIR="$OPENBLAS_PREFIX/lib"
OPENBLAS_INCDIR="$OPENBLAS_PREFIX/include"

# Source & outputs
SRC="${1:-$SCRIPT_DIR/../src/dsyevd.c}"
BIN="${SRC%.*}"                      # output next to SRC (kept from your layout)
OUT_DIR="${OUT_DIR:-$SCRIPT_DIR/output}"
ASM_DIR="$OUT_DIR/asm"
LIB_TMP="$OUT_DIR/lib_extract"

# Keys to search in the OpenBLAS archive
KEYS="${KEYS:-dsyevd dstevd dstedc dlaed0 dlaed1 dlaed2 dlaed3 dlaed4 dlaed5 dlaed6 dlaed7 dlaed8 dlaed9 dlaeda dlamrg}"

# Single-thread only
export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-1}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"
export ARMPL_NUM_THREADS="${ARMPL_NUM_THREADS:-1}"

# Allow overriding the static archive path (in case of suffixed names)
OBLAS_A="${OPENBLAS_A:-$OPENBLAS_LIBDIR/libopenblas.a}"

# -------------------- Sanity checks --------------------
[[ -f "$SRC"     ]] || { echo "[Error] Source file not found: $SRC"; exit 3; }
[[ -f "$OBLAS_A" ]] || { echo "[Error] Not found: $OBLAS_A"; exit 2; }
[[ -r "$OBLAS_A" ]] || { echo "[Error] No read permission: $OBLAS_A"; exit 2; }

mkdir -p "$OUT_DIR" "$ASM_DIR" "$LIB_TMP"

# -------------------- Choose objdump --------------------
if command -v llvm-objdump >/dev/null 2>&1; then
  OBJDUMP="llvm-objdump"
  ODFLAGS="-d --no-show-raw-insn --symbolize-operands --print-imm-hex"
else
  OBJDUMP="objdump"
  ODFLAGS="-d -C"
fi

# -------------------- Build --------------------
echo "[Build] Compiling -> $BIN"
gcc -O3 -g -mcpu=native -fno-pie -no-pie -I"$OPENBLAS_INCDIR" "$SRC" \
    "$OBLAS_A" -lm -ldl -lpthread -lgfortran \
    -o "$BIN"
echo "[OK] Built: $BIN"

# -------------------- Disassemble final binary --------------------
BIN_ASM="$ASM_DIR/$(basename "$BIN").asm"
echo "[Disasm] Dumping binary to $BIN_ASM using $OBJDUMP"
$OBJDUMP $ODFLAGS "$BIN" > "$BIN_ASM" || true

# -------------------- nm symbol table --------------------
NM_TXT="$ASM_DIR/$(basename "$BIN").nm.txt"
if command -v nm >/dev/null 2>&1; then
  nm -A -C --defined-only "$BIN" > "$NM_TXT" || true
  echo "[Info] Wrote symbol table: $NM_TXT"
fi

# -------------------- Prepare archive path relative to LIB_TMP --------------------
echo "[Extract] Searching objects in archive matching keys: $KEYS"
REL_ARCHIVE=""
if command -v python3 >/dev/null 2>&1; then
  REL_ARCHIVE="$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' \
                 "$OBLAS_A" "$LIB_TMP")"
else
  # Fallback (no absolute paths): copy once into LIB_TMP
  cp -f "$OBLAS_A" "$LIB_TMP/__openblas_archive.a"
  REL_ARCHIVE="__openblas_archive.a"
fi
[[ -n "$REL_ARCHIVE" ]] || { echo "[Error] REL_ARCHIVE empty"; exit 2; }

# -------------------- Extract & disassemble matched objects --------------------
pushd "$LIB_TMP" >/dev/null

# List archive members (relative)
if ! ar t "$REL_ARCHIVE" > all_objs.txt 2>ar_err.log; then
  echo "[Error] ar failed on archive: $REL_ARCHIVE"
  sed -n '1,5p' ar_err.log
  popd >/dev/null
  exit 2
fi

# Grep by keys (case-insensitive), unique
MATCHED=()
while read -r key; do
  [[ -z "$key" ]] && continue
  while IFS= read -r obj; do
    [[ -n "$obj" ]] && MATCHED+=("$obj")
  done < <(grep -i -- "$key" all_objs.txt || true)
done < <(printf "%s\n" $KEYS)

readarray -t UNIQUE < <(printf "%s\n" "${MATCHED[@]:-}" | awk 'NF && !seen[$0]++')

if [[ ${#UNIQUE[@]} -eq 0 ]]; then
  echo "[Warn] No matching objects found in archive for keys."
else
  echo "[Info] Found ${#UNIQUE[@]} object(s). Extracting and disassembling..."
  # Extract only matched members
  ar x "$REL_ARCHIVE" "${UNIQUE[@]}" || true

  # Disassemble each extracted .o
  for o in "${UNIQUE[@]}"; do
    base="$(basename "$o")"
    out="$ASM_DIR/$base.asm"
    echo "  - $o -> $out"
    $OBJDUMP $ODFLAGS "$o" > "$out" || true
  done
fi

popd >/dev/null

echo "[Done] Disassembly outputs in: $ASM_DIR"
echo "       - Binary asm : $BIN_ASM"
echo "       - Objects    : *.asm for matched archive members (if any)"

# -------------------- Usage tips --------------------
# 1) 构建时手动指定静态库（当名字带后缀时）：
#    OPENBLAS_A=../../openblas/openblas_install/lib/libopenblas_neoversev1p-r0.3.30.dev.a ./disasm.sh
# 2) 更换输出目录：
#    OUT_DIR=./my_out ./disasm.sh
# 3) 线程控制：
#    OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 ARMPL_NUM_THREADS=1 ./disasm.sh
