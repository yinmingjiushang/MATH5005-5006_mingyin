#!/usr/bin/env bash
# flamegraph.sh — perf + FlameGraph (full-run for 'case'; outputs under ../output/)
# Modes:
#   case <BIN> [freq] [-- <args...>]
#       -> runs ../output/bin/<BIN> to completion (full-run sampling)
#       -> outputs to ../output/perf/<BIN>_<timestamp>/
#   pid  <PID> [duration] [freq]
#       -> outputs to ../output/perf/pid<PID>_<timestamp>/
#   system [duration] [freq]
#       -> outputs to ../output/perf/system_<timestamp>/
#
# Examples:
#   ./flamegraph.sh case dsyevd-openblas
#   ./flamegraph.sh case dsyevd-openblas 199 -- --matrix 8000
#   ./flamegraph.sh pid 12345 20 199
#   ./flamegraph.sh system 10 99

set -euo pipefail

export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-1}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-1}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
BIN_ROOT="$SCRIPT_DIR/../output/bin"
OUT_ROOT="$SCRIPT_DIR/../output/perf"
TOOLS_DIR="$SCRIPT_DIR/tools"
FLAME_DIR="$TOOLS_DIR/FlameGraph"
mkdir -p "$OUT_ROOT"

MODE="${1:-}"; [[ -n "$MODE" ]] || { echo "Usage: case|pid|system ..."; exit 2; }; shift || true
TS="$(date +%Y%m%d_%H%M%S)"

need() { command -v "$1" >/dev/null 2>&1; }
die()  { echo "[Error] $*"; exit 1; }

ensure_tools() {
  need perf || die "'perf' not installed"
  need awk  || die "'awk' not installed"
  need sed  || die "'sed' not installed"
  if [[ ! -d "$FLAME_DIR" ]]; then
    need git || die "'git' not installed (required for FlameGraph clone)"
    mkdir -p "$TOOLS_DIR"
    echo "[Info] Cloning FlameGraph ..."
    git clone --depth=1 https://github.com/brendangregg/FlameGraph.git "$FLAME_DIR"
  fi
}

# Parse optional [duration] [freq] then optional "--"
parse_df() {
  DURATION=15
  FREQ=99
  if [[ $# -ge 1 && "${1:-}" =~ ^[0-9]+$ ]]; then
    DURATION="$1"; shift
  fi
  if [[ $# -ge 1 && "${1:-}" =~ ^[0-9]+$ ]]; then
    FREQ="$1"; shift
  fi
  if [[ "${1:-}" == "--" ]]; then shift; fi
  ARGS_REST=("$@")
}

# Parse optional [freq] then optional "--" (for 'case' full-run)
parse_f() {
  FREQ=99
  if [[ $# -ge 1 && "${1:-}" =~ ^[0-9]+$ ]]; then
    FREQ="$1"; shift
  fi
  if [[ "${1:-}" == "--" ]]; then shift; fi
  ARGS_REST=("$@")
}

post_process() {
  local out_dir="$1"; shift
  local title="$1";   shift
  echo "[Process] Generating stacks / folded / flame.svg"
  perf script -i "$out_dir/perf.data" > "$out_dir/perf.stacks" 2>/dev/null || true
  "$FLAME_DIR/stackcollapse-perf.pl" "$out_dir/perf.stacks" > "$out_dir/perf.folded"
  "$FLAME_DIR/flamegraph.pl" --title "CPU Flame Graph (${title}, F${FREQ})" \
    --countname=samples --width=1600 --height=900 \
    "$out_dir/perf.folded" > "$out_dir/flame.svg"
  echo "[Done] $out_dir/flame.svg"
}

ensure_tools

case "$MODE" in
  case)
    # case <BIN> [freq] [-- <args...>] (full-run)
    [[ $# -ge 1 ]] || die "Usage: ./flamegraph.sh case <BIN> [freq] [-- <args...>]"
    BIN="$1"; shift || true
    BIN_PATH="$BIN_ROOT/$BIN"
    [[ -x "$BIN_PATH" ]] || die "Binary not found or not executable: $BIN_PATH"

    parse_f "$@"; set -- "${ARGS_REST[@]}"
    TITLE="$BIN"
    OUT_DIR="$OUT_ROOT/${TITLE}_${TS}"
    mkdir -p "$OUT_DIR"

    echo "[Record] case=$BIN full-run F${FREQ} :: $BIN_PATH $*"
    perf record -F "$FREQ" -g --call-graph dwarf --output="$OUT_DIR/perf.data" -- "$BIN_PATH" "$@" || true
    post_process "$OUT_DIR" "$TITLE"
    ;;

  pid)
    # pid <PID> [duration] [freq]
    [[ $# -ge 1 ]] || die "Usage: ./flamegraph.sh pid <PID> [duration] [freq]"
    PID_VAL="$1"; shift || true
    [[ -d "/proc/$PID_VAL" ]] || die "PID $PID_VAL does not exist"

    parse_df "$@"; set -- "${ARGS_REST[@]}"
    TITLE="pid$PID_VAL"
    OUT_DIR="$OUT_ROOT/${TITLE}_${TS}"
    mkdir -p "$OUT_DIR"

    echo "[Record] pid=$PID_VAL ${DURATION}s F${FREQ}"
    perf record -F "$FREQ" -g --call-graph dwarf -p "$PID_VAL" \
      --output="$OUT_DIR/perf.data" -- sleep "$DURATION" || true
    post_process "$OUT_DIR" "$TITLE"
    ;;

  system)
    # system [duration] [freq]
    parse_df "$@"; set -- "${ARGS_REST[@]}"
    TITLE="system"
    OUT_DIR="$OUT_ROOT/${TITLE}_${TS}"
    mkdir -p "$OUT_DIR"

    echo "[Record] system ${DURATION}s F${FREQ}"
    perf record -F "$FREQ" -g --call-graph dwarf -a \
      --output="$OUT_DIR/perf.data" -- sleep "$DURATION" || true
    post_process "$OUT_DIR" "$TITLE"
    ;;

  *)
    die "Unknown mode: $MODE (use: case | pid | system)"
    ;;
esac

echo "Artifacts:"
echo "  - $OUT_DIR/perf.data"
echo "  - $OUT_DIR/perf.stacks"
echo "  - $OUT_DIR/perf.folded"
echo "  - $OUT_DIR/flame.svg"
