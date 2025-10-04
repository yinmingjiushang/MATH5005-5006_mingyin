#!/usr/bin/env bash
# flamegraph.sh — Generate CPU flame graph with perf + FlameGraph
# Usage:
#   ./flamegraph.sh run [duration_sec] [freq] -- <cmd> [args...]
#   ./flamegraph.sh pid <PID> [duration_sec] [freq]
#   ./flamegraph.sh system [duration_sec] [freq]
#
# Examples:
#   ./flamegraph.sh run 15 99 -- ../src/dsyevd
#   ./flamegraph.sh pid 12345 20 199
#   ./flamegraph.sh system 30 99
#
# Notes:
# - Needs: perf, git, awk, sed. Will try to guide install.
# - Uses DWARF call graph for better user-space stacks.
# - Outputs to: ./output/perf/<timestamp>/{perf.data,perf.stacks,perf.folded,flame.svg}

set -euo pipefail

export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-1}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-1}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
OUT_ROOT="$SCRIPT_DIR/output/perf"
TOOLS_DIR="$SCRIPT_DIR/tools"
FLAME_DIR="$TOOLS_DIR/FlameGraph"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="$OUT_ROOT/$TS"
mkdir -p "$OUT_DIR"

MODE="${1:-run}"            # run | pid | system
shift || true

# Defaults
DURATION="${1:-15}"; shift || true
FREQ="${1:-99}";     shift || true

# ——— helpers ———
need() { command -v "$1" >/dev/null 2>&1; }
die() { echo "[Error] $*"; exit 1; }

detect_pkgmgr() {
  if need dnf; then echo dnf
  elif need yum; then echo yum
  elif need apt; then echo apt
  else echo unknown
  fi
}

ensure_perf() {
  if need perf; then return; fi
  echo "[Warn] 'perf' not found."
  local pm; pm="$(detect_pkgmgr)"
  case "$pm" in
    dnf) echo "  Try: sudo dnf install -y perf";;
    yum) echo "  Try: sudo yum install -y perf";;
    apt) echo "  Try: sudo apt update && sudo apt install -y linux-perf";;
    *)   echo "  Unknown package manager. Install 'perf' manually.";;
  esac
  die "Please install 'perf' and rerun."
}

ensure_tools() {
  need git || die "git required."
  need awk || die "awk required."
  need sed || die "sed required."
  if [[ ! -d "$FLAME_DIR" ]]; then
    mkdir -p "$TOOLS_DIR"
    echo "[Info] Cloning FlameGraph into $FLAME_DIR ..."
    git clone --depth=1 https://github.com/brendangregg/FlameGraph.git "$FLAME_DIR"
  fi
}

lower_paranoia_if_possible() {
  # Try to relax perf restrictions (ignore failures)
  if [[ -w /proc/sys/kernel/perf_event_paranoid ]]; then
    echo 1 | sudo tee /proc/sys/kernel/perf_event_paranoid >/dev/null 2>&1 || true
  else
    sudo sysctl -w kernel.perf_event_paranoid=1 >/dev/null 2>&1 || true
  fi
  if [[ -w /proc/sys/kernel/kptr_restrict ]]; then
    echo 0 | sudo tee /proc/sys/kernel/kptr_restrict >/dev/null 2>&1 || true
  else
    sudo sysctl -w kernel.kptr_restrict=0 >/dev/null 2>&1 || true
  fi
}

record_run() {
  # Remaining args after '--' is the command
  local cmd=("$@")
  if [[ ${#cmd[@]} -eq 0 ]]; then
    # default to your dsyevd test
    cmd=("$SCRIPT_DIR/../src/dsyevd")
  fi
  echo "[Record] mode=run duration=${DURATION}s freq=${FREQ} cmd=${cmd[*]}"
  perf record -F "$FREQ" -g --call-graph dwarf --output="$OUT_DIR/perf.data" -- \
    "${cmd[@]}" || true
}

record_pid() {
  local pid="$1"; shift || true
  echo "[Record] mode=pid pid=$pid duration=${DURATION}s freq=${FREQ}"
  # sample for DURATION seconds
  perf record -F "$FREQ" -g --call-graph dwarf -p "$pid" \
    --output="$OUT_DIR/perf.data" -- sleep "$DURATION" || true
}

record_system() {
  echo "[Record] mode=system duration=${DURATION}s freq=${FREQ}"
  perf record -F "$FREQ" -g --call-graph dwarf -a \
    --output="$OUT_DIR/perf.data" -- sleep "$DURATION" || true
}

post_process() {
  echo "[Process] Converting perf.data -> stacks -> folded -> flame.svg"
  # perf script to text stacks
  perf script -i "$OUT_DIR/perf.data" > "$OUT_DIR/perf.stacks" 2>/dev/null || true
  # collapse stacks
  "$FLAME_DIR/stackcollapse-perf.pl" "$OUT_DIR/perf.stacks" > "$OUT_DIR/perf.folded"
  # generate SVG
  "$FLAME_DIR/flamegraph.pl" --title "CPU Flame Graph ($MODE, ${DURATION}s, F${FREQ})" \
    --countname=samples --width=1600 --height=900 \
    "$OUT_DIR/perf.folded" > "$OUT_DIR/flame.svg"
  echo "[Done] Flame graph: $OUT_DIR/flame.svg"
}

# ——— main ———
ensure_perf
ensure_tools
lower_paranoia_if_possible

case "$MODE" in
  run)
    # If user passed '--', everything after它就是命令
    if [[ "${1:-}" == "--" ]]; then shift; fi
    record_run "$@"
    ;;
  pid)
    [[ $# -ge 1 ]] || die "Usage: ./flamegraph.sh pid <PID> [duration] [freq]"
    PID="$1"; shift || true
    [[ -d "/proc/$PID" ]] || die "PID $PID not found"
    record_pid "$PID"
    ;;
  system)
    record_system
    ;;
  *)
    die "Unknown mode: $MODE (use: run|pid|system)"
    ;;
esac

post_process

echo "Artifacts:"
echo "  - perf.data   : $OUT_DIR/perf.data"
echo "  - stacks      : $OUT_DIR/perf.stacks"
echo "  - folded      : $OUT_DIR/perf.folded"
echo "  - flame.svg   : $OUT_DIR/flame.svg"
echo
echo "Open the SVG in a browser or download it, e.g.:"
echo "  scp ec2-user@<your-ec2-ip>:$OUT_DIR/flame.svg ."
