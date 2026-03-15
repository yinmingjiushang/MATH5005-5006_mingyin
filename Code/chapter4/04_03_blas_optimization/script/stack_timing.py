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
    ap.add_argument("--lib-a", default="lapack")
    ap.add_argument("--lib-b", default="openblas")
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

    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        for row in a_rows:
            w.writerow([
                args.routine, row["threads"], row["N"], args.lib_a, row["total_s"],
                row[stages[0]], row[stages[1]], row[stages[2]],
            ])
            other = b_map.get(key(row))
            if other:
                w.writerow([
                    args.routine, other["threads"], other["N"], args.lib_b, other["total_s"],
                    other[stages[0]], other[stages[1]], other[stages[2]],
                ])

    print(f"[OK] Wrote stacked timing table: {out_path}")


if __name__ == "__main__":
    main()
