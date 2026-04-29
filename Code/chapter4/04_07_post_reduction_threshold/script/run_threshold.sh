#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd -P)"
BIN="$ROOT_DIR/output/bin/post_reduction_threshold"

if [[ ! -x "$BIN" ]]; then
  "$SCRIPT_DIR/build.sh"
fi

if [[ "$#" -gt 0 ]]; then
  SIZES=("$@")
else
  SIZES=(512 1024 2048 4096 6144 8192)
fi

cd "$ROOT_DIR"
echo "[RUN] sizes: ${SIZES[*]}"
exec "$BIN" "${SIZES[@]}"
