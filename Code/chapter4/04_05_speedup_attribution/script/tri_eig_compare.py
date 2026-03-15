#!/usr/bin/env python3
"""
Compare DSTEQR (syev) vs DSTEDC (syevd) Tri-eig timing within same OpenBLAS.
Output: table, CSV, optional plot of Tri-eig time vs N.
"""
import argparse
import csv
import os

def load_csv(path):
    with open(path, "r", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def main():
    ap = argparse.ArgumentParser(
        description="Compare DSTEQR vs DSTEDC Tri-eig timing (same OpenBLAS)"
    )
    ap.add_argument("--root", default="../output", help="Output root (e.g. ../output or ../../04_04_sve_vectorization/output)")
    ap.add_argument("--lib", default="openblas", help="Library dir (e.g. openblas or openblas_sve)")
    ap.add_argument("--out", default=None, help="Output CSV path (default: root/compare/time_tri_eig_steqr_vs_stedc.csv)")
    ap.add_argument("--plot", action="store_true", help="Plot Tri-eig time vs N (requires matplotlib)")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    lib_dir = os.path.join(root, args.lib)
    syev_csv = os.path.join(lib_dir, "syev_benchmark.csv")
    syevd_csv = os.path.join(lib_dir, "syevd_benchmark.csv")

    if not os.path.isfile(syev_csv):
        raise SystemExit(f"Missing {syev_csv}")
    if not os.path.isfile(syevd_csv):
        raise SystemExit(f"Missing {syevd_csv}")

    syev_rows = load_csv(syev_csv)
    syevd_rows = load_csv(syevd_csv)

    syev_map = {(int(r["threads"]), int(r["N"])): r for r in syev_rows}
    syevd_map = {(int(r["threads"]), int(r["N"])): r for r in syevd_rows}

    common_keys = sorted(set(syev_map.keys()) & set(syevd_map.keys()))
    if not common_keys:
        raise SystemExit("No common (threads,N) between syev and syevd CSVs")

    out_dir = os.path.join(root, "compare")
    os.makedirs(out_dir, exist_ok=True)
    out_csv = args.out or os.path.join(out_dir, "time_tri_eig_steqr_vs_stedc.csv")

    rows = []
    print()
    print("  Tri-eig: DSTEQR (syev) vs DSTEDC (syevd) — same OpenBLAS")
    print("  " + "-" * 70)
    print(f"  {'T':>3} {'N':>6}   {'DSTEQR(s)':>10}   {'DSTEDC(s)':>10}   speedup (STEDC faster)")
    print("  " + "-" * 70)

    for (t, n) in common_keys:
        r_ev = syev_map[(t, n)]
        r_evd = syevd_map[(t, n)]
        steqr_s = float(r_ev["dsteqr_s"])
        stedc_s = float(r_evd["dstedc_s"])
        speedup = steqr_s / stedc_s if stedc_s > 0 else 0
        rows.append((t, n, steqr_s, stedc_s, speedup))
        print(f"  {t:>3} {n:>6}   {steqr_s:>10.3f}   {stedc_s:>10.3f}   {speedup:.2f}x")

    print("  " + "-" * 70)
    if rows:
        avg_sp = sum(r[4] for r in rows) / len(rows)
        print(f"  Avg speedup (DSTEDC vs DSTEQR): {avg_sp:.2f}x")
    print()

    with open(out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["threads", "N", "dsteqr_s", "dstedc_s", "speedup"])
        for t, n, se, sd, sp in rows:
            w.writerow([t, n, round(se, 6), round(sd, 6), round(sp, 4)])
    print(f"  CSV: {out_csv}")

    if args.plot and rows:
        try:
            import matplotlib.pyplot as plt
            ns = [r[1] for r in rows]
            steqr_t = [r[2] for r in rows]
            stedc_t = [r[3] for r in rows]
            plt.figure(figsize=(8, 5))
            plt.plot(ns, steqr_t, "o-", label="DSTEQR (syev)")
            plt.plot(ns, stedc_t, "s-", label="DSTEDC (syevd)")
            plt.xlabel("N")
            plt.ylabel("Tri-eig time (s)")
            plt.title("Tri-eig: DSTEQR vs DSTEDC (OpenBLAS)")
            plt.legend()
            plt.grid(True, alpha=0.3)
            plot_path = os.path.join(out_dir, "tri_eig_steqr_vs_stedc.png")
            plt.savefig(plot_path, dpi=120)
            plt.close()
            print(f"  Plot: {plot_path}")
        except ImportError:
            print("  [Skip plot] matplotlib not installed")


if __name__ == "__main__":
    main()
