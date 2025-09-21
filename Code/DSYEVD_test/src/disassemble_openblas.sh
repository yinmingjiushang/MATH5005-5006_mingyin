#!/bin/sh
# Disassemble Divide-&-Conquer–related objects from OpenBLAS static lib
# (OpenBLAS bundles LAPACK routines). Portable POSIX sh (no bashisms).
# Outputs *.s into ./output. Falls back to extract-if-needed.

set -eu

# ---- Config (override via env) ----
OPENBLAS_LIB="${OPENBLAS_LIB:-../../openblas/lib/libopenblas.a}"
OBJDUMP="${OBJDUMP:-/opt/homebrew/opt/llvm/bin/llvm-objdump}"   # or llvm-objdump in PATH
OBJDUMP_OPTS="${OBJDUMP_OPTS:-}"
OUT_DIR="${OUT_DIR:-../output}"

# Substring keys to match LAPACK D&C pipeline members
# (dsyevd -> dstedc/dstevd + dlaed0..9/a + dlamrg, etc.)
KEYS="dsyevd dstevd dstedc dlaed0 dlaed1 dlaed2 dlaed3 dlaed4 dlaed5 dlaed6 dlaed7 dlaed8 dlaed9 dlaeda dlamrg"

mkdir -p "$OUT_DIR"

if [ ! -f "$OPENBLAS_LIB" ]; then
  echo "ERROR: OpenBLAS static library not found: $OPENBLAS_LIB" >&2
  exit 1
fi

echo "== Using lib = $OPENBLAS_LIB"
echo "== Output dir = $OUT_DIR"
echo

# List members (works for normal/thin archives)
MEMBERS_FILE="$(mktemp -t openblas_members.XXXX.txt)"
ar -t "$OPENBLAS_LIB" > "$MEMBERS_FILE"

INDEX_FILE="$OUT_DIR/index.txt"
: > "$INDEX_FILE"
{
  echo "# Disassembly index ($(date))"
  echo "# Library: $OPENBLAS_LIB"
  echo
} >> "$INDEX_FILE"

FOUND=0

disasm_member() {
  member="$1"
  base="$(basename "$member")"
  tag="${base%.*}"         # strip last extension (.o)
  tag="${tag%.*}"          # strip another (.f) if present
  out="$OUT_DIR/${tag}_objdump.s"

  # Try 'archive(member)' first (supported by Apple LLVM tools)
  if "$OBJDUMP" -d $OBJDUMP_OPTS "$OPENBLAS_LIB($member)" > "$out" 2>/dev/null; then
    echo "[OK] $member -> $out"
    return 0
  fi

  # Fallback: extract then disassemble loose object
  TMPDIR="$(mktemp -d -t openblas_obj.XXXX)"
  ( cd "$TMPDIR" && ar -x "$OLDPWD/$OPENBLAS_LIB" "$member" )
  if [ ! -f "$TMPDIR/$base" ]; then
    echo "[--] extract failed: $member"
    rm -rf "$TMPDIR"
    return 1
  fi
  "$OBJDUMP" -d $OBJDUMP_OPTS "$TMPDIR/$base" > "$out"
  rm -rf "$TMPDIR"
  echo "[OK] $member -> $out (via extract)"
  return 0
}

# Iterate keys; grep matching members; disassemble each
for key in $KEYS; do
  hits_file="$(mktemp -t openblas_hits.XXXX.txt)"
  # case-insensitive match on member names
  grep -i "$key" "$MEMBERS_FILE" > "$hits_file" || true

  if [ ! -s "$hits_file" ]; then
    echo "[--] $key (no member found)"
    echo "$key -> missing" >> "$INDEX_FILE"
    rm -f "$hits_file"
    continue
  fi

  while IFS= read -r m; do
    [ -n "$m" ] || continue
    if disasm_member "$m"; then
      FOUND=$((FOUND + 1))
      echo "$m -> ${key}_objdump.s" >> "$INDEX_FILE"
    fi
  done < "$hits_file"
  rm -f "$hits_file"
done

rm -f "$MEMBERS_FILE"

echo
echo "Done. Disassembled $FOUND member(s). See:"
echo "  - $INDEX_FILE"
echo "  - $OUT_DIR/*.s"
