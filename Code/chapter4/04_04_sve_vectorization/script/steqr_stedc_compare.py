#!/usr/bin/env python3
"""Compare only DSTEQR (syev) and DSTEDC (syevd) timing: SVE vs SIMD baseline."""
import argparse
import csv
import os


def load_csv(path):
    with open(path, "r", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def main():
    ap = argparse.ArgumentParser(description="Compare DSTEQR and DSTEDC only (SVE vs SIMD baseline)")
    ap.add_argument("--root", default="../output")
    ap.add_argument("--lib-a", default="openblas_sve")
    ap.add_argument("--lib-b", default="openblas_simd")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    out_dir = os.path.join(root, "compare")
    os.makedirs(out_dir, exist_ok=True)

    # ---- DSTEQR (syev) ----
    a_syev = load_csv(os.path.join(root, args.lib_a, "syev_benchmark.csv"))
    b_syev = load_csv(os.path.join(root, args.lib_b, "syev_benchmark.csv"))
    b_syev_map = {(int(r["threads"]), int(r["N"])): r for r in b_syev}

    print()
    print("  [syev] DSTEQR only — openblas_sve vs openblas_simd")
    print("  " + "-" * 60)
    print(f"  {'T':>3} {'N':>6}   {args.lib_a:>12}   {args.lib_b:>12}   speedup")
    print("  " + "-" * 60)

    steqr_rows = []
    for r in sorted(a_syev, key=lambda x: (int(x["threads"]), int(x["N"]))):
        t, n = int(r["threads"]), int(r["N"])
        a_val = float(r["dsteqr_s"])
        other = b_syev_map.get((t, n))
        if not other:
            continue
        b_val = float(other["dsteqr_s"])
        speedup = b_val / a_val if a_val > 0 else 0  # >1 = SVE faster
        steqr_rows.append((t, n, a_val, b_val, speedup))
        print(f"  {t:>3} {n:>6}   {a_val:>10.3f}s   {b_val:>10.3f}s   {speedup:.3f}x")
    print("  " + "-" * 60)
    if steqr_rows:
        avg = sum(x[4] for x in steqr_rows) / len(steqr_rows)
        print(f"  Avg speedup (SVE vs SIMD baseline, DSTEQR only): {avg:.3f}x")
    print()

    # ---- DSTEDC (syevd) ----
    a_syevd = load_csv(os.path.join(root, args.lib_a, "syevd_benchmark.csv"))
    b_syevd = load_csv(os.path.join(root, args.lib_b, "syevd_benchmark.csv"))
    b_syevd_map = {(int(r["threads"]), int(r["N"])): r for r in b_syevd}

    print("  [syevd] DSTEDC only — openblas_sve vs openblas_simd")
    print("  " + "-" * 60)
    print(f"  {'T':>3} {'N':>6}   {args.lib_a:>12}   {args.lib_b:>12}   speedup")
    print("  " + "-" * 60)

    stedc_rows = []
    for r in sorted(a_syevd, key=lambda x: (int(x["threads"]), int(x["N"]))):
        t, n = int(r["threads"]), int(r["N"])
        a_val = float(r["dstedc_s"])
        other = b_syevd_map.get((t, n))
        if not other:
            continue
        b_val = float(other["dstedc_s"])
        speedup = b_val / a_val if a_val > 0 else 0  # >1 = SVE faster
        stedc_rows.append((t, n, a_val, b_val, speedup))
        print(f"  {t:>3} {n:>6}   {a_val:>10.3f}s   {b_val:>10.3f}s   {speedup:.3f}x")
    print("  " + "-" * 60)
    if stedc_rows:
        avg = sum(x[4] for x in stedc_rows) / len(stedc_rows)
        print(f"  Avg speedup (SVE vs SIMD baseline, DSTEDC only): {avg:.3f}x")
    print()

    # ---- CSV: DSTEQR ----
    steqr_csv = os.path.join(out_dir, "time_dsteqr_only_openblas_sve_openblas_simd.csv")
    with open(steqr_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["routine", "threads", "N", "lib_a_s", "lib_b_s", "speedup"])
        for t, n, va, vb, sp in steqr_rows:
            w.writerow(["syev", t, n, round(va, 6), round(vb, 6), round(sp, 4)])
    print(f"  CSV (DSTEQR): {steqr_csv}")

    # ---- CSV: DSTEDC ----
    stedc_csv = os.path.join(out_dir, "time_dstedc_only_openblas_sve_openblas_simd.csv")
    with open(stedc_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["routine", "threads", "N", "lib_a_s", "lib_b_s", "speedup"])
        for t, n, va, vb, sp in stedc_rows:
            w.writerow(["syevd", t, n, round(va, 6), round(vb, 6), round(sp, 4)])
    print(f"  CSV (DSTEDC): {stedc_csv}")
    print()


if __name__ == "__main__":
    main()
