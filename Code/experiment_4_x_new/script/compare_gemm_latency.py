#!/usr/bin/env python3
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SVE_CSV = ROOT / "output" / "openblas_sve" / "gemm" / "gemm_latency.csv"
SCALAR_CSV = ROOT / "output" / "openblas_scalar" / "gemm" / "gemm_latency.csv"
OUT_DIR = ROOT / "output" / "compare"
OUT_CSV = OUT_DIR / "gemm_latency_compare.csv"


def read_rows(path: Path):
    rows = {}
    with path.open("r", newline="") as f:
        for row in csv.DictReader(f):
            key = (int(row["threads"]), int(row["n"]))
            rows[key] = row
    return rows


def main() -> int:
    if not SVE_CSV.exists() or not SCALAR_CSV.exists():
        print("[X] Missing input CSV files.")
        print(f"    need: {SVE_CSV}")
        print(f"    need: {SCALAR_CSV}")
        print("    run: ./build_run.sh all")
        return 1

    sve = read_rows(SVE_CSV)
    scalar = read_rows(SCALAR_CSV)

    keys = sorted(set(sve.keys()) & set(scalar.keys()))
    if not keys:
        print("[X] No common (threads, n) rows between SVE and scalar results.")
        return 2

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "threads", "n",
            "sve_avg_s", "scalar_avg_s",
            "speedup_scalar_over_sve", "speedup_sve_over_scalar",
            "sve_gflops", "scalar_gflops",
        ])

        print("threads  N      sve_avg(s)   scalar_avg(s)   scalar/sve   sve/scalar")
        print("----------------------------------------------------------------------")
        for key in keys:
            t, n = key
            sve_avg = float(sve[key]["avg_s"])
            scalar_avg = float(scalar[key]["avg_s"])
            sve_gflops = float(sve[key]["gflops_avg"])
            scalar_gflops = float(scalar[key]["gflops_avg"])

            speedup_scalar_over_sve = scalar_avg / sve_avg if sve_avg > 0 else 0.0
            speedup_sve_over_scalar = sve_avg / scalar_avg if scalar_avg > 0 else 0.0

            w.writerow([
                t, n,
                f"{sve_avg:.9f}", f"{scalar_avg:.9f}",
                f"{speedup_scalar_over_sve:.6f}", f"{speedup_sve_over_scalar:.6f}",
                f"{sve_gflops:.6f}", f"{scalar_gflops:.6f}",
            ])

            print(
                f"{t:<8d} {n:<6d} {sve_avg:<12.6f} {scalar_avg:<14.6f} "
                f"{speedup_scalar_over_sve:<11.4f} {speedup_sve_over_scalar:<10.4f}"
            )

    print(f"\nSaved compare CSV: {OUT_CSV}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
