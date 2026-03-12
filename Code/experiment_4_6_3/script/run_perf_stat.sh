#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
OUT_DIR="$SCRIPT_DIR/../output"
BIN_DIR="$OUT_DIR/bin"

MODE="${1:-all}"
SIZE_LIST="${SIZE_LIST:-512 1024 2048 4096}"
read -r -a SIZES <<< "$SIZE_LIST"
DEFAULT_EVENTS="task-clock,cycles,instructions,cache-references,cache-misses,l1d_cache_refill,l2d_cache_refill,mem_access,stall_backend_mem"
DEEP_EVENTS_CORE="task-clock,cycles,instructions,stall_backend_mem"
DEEP_EVENTS_MEMORY="cache-references,cache-misses,l1d_cache_refill,l2d_cache_refill,mem_access,mem_access_rd,mem_access_wr,L1-dcache-loads,L1-dcache-load-misses"
DEEP_EVENTS_COMPUTE="fp_fixed_ops_spec,fp_scale_ops_spec,sve_inst_spec,ase_inst_spec,ld_spec,st_spec"

repeat_for_case() {
  local mode="$1"
  local n="$2"
  if [[ "$mode" == "tri" ]]; then
    case "$n" in
      512|1024) echo 5 ;;
      2048) echo 3 ;;
      4096|8192) echo 1 ;;
    esac
  else
    case "$n" in
      512|1024) echo 3 ;;
      2048|4096|8192) echo 1 ;;
    esac
  fi
}

setup_output_layout() {
  case "$MODE" in
    deep-tri)
      PERF_DIR="$OUT_DIR/perf_deep"
      SUMMARY_CSV="$PERF_DIR/perf_deep_tri_summary.csv"
      EVENTS="${PERF_EVENTS:-$DEEP_EVENTS_CORE}"
      ;;
    *)
      PERF_DIR="$OUT_DIR/perf"
      SUMMARY_CSV="$PERF_DIR/perf_stat_summary.csv"
      EVENTS="${PERF_EVENTS:-$DEFAULT_EVENTS}"
      ;;
  esac
  RAW_DIR="$PERF_DIR/raw"
  mkdir -p "$RAW_DIR"
}

run_case() {
  local case_name="$1"
  local bin_name="$2"
  local family="$3"
  local suffix="${4:-}"
  local events_override="${5:-$EVENTS}"
  local bin="$BIN_DIR/$bin_name"

  if [[ ! -x "$bin" ]]; then
    echo "Missing binary: $bin" >&2
    echo "Run ./build_run.sh all first." >&2
    exit 1
  fi

  for n in "${SIZES[@]}"; do
    local repeat
    repeat="$(repeat_for_case "$family" "$n")"
    local stem="${case_name}_N${n}_R${repeat}"
    if [[ -n "$suffix" ]]; then
      stem="${stem}_${suffix}"
    fi
    local raw="$RAW_DIR/${stem}.perf.csv"
    local stdout="$RAW_DIR/${stem}.stdout.txt"
    echo "[perf] $case_name N=$n repeat=$repeat ${suffix:+group=$suffix }"
    perf stat -x, -e "$events_override" -o "$raw" -- \
      "$bin" --n "$n" --repeat "$repeat" > "$stdout"
  done
}

setup_output_layout

case "$MODE" in
  all)
    run_case "dsyev" "benchmark-syev-openblas-sve-hw" "end2end"
    run_case "dsyevd" "benchmark-syevd-openblas-sve-hw" "end2end"
    run_case "dsteqr" "benchmark-dsteqr-openblas-sve-hw" "tri"
    run_case "dstedc" "benchmark-dstedc-openblas-sve-hw" "tri"
    ;;
  end2end)
    run_case "dsyev" "benchmark-syev-openblas-sve-hw" "end2end"
    run_case "dsyevd" "benchmark-syevd-openblas-sve-hw" "end2end"
    ;;
  tri)
    run_case "dsteqr" "benchmark-dsteqr-openblas-sve-hw" "tri"
    run_case "dstedc" "benchmark-dstedc-openblas-sve-hw" "tri"
    ;;
  deep-tri)
    run_case "dsteqr" "benchmark-dsteqr-openblas-sve-hw" "tri" "core" "$DEEP_EVENTS_CORE"
    run_case "dsteqr" "benchmark-dsteqr-openblas-sve-hw" "tri" "memory" "$DEEP_EVENTS_MEMORY"
    run_case "dsteqr" "benchmark-dsteqr-openblas-sve-hw" "tri" "compute" "$DEEP_EVENTS_COMPUTE"
    run_case "dstedc" "benchmark-dstedc-openblas-sve-hw" "tri" "core" "$DEEP_EVENTS_CORE"
    run_case "dstedc" "benchmark-dstedc-openblas-sve-hw" "tri" "memory" "$DEEP_EVENTS_MEMORY"
    run_case "dstedc" "benchmark-dstedc-openblas-sve-hw" "tri" "compute" "$DEEP_EVENTS_COMPUTE"
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 1
    ;;
esac

python3 "$SCRIPT_DIR/summarize_hw.py" perf --input-dir "$RAW_DIR" --output "$SUMMARY_CSV" --sizes "${SIZES[@]}"
echo "[DONE ] Summary CSV: $SUMMARY_CSV"
