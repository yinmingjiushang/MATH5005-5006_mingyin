#!/usr/bin/env bash
# Run full experiment 4.3: benchmarks (SVE + scalar) then compare + stack_timing.
# Usage: ./run_all.sh   (from this directory, or any dir)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
ROOT="$SCRIPT_DIR/../output"

echo "=== 1/3 build_run.sh all ==="
"$SCRIPT_DIR/build_run.sh" all

echo ""
echo "=== 2/3 compare_partial.py (syev, syevd) ==="
python3 "$SCRIPT_DIR/compare_partial.py" --lib-a openblas_sve --lib-b openblas_scalar --routine syev  --root "$ROOT"
python3 "$SCRIPT_DIR/compare_partial.py" --lib-a openblas_sve --lib-b openblas_scalar --routine syevd --root "$ROOT"

echo ""
echo "=== 3/3 stack_timing.py (syev, syevd) ==="
python3 "$SCRIPT_DIR/stack_timing.py" --routine syev  --root "$ROOT"
python3 "$SCRIPT_DIR/stack_timing.py" --routine syevd --root "$ROOT"

echo ""
echo "Done. Results under $ROOT/compare/"
