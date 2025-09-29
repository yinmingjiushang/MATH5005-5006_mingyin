#!/usr/bin/env bash
# Disassemble OpenBLAS LAPACK Divide-&-Conquer members on x86 (Linux/WSL/MSYS2-UCRT64).
# - Auto-detect llvm-objdump/objdump; detect COFF/ELF/LLVM bitcode via `file`.
# - Normal/thin archives supported (prefer `ar -x`, fallback `ar p`).
# - Output: *_objdump.s (machine code) or *.ll (LLVM IR); plus a quick SIMD scan.
set -euo pipefail

# ===== Config (env overrides) =====
# Default to your layout; override with: export OPENBLAS_LIB=/path/libopenblas.a
OPENBLAS_LIB="${OPENBLAS_LIB:-../../openblas/install/lib/libopenblas.a}"
OUT_DIR="${OUT_DIR:-../output}"

# LAPACK D&C pipeline members (substring matches). Override with export KEYS="..."
KEYS="${KEYS:-dsyevd dstevd dstedc dlaed0 dlaed1 dlaed2 dlaed3 dlaed4 dlaed5 dlaed6 dlaed7 dlaed8 dlaed9 dlaeda dlamrg}"

# ===== Tool detection =====
if command -v llvm-objdump >/dev/null 2>&1; then
  OBJDUMP="${OBJDUMP:-llvm-objdump}"
  OBJDUMP_OPTS="${OBJDUMP_OPTS:--d --x86-asm-syntax=intel --no-show-raw-insn --symbolize-operands --print-imm-hex}"
else
  OBJDUMP="${OBJDUMP:-objdump}"
  # Let objdump auto-detect file format (COFF/ELF); Intel syntax for x86
  OBJDUMP_OPTS="${OBJDUMP_OPTS:--dr -M intel}"
fi
LLVMDIS="${LLVMDIS:-llvm-dis}"
FILECMD="${FILECMD:-file}"

# ===== Prep =====
mkdir -p "$OUT_DIR"
[ -f "$OPENBLAS_LIB" ] || { echo "ERROR: $OPENBLAS_LIB not found"; exit 1; }

echo "== Using lib  : $OPENBLAS_LIB"
echo "== Objdump    : $OBJDUMP $OBJDUMP_OPTS"
command -v "$LLVMDIS" >/dev/null 2>&1 && echo "== llvm-dis    : $LLVMDIS"
echo "== Output dir : $OUT_DIR"
echo "== Keys       : $KEYS"
echo

# List members (strip CR for safety)
MEMBERS_FILE="$(mktemp -t openblas_members.XXXX.txt 2>/dev/null || mktemp)"
ar -t "$OPENBLAS_LIB" | tr -d '\r' > "$MEMBERS_FILE"

INDEX_FILE="$OUT_DIR/index.txt"
: > "$INDEX_FILE"
{
  echo "# Disassembly index ($(date))"
  echo "# Library: $OPENBLAS_LIB"
  echo "# Objdump: $OBJDUMP $OBJDUMP_OPTS"
  echo
} >> "$INDEX_FILE"

FOUND=0
IR_DUMPED=0
SKIPPED=0

disasm_machine_obj() {
  local in="$1" out="$2"
  if "$OBJDUMP" $OBJDUMP_OPTS "$in" > "$out"; then
    echo "[OK] machine-code: $in -> $out"
    echo "$in -> $out" >> "$INDEX_FILE"
    return 0
  else
    echo "[!!] objdump failed on $in" >&2
    return 1
  fi
}

dump_bitcode() {
  local in="$1" out="$2"
  if command -v "$LLVMDIS" >/dev/null 2>&1; then
    if "$LLVMDIS" -o "$out" "$in"; then
      echo "[OK] llvm-bitcode : $in -> $out"
      echo "$in -> $out" >> "$INDEX_FILE"
      return 0
    fi
  fi
  echo "[--] llvm-dis missing or failed: $in" >&2
  return 1
}

handle_member() {
  local member="$1"
  local base tag out_s out_ll
  base="$(basename "$member")"
  tag="${base%.*}"; tag="${tag%.*}"
  out_s="$OUT_DIR/${tag}_objdump.s"
  out_ll="$OUT_DIR/${tag}.ll"

  local TMPDIR; TMPDIR="$(mktemp -d -t openblas_obj.XXXX 2>/dev/null || mktemp -d)"

  # Prefer true extraction; fallback to ar p if needed
  if ! ( cd "$TMPDIR" && ar -x "$OLDPWD/$OPENBLAS_LIB" "$member" ) 2>/dev/null; then
    ar p "$OPENBLAS_LIB" "$member" > "$TMPDIR/$base" 2>/dev/null || {
      echo "[--] extract failed: $member"
      rm -rf "$TMPDIR"; return 1
    }
  fi

  # Normalize extracted filename (ar -x can drop into nested path)
  [ -f "$TMPDIR/$base" ] || base="$(ls -1 "$TMPDIR" | head -n1)"
  [ -f "$TMPDIR/$base" ] || { echo "[--] missing extracted object: $member"; rm -rf "$TMPDIR"; return 1; }

  local info="$($FILECMD -b "$TMPDIR/$base" 2>/dev/null || true)"

  if echo "$info" | grep -qiE 'LLVM IR|bitcode'; then
    dump_bitcode "$TMPDIR/$base" "$out_ll" && IR_DUMPED=$((IR_DUMPED+1)) || SKIPPED=$((SKIPPED+1))
  else
    disasm_machine_obj "$TMPDIR/$base" "$out_s" && FOUND=$((FOUND+1)) || { echo "[--] unknown/failed ($info): $member"; SKIPPED=$((SKIPPED+1)); }
  fi
  rm -rf "$TMPDIR"
}

for key in $KEYS; do
  hits_file="$(mktemp -t openblas_hits.XXXX.txt 2>/dev/null || mktemp)"
  grep -i "$key" "$MEMBERS_FILE" > "$hits_file" || true

  if [ ! -s "$hits_file" ]; then
    echo "[--] $key (no member found)"
    echo "$key -> missing" >> "$INDEX_FILE"
    rm -f "$hits_file"; continue
  fi

  while IFS= read -r m; do
    [ -n "$m" ] || continue
    handle_member "$m" || true
  done < "$hits_file"
  rm -f "$hits_file"
done

rm -f "$MEMBERS_FILE"

# ===== Optional: quick SIMD scan (AVX/SSE hints) =====
echo
echo "== SIMD scan (AVX/SSE hints) =="
grep -nE '\b(ymm|zmm|vfmadd|v(add|sub|mul)p[sd])\b' "$OUT_DIR"/*.s 2>/dev/null | head || true
grep -nE '\b(xmm|addp[sd]|mulp[sd]|movap[sd]|movup[sd])\b' "$OUT_DIR"/*.s 2>/dev/null | head || true

echo
echo "Done. Machine-code: $FOUND, LLVM-IR: $IR_DUMPED, Skipped: $SKIPPED"
echo "See:"
echo "  - $INDEX_FILE"
echo "  - $OUT_DIR/*.s (machine-code)"
echo "  - $OUT_DIR/*.ll (LLVM IR)"
