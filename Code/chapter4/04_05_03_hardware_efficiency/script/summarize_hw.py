#!/usr/bin/env python3
import argparse
import csv
import pathlib
import re


PERF_RE = re.compile(r"(?P<case>[a-z0-9_]+)_N(?P<n>\d+)_R(?P<repeat>\d+)(?:_(?P<group>[a-z0-9_]+))?\.perf\.csv$")
MEM_RE = re.compile(r"(?P<case>[a-z0-9_]+)_N(?P<n>\d+)_R(?P<repeat>\d+)\.time\.txt$")


def parse_value(text: str):
    text = text.strip()
    if not text or text.startswith("<"):
        return None
    try:
        return float(text)
    except ValueError:
        return None


def normalize_event(name: str) -> str:
    return name.strip().split(":")[0].replace("-", "_").lower()


def safe_div(a, b):
    if a is None or b in (None, 0):
        return None
    return a / b


def fmt(value):
    if value is None:
        return ""
    return f"{value:.6f}"


def summarize_perf(input_dir: pathlib.Path, output_path: pathlib.Path, sizes=None):
    grouped = {}
    for path in sorted(input_dir.glob("*.perf.csv")):
        match = PERF_RE.match(path.name)
        if not match:
            continue
        n = int(match.group("n"))
        if sizes is not None and n not in sizes:
            continue

        key = (match.group("case"), n, int(match.group("repeat")))
        row = grouped.setdefault(key, {
            "case": match.group("case"),
            "n": n,
            "repeat": int(match.group("repeat")),
        })
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line:
                    continue
                parts = line.split(",")
                if len(parts) < 3:
                    continue
                value = parse_value(parts[0])
                event = normalize_event(parts[2])
                row[event] = value

    rows = []
    for _, row in sorted(grouped.items()):
        cycles = row.get("cycles")
        instructions = row.get("instructions")
        cache_refs = row.get("cache_references")
        cache_misses = row.get("cache_misses")
        l1_refill = row.get("l1d_cache_refill")
        l2_refill = row.get("l2d_cache_refill")
        mem_access = row.get("mem_access")
        mem_access_rd = row.get("mem_access_rd")
        mem_access_wr = row.get("mem_access_wr")
        stall_backend_mem = row.get("stall_backend_mem")
        task_clock = row.get("task_clock")
        l1_loads = row.get("l1_dcache_loads")
        l1_load_misses = row.get("l1_dcache_load_misses")
        fp_fixed_ops = row.get("fp_fixed_ops_spec")
        fp_scale_ops = row.get("fp_scale_ops_spec")
        sve_inst = row.get("sve_inst_spec")
        ase_inst = row.get("ase_inst_spec")
        ld_spec = row.get("ld_spec")
        st_spec = row.get("st_spec")
        fp_ops = None
        if fp_fixed_ops is not None or fp_scale_ops is not None:
            fp_ops = (fp_fixed_ops or 0.0) + (fp_scale_ops or 0.0)

        rows.append({
            "case": row["case"],
            "n": row["n"],
            "repeat": row["repeat"],
            "task_clock_ms": task_clock,
            "cycles": cycles,
            "instructions": instructions,
            "ipc": safe_div(instructions, cycles),
            "cache_references": cache_refs,
            "cache_misses": cache_misses,
            "cache_miss_rate": safe_div(cache_misses, cache_refs),
            "l1d_cache_refill": l1_refill,
            "l2d_cache_refill": l2_refill,
            "l1_refill_per_inst": safe_div(l1_refill, instructions),
            "l2_refill_per_inst": safe_div(l2_refill, instructions),
            "mem_access": mem_access,
            "mem_access_rd": mem_access_rd,
            "mem_access_wr": mem_access_wr,
            "mem_access_per_inst": safe_div(mem_access, instructions),
            "stall_backend_mem": stall_backend_mem,
            "stall_backend_mem_per_inst": safe_div(stall_backend_mem, instructions),
            "stall_backend_mem_per_cycle": safe_div(stall_backend_mem, cycles),
            "l1_dcache_loads": l1_loads,
            "l1_dcache_load_misses": l1_load_misses,
            "l1_dcache_load_miss_rate": safe_div(l1_load_misses, l1_loads),
            "fp_fixed_ops_spec": fp_fixed_ops,
            "fp_scale_ops_spec": fp_scale_ops,
            "fp_ops_spec": fp_ops,
            "fp_ops_per_inst": safe_div(fp_ops, instructions),
            "sve_inst_spec": sve_inst,
            "ase_inst_spec": ase_inst,
            "sve_inst_share": safe_div(sve_inst, instructions),
            "ase_inst_share": safe_div(ase_inst, instructions),
            "ld_spec": ld_spec,
            "st_spec": st_spec,
            "ld_spec_share": safe_div(ld_spec, instructions),
            "st_spec_share": safe_div(st_spec, instructions),
        })

    fieldnames = [
        "case", "n", "repeat", "task_clock_ms", "cycles", "instructions", "ipc",
        "cache_references", "cache_misses", "cache_miss_rate",
        "l1d_cache_refill", "l2d_cache_refill",
        "l1_refill_per_inst", "l2_refill_per_inst",
        "mem_access", "mem_access_rd", "mem_access_wr", "mem_access_per_inst",
        "stall_backend_mem", "stall_backend_mem_per_inst", "stall_backend_mem_per_cycle",
        "l1_dcache_loads", "l1_dcache_load_misses", "l1_dcache_load_miss_rate",
        "fp_fixed_ops_spec", "fp_scale_ops_spec", "fp_ops_spec", "fp_ops_per_inst",
        "sve_inst_spec", "ase_inst_spec", "sve_inst_share", "ase_inst_share",
        "ld_spec", "st_spec", "ld_spec_share", "st_spec_share",
    ]
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: fmt(v) if isinstance(v, float) else v for k, v in row.items()})


