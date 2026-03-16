#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
CODE_DIR="$(cd -- "$SCRIPT_DIR/../.." >/dev/null 2>&1 && pwd -P)"

python3 "$SCRIPT_DIR/script/accelerate_decompose.py" \
  --root4_2 "$CODE_DIR/chapter4/04_03_blas_optimization/output" \
  --root4_3 "$CODE_DIR/chapter4/04_04_sve_vectorization/output"
