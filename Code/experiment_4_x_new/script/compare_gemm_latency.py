#!/usr/bin/env python3
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SVE_CSV = ROOT / "output" / "openblas_sve" / "gemm" / "gemm_latency.csv"
SIMD_CSV = ROOT / "output" / "openblas_simd" / "gemm" / "gemm_latency.csv"
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
    if not SVE_CSV.exists() or not SIMD_CSV.exists():
        print("[X] Missing input CSV files.")
        print(f"    need: {SVE_CSV}")
        print(f"    need: {SIMD_CSV}")
        print("    run: ./build_run.sh all")
        return 1

    sve = read_rows(SVE_CSV)
    simd = read_rows(SIMD_CSV)

    keys = sorted(set(sve.keys()) & set(simd.keys()))
    if not keys:
        print("[X] No common (threads, n) rows between SVE and SIMD-baseline results.")
        return 2

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow([
            "threads", "n",
            "sve_avg_s", "simd_avg_s",
            "speedup_simd_over_sve", "speedup_sve_over_simd",
            "sve_gflops", "simd_gflops",
        ])

        print("threads  N      sve_avg(s)   simd_avg(s)     simd/sve     sve/simd")
        print("----------------------------------------------------------------------")
        for key in keys:
            t, n = key
            sve_avg = float(sve[key]["avg_s"])
            simd_avg = float(simd[key]["avg_s"])
            sve_gflops = float(sve[key]["gflops_avg"])
            simd_gflops = float(simd[key]["gflops_avg"])

            speedup_simd_over_sve = simd_avg / sve_avg if sve_avg > 0 else 0.0
            speedup_sve_over_simd = sve_avg / simd_avg if simd_avg > 0 else 0.0

            w.writerow([
                t, n,
                f"{sve_avg:.9f}", f"{simd_avg:.9f}",
                f"{speedup_simd_over_sve:.6f}", f"{speedup_sve_over_simd:.6f}",
                f"{sve_gflops:.6f}", f"{simd_gflops:.6f}",
            ])

            print(
                f"{t:<8d} {n:<6d} {sve_avg:<12.6f} {simd_avg:<14.6f} "
                f"{speedup_simd_over_sve:<11.4f} {speedup_sve_over_simd:<10.4f}"
            )

    print(f"\nSaved compare CSV: {OUT_CSV}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