def parse_time_value(lines, prefix):
    for line in lines:
        if line.startswith(prefix):
            sep = ": "
            if sep in line:
                return line.split(sep, 1)[1].strip()
            return line.rsplit(":", 1)[1].strip()
    return ""


def parse_elapsed_seconds(text: str):
    if not text:
        return None
    parts = text.split(":")
    try:
        if len(parts) == 3:
            hours = float(parts[0])
            minutes = float(parts[1])
            seconds = float(parts[2])
            return hours * 3600.0 + minutes * 60.0 + seconds
        if len(parts) == 2:
            minutes = float(parts[0])
            seconds = float(parts[1])
            return minutes * 60.0 + seconds
        return float(text)
    except ValueError:
        return None


def summarize_mem(input_dir: pathlib.Path, output_path: pathlib.Path, sizes=None):
    rows = []
    for path in sorted(input_dir.glob("*.time.txt")):
        match = MEM_RE.match(path.name)
        if not match:
            continue
        n = int(match.group("n"))
        if sizes is not None and n not in sizes:
            continue

        lines = path.read_text(encoding="utf-8").splitlines()
        elapsed = parse_elapsed_seconds(parse_time_value(lines, "\tElapsed (wall clock) time"))
        user_s = parse_value(parse_time_value(lines, "\tUser time (seconds)"))
        sys_s = parse_value(parse_time_value(lines, "\tSystem time (seconds)"))
        rss_kb = parse_value(parse_time_value(lines, "\tMaximum resident set size (kbytes)"))

        rows.append({
            "case": match.group("case"),
            "n": n,
            "repeat": int(match.group("repeat")),
            "elapsed_wall_s": elapsed,
            "user_s": user_s,
            "sys_s": sys_s,
            "max_rss_kb": rss_kb,
        })

    fieldnames = ["case", "n", "repeat", "elapsed_wall_s", "user_s", "sys_s", "max_rss_kb"]
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow({k: fmt(v) if isinstance(v, float) else v for k, v in row.items()})


def main():
    parser = argparse.ArgumentParser(description="Summarize raw perf/time logs for experiment 4.5.3.")
    parser.add_argument("mode", choices=["perf", "mem"])
    parser.add_argument("--input-dir", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--sizes", nargs="*", type=int)
    args = parser.parse_args()

    input_dir = pathlib.Path(args.input_dir)
    output_path = pathlib.Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    sizes = set(args.sizes) if args.sizes else None

    if args.mode == "perf":
        summarize_perf(input_dir, output_path, sizes=sizes)
    else:
        summarize_mem(input_dir, output_path, sizes=sizes)


if __name__ == "__main__":
    main()
