#!/usr/bin/env bash
# Run perf record on syev/syevd benchmark for Tri-eig hotspot comparison.
# Usage: ./perf_syevd.sh <path-to-binary>
#   e.g. ./perf_syevd.sh ../output/bin/benchmark-syev-openblas
#   e.g. ./perf_syevd.sh ../output/bin/benchmark-syevd-openblas
#
# Output: perf.data, perf report to stdout.
# Use perf report -g 'symbol,dso' --stdio for full hotspot.
set -euo pipefail

BIN="${1:-}"
if [[ -z "$BIN" || ! -x "$BIN" ]]; then
    echo "Usage: $0 <path-to-benchmark-binary>"
    echo "  e.g. $0 ../output/bin/benchmark-syev-openblas"
    echo "  e.g. $0 ../output/bin/benchmark-syevd-openblas"
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
cd "$SCRIPT_DIR"

NAME="$(basename "$BIN")"
OUT_PERF="${NAME}.perf.data"

echo "[perf] Recording $BIN ..."
echo "[INFO] Run long enough (large N) for meaningful sampling. OMP/OPENBLAS threads=1."
perf record -g -F 99 -o "$OUT_PERF" -- "$BIN"
echo ""
echo "[perf] Report (symbol,dso):"
perf report -g 'symbol,dso' -i "$OUT_PERF" --stdio

echo ""
echo "Saved: $OUT_PERF"
echo "Re-report: perf report -g 'symbol,dso' -i $OUT_PERF --stdio"
