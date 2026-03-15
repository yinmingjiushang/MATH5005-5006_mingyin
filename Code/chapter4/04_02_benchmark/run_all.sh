#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
SECTION_DIR="$SCRIPT_DIR"

"$SECTION_DIR/dsyev_backend/script/build_run.sh" benchmark-syev-openblas
"$SECTION_DIR/dsyevd_backend/script/build_run.sh" benchmark-syevd-openblas
