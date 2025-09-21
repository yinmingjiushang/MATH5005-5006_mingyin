#!/bin/sh
# Disassemble Divide-&-Conquer related objects from Reference LAPACK static lib.
# Portable POSIX sh version (no bashisms).
# Outputs *.s into ./output. Falls back to extracting member if direct objdump fails.

set -eu

# Config (can be overridden by env)
LAPACK_LIB="${LAPACK_LIB:-../../LAPACK_build/build/lib/liblapack.a}"
#OBJDUMP="${OBJDUMP:-/opt/homebrew/opt/llvm/bin/llvm-objdump}"
OBJDUMP=/opt/homebrew/opt/llvm/bin/llvm-objdump
OBJDUMP_OPTS="${OBJDUMP_OPTS:-}"
OUT_DIR="${OUT_DIR:-../output}"

# Substring keys to search inside archive members
KEYS="dstevd dstedc dlaed0 dlaed1 dlaed2 dlaed3 dlaed4 dlaed5 dlaed6 dlaed7 dlaed8 dlaed9 dlaeda dlamrg"

mkdir -p "$OUT_DIR"

if [ ! -f "$LAPACK_LIB" ]; then
  echo "ERROR: LAPACK static library not found: $LAPACK_LIB" >&2
  exit 1
fi

echo "== Using lib = $LAPACK_LIB"
echo "== Output dir = $OUT_DIR"
echo

# Dump member list to a temp file (portable replacement of 'mapfile')
MEMBERS_FILE="$(mktemp -t lapack_members.XXXX.txt)"
ar -t "$LAPACK_LIB" > "$MEMBERS_FILE"

INDEX_FILE="$OUT_DIR/index.txt"
: > "$INDEX_FILE"
{
  echo "# Disassembly index ($(date))"
  echo "# Library: $LAPACK_LIB"
  echo
} >> "$INDEX_FILE"

FOUND=0

disasm_member() {
  member="$1"
  base="$(basename "$member")"
  tag="${base%.*}"         # strip last extension (e.g., .o)
  tag="${tag%.*}"          # strip another (.f) if present
  out="$OUT_DIR/${tag}_objdump.s"

  # Try archive(member) form first (supported by Apple LLVM tools)
  if $OBJDUMP -d $OBJDUMP_OPTS "$LAPACK_LIB($member)" > "$out" 2>/dev/null; then
    echo "[OK] $member -> $out"
    return 0
  fi

  # Fallback: extract to a temp dir, then disassemble the loose object
  TMPDIR="$(mktemp -d -t lapack_obj.XXXX)"
  ( cd "$TMPDIR" && ar -x "$OLDPWD/$LAPACK_LIB" "$member" )
  if [ ! -f "$TMPDIR/$(basename "$member")" ]; then
    echo "[--] extract failed: $member"
    rm -rf "$TMPDIR"
    return 1
  fi
  $OBJDUMP -d $OBJDUMP_OPTS "$TMPDIR/$(basename "$member")" > "$out"
  rm -rf "$TMPDIR"
  echo "[OK] $member -> $out (via extract)"
  return 0
}

# Iterate over keys; for each key, grep matching members and disassemble
for key in $KEYS; do
  hits_file="$(mktemp -t lapack_hits.XXXX.txt)"
  grep -i "$key" "$MEMBERS_FILE" > "$hits_file" || true

  if [ ! -s "$hits_file" ]; then
    echo "[--] $key (no member found)"
    echo "$key -> missing" >> "$INDEX_FILE"
    rm -f "$hits_file"
    continue
  fi

  # Loop over each matching member
  while IFS= read -r m; do
    if [ -n "$m" ]; then
      if disasm_member "$m"; then
        FOUND=$((FOUND + 1))
        echo "$m -> ${key}_objdump.s" >> "$INDEX_FILE"
      fi
    fi
  done < "$hits_file"
  rm -f "$hits_file"
done

rm -f "$MEMBERS_FILE"

echo
echo "Done. Disassembled $FOUND member(s). See:"
echo "  - $INDEX_FILE"
echo "  - $OUT_DIR/*.s"
