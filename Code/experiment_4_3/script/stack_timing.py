#!/usr/bin/env python3
import argparse
import csv
import os


def load_csv(path):
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            rows.append(row)
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--routine", required=True, choices=["syev", "syevd"])
    ap.add_argument("--root", default="../output")
    ap.add_argument("--lib-a", default="openblas_sve", help="e.g. openblas_sve")
    ap.add_argument("--lib-b", default="openblas_scalar", help="e.g. openblas_scalar")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    a_csv = os.path.join(root, args.lib_a, f"{args.routine}_benchmark.csv")
    b_csv = os.path.join(root, args.lib_b, f"{args.routine}_benchmark.csv")
    if not os.path.isfile(a_csv) or not os.path.isfile(b_csv):
        raise SystemExit("Missing benchmark CSV for libs/routine")

    a_rows = load_csv(a_csv)
    b_rows = load_csv(b_csv)

    out_dir = os.path.join(root, "compare")
    os.makedirs(out_dir, exist_ok=True)
    out_path = args.out or os.path.join(
        out_dir, f"time_{args.routine}_stacked_{args.lib_a}_{args.lib_b}.csv"
    )

    if args.routine == "syev":
        stages = ["dsytrd_s", "dsteqr_s", "dorgtr_s"]
    else:
        stages = ["dsytrd_s", "dstedc_s", "dormtr_s"]

    header = ["routine", "threads", "N", "lib", "total_s"] + stages

    def key(row):
        return (int(row["threads"]), int(row["N"]))

    a_rows = sorted(a_rows, key=key)
    b_rows = sorted(b_rows, key=key)

    b_map = {key(r): r for r in b_rows}

    # Collect (threads,N) pairs for terminal comparison table
    table_rows = []
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        for row in a_rows:
            k = key(row)
            ta, na = int(row["threads"]), int(row["N"])
            total_a = float(row["total_s"])
            w.writerow([
                args.routine, row["threads"], row["N"], args.lib_a, row["total_s"],
                row[stages[0]], row[stages[1]], row[stages[2]],
            ])
            other = b_map.get(k)
            if other:
                total_b = float(other["total_s"])
                speedup = total_b / total_a if total_a > 0 else 0  # >1 means lib_a faster
                table_rows.append((ta, na, total_a, total_b, speedup))
                w.writerow([
                    args.routine, other["threads"], other["N"], args.lib_b, other["total_s"],
                    other[stages[0]], other[stages[1]], other[stages[2]],
                ])

    # --- Terminal table: SVE vs scalar timing and speedup ---
    print()
    print(f"  [{args.routine}] {args.lib_a} vs {args.lib_b}  timing (speedup = {args.lib_b}/{args.lib_a}, >1 = {args.lib_a} faster)")
    print("  " + "-" * 72)
    print(f"  {'T':>3} {'N':>6}   {args.lib_a:>12}   {args.lib_b:>12}   speedup")
    print("  " + "-" * 72)
    for t, n, total_a, total_b, speedup in table_rows:
        print(f"  {t:>3} {n:>6}   {total_a:>10.3f}s   {total_b:>10.3f}s   {speedup:.3f}x")
    print("  " + "-" * 72)
    if table_rows:
        avg_sp = sum(r[4] for r in table_rows) / len(table_rows)
        print(f"  Avg speedup ({args.lib_a} vs {args.lib_b}): {avg_sp:.3f}x")
    print(f"  CSV: {out_path}")
    print()


if __name__ == "__main__":
    main()
