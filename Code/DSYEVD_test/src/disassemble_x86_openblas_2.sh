#!/usr/bin/env bash
# Build + disassemble (static link OpenBLAS, pure assembly only)
set -euo pipefail

SRC="${SRC:-dsyevd.c}"
TARGET_BASE="${TARGET_BASE:-dsyevd_test}"
OPENBLAS_LIB="${OPENBLAS_LIB:-../../openblas/install/lib/libopenblas.a}"
OUT="${OUT:-my_objdump.s}"

# 指定要看的函数，多个用逗号分隔；留空则导出整个 .text 段
FUNCS="${FUNCS:-dsyevd_,dstedc_}"

# 平台：MSYS2 自动加 .exe 后缀
EXE_SUFFIX=""
case "$(uname -s || echo)" in
  MINGW*|MSYS*|CYGWIN*) EXE_SUFFIX=".exe" ;;
esac
TARGET="${TARGET_BASE}${EXE_SUFFIX}"

# x86 自动加 Intel 语法
ASMFLAG=""
case "$(uname -m || echo)" in
  x86_64|i?86) ASMFLAG="-M intel" ;;
esac

echo "[build] $SRC -> $TARGET (static link)"
gcc -O3 -march=native "$SRC" -o "$TARGET" \
    "$OPENBLAS_LIB" -lgfortran -lpthread -lm ${EXTRA_LDFLAGS:-}

echo "[disasm] -> $OUT"
if [ -n "$FUNCS" ]; then
  ARGS=""
  IFS=',' read -ra FARR <<< "$FUNCS"
  for f in "${FARR[@]}"; do
    [ -n "$f" ] && ARGS="$ARGS --disassemble=$f"
  done
  objdump -d $ASMFLAG $ARGS "$TARGET" > "$OUT"
else
  objdump -d $ASMFLAG --section=.text "$TARGET" > "$OUT"
fi

echo "[done] see $OUT"
