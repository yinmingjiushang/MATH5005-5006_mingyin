#!/usr/bin/env python3
import argparse
import csv
import math
import os
import re

RUN_RE = re.compile(r"run_T(\d+)_N(\d+)$")


def parse_eigenvalues(path):
    vals = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            vals.append(float(line))
    return vals


def parse_eigenvectors(path):
    n = None
    rows = None
    vals = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.startswith("#"):
                if "full_n=" in line and n is None:
                    m = re.search(r"full_n=(\d+)", line)
                    if m:
                        n = int(m.group(1))
                if "rows" in line and rows is None:
                    m = re.search(r"rows 0\.\.(\d+)", line)
                    if m:
                        rows = int(m.group(1)) + 1
                continue
            vals.append(float(line))
    if n is None:
        raise ValueError(f"Failed to parse full_n from header in {path}")
    if rows is None:
        rows = n
    if len(vals) % rows != 0:
        raise ValueError(f"Vector count not divisible by rows in {path}")
    k = len(vals) // rows
    # Column-major: first column length rows, then next, ...
    cols = []
    for j in range(k):
        cols.append(vals[j * rows:(j + 1) * rows])
    return cols


def max_abs_diff(a, b):
    return max(abs(x - y) for x, y in zip(a, b))


def max_rel_diff(a, b, eps=1e-30):
    max_rel = 0.0
    for x, y in zip(a, b):
        denom = max(abs(y), eps)
        max_rel = max(max_rel, abs(x - y) / denom)
    return max_rel


def vector_dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def compare_vectors(cols_a, cols_b):
    if len(cols_a) != len(cols_b):
        raise ValueError("Eigenvector column count mismatch")
    max_col = 0.0
    for va, vb in zip(cols_a, cols_b):
        if vector_dot(va, vb) < 0.0:
            vb = [-x for x in vb]
        max_col = max(max_col, max_abs_diff(va, vb))
    return max_col


def collect_runs(root):
    runs = {}
    for entry in os.listdir(root):
        p = os.path.join(root, entry)
        if not os.path.isdir(p):
            continue
        m = RUN_RE.match(entry)
        if not m:
            continue
        t, n = int(m.group(1)), int(m.group(2))
        runs[(t, n)] = p
    return runs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lib-a", required=True)
    ap.add_argument("--lib-b", required=True)
    ap.add_argument("--routine", required=True, choices=["syev", "syevd"])
    ap.add_argument("--root", default="../output")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    a_root = os.path.join(root, args.lib_a, args.routine)
    b_root = os.path.join(root, args.lib_b, args.routine)
    if not os.path.isdir(a_root) or not os.path.isdir(b_root):
        raise SystemExit("Missing output directories for libs/routine")

    runs_a = collect_runs(a_root)
    runs_b = collect_runs(b_root)
    keys = sorted(set(runs_a.keys()) & set(runs_b.keys()))
    if not keys:
        raise SystemExit("No matching run_T*_N* directories between libs")

    out_dir = os.path.join(root, "compare")
    os.makedirs(out_dir, exist_ok=True)
    out_path = args.out or os.path.join(
        out_dir, f"{args.routine}_{args.lib_a}_vs_{args.lib_b}.csv"
    )

    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([
            "lib_a", "lib_b", "routine", "threads", "N",
            "max_abs_eval", "max_rel_eval", "max_abs_evec"
        ])
        for t, n in keys:
            ea = parse_eigenvalues(os.path.join(runs_a[(t, n)], "eigenvalues.txt"))
            eb = parse_eigenvalues(os.path.join(runs_b[(t, n)], "eigenvalues.txt"))
            if len(ea) != len(eb):
                raise ValueError(f"Eigenvalue count mismatch for T={t} N={n}")
            va = parse_eigenvectors(os.path.join(runs_a[(t, n)], "eigenvectors.txt"))
            vb = parse_eigenvectors(os.path.join(runs_b[(t, n)], "eigenvectors.txt"))
            if len(va) != len(vb):
                raise ValueError(f"Eigenvector column mismatch for T={t} N={n}")

            max_abs_eval = max_abs_diff(ea, eb)
            max_rel_eval = max_rel_diff(ea, eb)
            max_abs_evec = compare_vectors(va, vb)
            w.writerow([
                args.lib_a, args.lib_b, args.routine, t, n,
                f"{max_abs_eval:.6e}", f"{max_rel_eval:.6e}", f"{max_abs_evec:.6e}"
            ])

    print(f"[OK] Wrote comparison: {out_path}")


if __name__ == "__main__":
    main()
