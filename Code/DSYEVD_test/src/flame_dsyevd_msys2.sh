#!/usr/bin/env bash
set -euo pipefail

SRC="${SRC:-dsyevd.c}"
EXE="${EXE:-dsyevd_flame.exe}"
OUT_DIR="${OUT_DIR:-output}"
OPENBLAS_LIB="${OPENBLAS_LIB:-../../openblas/install/lib/libopenblas.a}"
FLAMEGRAPH_DIR="${FLAMEGRAPH_DIR:-../../flamegraph/FlameGraph}"

POWERSHELL_SCRIPT="${POWERSHELL_SCRIPT:-flame_dsyevd_win.ps1}"

mkdir -p "$OUT_DIR"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1

have(){ command -v "$1" >/dev/null 2>&1; }

echo "[build]"
if have clang && have lld-link; then
  echo "  using clang + lld (PDB)"
  # 关闭 MSYS2 参数改写，避免 /DEBUG 被当成路径
  MSYS2_ARG_CONV_EXCL='*' clang -O3 -gcodeview -fno-omit-frame-pointer -fuse-ld=lld -Wl,/DEBUG -Wl,/PDB:"${EXE}.pdb" \
    "$SRC" "$OPENBLAS_LIB" -lpthread -lm -lgfortran -o "$EXE"
else
  echo "  using gcc (DWARF symbols)"
  gcc -O3 -g -fno-omit-frame-pointer \
    "$SRC" "$OPENBLAS_LIB" -lpthread -lm -lgfortran -o "$EXE"
fi

if [ ! -f "$POWERSHELL_SCRIPT" ]; then
  echo "ERROR: 缺少 $POWERSHELL_SCRIPT"; exit 2
fi

# 转为 Windows 风格路径
EXE_WIN="$(pwd -W)/$EXE"
OUT_WIN="$(pwd -W)/$OUT_DIR"
FG_WIN="$(cd "$FLAMEGRAPH_DIR" >/dev/null 2>&1 && pwd -W)"

# ⚠️ 重要：整行写，不要用反引号续行（反引号在 bash 会被当做命令替换）
powershell -NoProfile -ExecutionPolicy Bypass -File "$POWERSHELL_SCRIPT" -ExePath "$EXE_WIN" -OutDir "$OUT_WIN" -FlameGraphDir "$FG_WIN"

echo "[done] 打开 $OUT_DIR/flame.svg"
