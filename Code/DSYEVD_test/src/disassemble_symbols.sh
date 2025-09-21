#!/usr/bin/env bash
# Export symbol tables alongside disassembly for selected LAPACK objects.
# Writes *.sym next to *.s under ./output.

set -euo pipefail

LAPACK_LIB="${LAPACK_LIB:-../../LAPACK_build/build/lib/liblapack.a}"
OUT_DIR="../output"
NM="${NM:-nm}"

OBJECTS=(
  "dstevd.o"
  "dstedc.o"
  "dlaed0.o"
  "dlaed1.o"
  "dlaed2.o"
  "dlaed3.o"
  "dlaed4.o"
  "dlaed5.o"
  "dlaed6.o"
  "dlaed7.o"
  "dlaed8.o"
  "dlaed9.o"
  "dlaeda.o"
  "dlamrg.o"
)

mkdir -p "$OUT_DIR"

if [ ! -f "$LAPACK_LIB" ]; then
  echo "ERROR: LAPACK static library not found: $LAPACK_LIB" >&2
  exit 1
fi

echo "== Using lib = $LAPACK_LIB"
echo "== Output dir = $OUT_DIR"
echo

has_member () {
  ar -t "$LAPACK_LIB" | grep -x "$1" >/dev/null 2>&1
}

for obj in "${OBJECTS[@]}"; do
  if has_member "$obj"; then
    sym="$OUT_DIR/${obj%.o}.sym"
    echo "[OK] symbols: $obj -> $sym"
    # On macOS, nm can read lib.a(member) form directly
    $NM -an "$LAPACK_LIB($obj)" > "$sym"
  else
    echo "[--] symbols: $obj missing, skipped"
  fi
done

echo "Done. Symbols exported under $OUT_DIR/*.sym"
