#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
OUT_DIR="$SCRIPT_DIR/../output"
BIN_DIR="$OUT_DIR/bin"
MEM_DIR="$OUT_DIR/mem"
RAW_DIR="$MEM_DIR/raw"
SUMMARY_CSV="$MEM_DIR/memory_summary.csv"

mkdir -p "$RAW_DIR"

MODE="${1:-end2end}"
SIZE_LIST="${SIZE_LIST:-512 1024 2048 4096}"
read -r -a SIZES <<< "$SIZE_LIST"

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
    echo 1
  fi
}

run_case() {
  local case_name="$1"
  local bin_name="$2"
  local family="$3"
  local bin="$BIN_DIR/$bin_name"

  if [[ ! -x "$bin" ]]; then
    echo "Missing binary: $bin" >&2
    echo "Run ./build_run.sh all first." >&2
    exit 1
  fi

  for n in "${SIZES[@]}"; do
    local repeat
    repeat="$(repeat_for_case "$family" "$n")"
    local raw="$RAW_DIR/${case_name}_N${n}_R${repeat}.time.txt"
    local stdout="$RAW_DIR/${case_name}_N${n}_R${repeat}.stdout.txt"
    echo "[mem ] $case_name N=$n repeat=$repeat"
    /usr/bin/time -v -o "$raw" \
      "$bin" --n "$n" --repeat "$repeat" > "$stdout"
  done
}

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
  *)
    echo "Unknown mode: $MODE" >&2
    exit 1
    ;;
esac

python3 "$SCRIPT_DIR/summarize_hw.py" mem --input-dir "$RAW_DIR" --output "$SUMMARY_CSV" --sizes "${SIZES[@]}"
echo "[DONE ] Summary CSV: $SUMMARY_CSV"
