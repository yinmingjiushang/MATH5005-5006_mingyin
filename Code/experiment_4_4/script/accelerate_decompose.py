#!/usr/bin/env python3
"""
实验 4.4：各因素加速贡献分解

基于 4.2（LAPACK vs OpenBLAS）和 4.3（SVE vs scalar）的数据，
量化以下因素的加速程度：
  1. 算法 (STEQR vs STEDC)
  2. BLAS 优化 (Reference BLAS → OpenBLAS)
  3. SVE (scalar → SVE)
  4. 归因：Tri-eig 对总加速的贡献占比

用法:
  python3 accelerate_decompose.py --root4_2 ../../experiment_4_2/output --root4_3 ../../experiment_4_3/output
"""
import argparse
import csv
import os


def load_stacked_csv(path):
    """Load stacked CSV (lapack/openblas or sve/scalar), return dict (t,n,lib) -> row"""
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    return {((int(r["threads"]), int(r["N"]), r["lib"]), r["routine"]): r for r in rows}


def load_simple_csv(path):
    """Load CSV with lib column, return list of rows"""
    with open(path, "r", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def main():
    ap = argparse.ArgumentParser(description="Acceleration decomposition (4.4)")
    ap.add_argument("--root4_2", default="../../experiment_4_2/output", help="4.2 output root")
    ap.add_argument("--root4_3", default="../../experiment_4_3/output", help="4.3 output root")
    ap.add_argument("--out", default=None, help="Output CSV path")
    args = ap.parse_args()

    root_42 = os.path.abspath(args.root4_2)
    root_43 = os.path.abspath(args.root4_3)

    compare_42 = os.path.join(root_42, "compare")
    compare_43 = os.path.join(root_43, "compare")

    # 4.2: LAPACK vs OpenBLAS
    syev_42 = os.path.join(compare_42, "time_syev_stacked_lapack_openblas.csv")
    syevd_42 = os.path.join(compare_42, "time_syevd_stacked_lapack_openblas.csv")
    # 4.3: SVE vs scalar
    syev_43 = os.path.join(compare_43, "time_syev_stacked_openblas_sve_openblas_scalar.csv")
    syevd_43 = os.path.join(compare_43, "time_syevd_stacked_openblas_sve_openblas_scalar.csv")

    for p in [syev_42, syevd_42, syev_43, syevd_43]:
        if not os.path.isfile(p):
            print(f"[WARN] Missing {p}")

    def get_42(routine, lib, t, n, col):
        path = syev_42 if routine == "syev" else syevd_42
        if not os.path.isfile(path):
            return None
        for row in load_simple_csv(path):
            if int(row["threads"]) == t and int(row["N"]) == n and row["lib"] == lib:
                return float(row.get(col, 0))
        return None

    def get_43(routine, lib, t, n, col):
        path = syev_43 if routine == "syev" else syevd_43
        if not os.path.isfile(path):
            return None
        for row in load_simple_csv(path):
            if int(row["threads"]) == t and int(row["N"]) == n and row["lib"] == lib:
                return float(row.get(col, 0))
        return None

    # Collect common N from available data
    all_n = set()
    for path in [syev_42, syevd_42, syev_43, syevd_43]:
        if os.path.isfile(path):
            for r in load_simple_csv(path):
                all_n.add(int(r["N"]))
    ns = sorted(all_n)

    print()
    print("=" * 80)
    print("  实验 4.4：各因素加速贡献分解")
    print("=" * 80)

    # ---- 1. 算法贡献 (STEQR vs DSTEDC, 同一 OpenBLAS) ----
    print()
    print("  1. 算法贡献：DSTEQR vs DSTEDC（同一 OpenBLAS SVE）")
    print("  " + "-" * 60)
    print(f"  {'N':>6}   {'DSTEQR(s)':>10}   {'DSTEDC(s)':>10}   加速比")
    print("  " + "-" * 60)

    algo_rows = []
    for n in ns:
        se = get_43("syev", "openblas_sve", 1, n, "dsteqr_s")
        sd = get_43("syevd", "openblas_sve", 1, n, "dstedc_s")
        if se is not None and sd is not None and sd > 0:
            sp = se / sd
            algo_rows.append((n, se, sd, sp))
            print(f"  {n:>6}   {se:>10.3f}   {sd:>10.3f}   {sp:.2f}x")
    print("  " + "-" * 60)
    if algo_rows:
        avg = sum(r[3] for r in algo_rows) / len(algo_rows)
        print(f"  平均算法加速：{avg:.2f}x")
    print()

    # ---- 2. BLAS 优化贡献 (LAPACK → OpenBLAS)，分阶段 ----
    print()
    print("  2. BLAS 优化贡献：Reference BLAS → OpenBLAS（各阶段加速比 = Lapack时间/OpenBLAS时间）")
    print("  " + "-" * 75)
    print(f"  {'N':>6}   {'DSYTRD':>8}   {'syev Tri':>10}   {'syevd Tri':>10}   {'DORGTR':>8}   {'DORMTR':>8}")
    print("  " + "-" * 75)

    blas_rows = []
    for n in ns:
        l_ds = get_42("syev", "lapack", 1, n, "dsytrd_s")
        o_ds = get_42("syev", "openblas", 1, n, "dsytrd_s")
        l_se = get_42("syev", "lapack", 1, n, "dsteqr_s")
        o_se = get_42("syev", "openblas", 1, n, "dsteqr_s")
        l_st = get_42("syevd", "lapack", 1, n, "dstedc_s")
        o_st = get_42("syevd", "openblas", 1, n, "dstedc_s")
        l_og = get_42("syev", "lapack", 1, n, "dorgtr_s")
        o_og = get_42("syev", "openblas", 1, n, "dorgtr_s")
        l_dm = get_42("syevd", "lapack", 1, n, "dormtr_s")
        o_dm = get_42("syevd", "openblas", 1, n, "dormtr_s")

        def fmt(a, b):
            return f"{a/b:.2f}x" if a and b and b > 0 else "-"

        p_ds = fmt(l_ds, o_ds)
        p_se = fmt(l_se, o_se)
        p_st = fmt(l_st, o_st)
        p_og = fmt(l_og, o_og)
        p_dm = fmt(l_dm, o_dm)
        print(f"  {n:>6}   {p_ds:>8}   {p_se:>10}   {p_st:>10}   {p_og:>8}   {p_dm:>8}")
        blas_rows.append((n, p_ds, p_se, p_st, p_og, p_dm))
    print("  " + "-" * 70)
    print("  注：syev Tri-eig ≈ 1× (DSTEQR 无 DGEMM)，syevd Tri-eig ≈ 2–4× (DSTEDC 有 DGEMM)")
    print()

    # ---- 3. SVE 贡献 (scalar → SVE)，分阶段 ----
    print()
    print("  3. SVE 贡献：scalar → SVE（各阶段加速比）")
    print("  " + "-" * 70)
    print(f"  {'N':>6}   {'syev DSYTRD':>10}   {'syev DSTEQR':>10}   {'syevd DSYTRD':>10}   {'syevd DSTEDC':>10}")
    print("  " + "-" * 70)

    sve_rows = []
    for n in ns:
        sc_ds = get_43("syev", "openblas_scalar", 1, n, "dsytrd_s")
        sv_ds = get_43("syev", "openblas_sve", 1, n, "dsytrd_s")
        sc_se = get_43("syev", "openblas_scalar", 1, n, "dsteqr_s")
        sv_se = get_43("syev", "openblas_sve", 1, n, "dsteqr_s")
        sc_dsd = get_43("syevd", "openblas_scalar", 1, n, "dsytrd_s")
        sv_dsd = get_43("syevd", "openblas_sve", 1, n, "dsytrd_s")
        sc_st = get_43("syevd", "openblas_scalar", 1, n, "dstedc_s")
        sv_st = get_43("syevd", "openblas_sve", 1, n, "dstedc_s")

        def sp(a, b):
            return f"{a/b:.2f}x" if b and b > 0 else "-"

        p1 = sp(sc_ds, sv_ds) if sc_ds and sv_ds else "-"
        p2 = sp(sc_se, sv_se) if sc_se and sv_se else "-"
        p3 = sp(sc_dsd, sv_dsd) if sc_dsd and sv_dsd else "-"
        p4 = sp(sc_st, sv_st) if sc_st and sv_st else "-"
        print(f"  {n:>6}   {p1:>10}   {p2:>10}   {p3:>10}   {p4:>10}")
        sve_rows.append((n, p1, p2, p3, p4))
    print("  " + "-" * 70)
    print("  注：DSTEQR 的 SVE 加速 ≈ 1×，DSTEDC 的 SVE 加速 ≈ 1.1–1.2×")
    print()

    # ---- 4. 归因：Tri-eig 对总加速的贡献 ----
    print()
    print("  4. 归因：Tri-eig 对 syev→syevd 总加速的贡献")
    print("  " + "-" * 70)
    print(f"  {'N':>6}   {'syev总(s)':>10}   {'syevd总(s)':>10}   {'总加速':>8}   {'Tri-eig节省':>12}   {'贡献%':>8}")
    print("  " + "-" * 70)

    attr_rows = []
    for n in ns:
        tv = get_43("syev", "openblas_sve", 1, n, "total_s")
        tvd = get_43("syevd", "openblas_sve", 1, n, "total_s")
        se = get_43("syev", "openblas_sve", 1, n, "dsteqr_s")
        sd = get_43("syevd", "openblas_sve", 1, n, "dstedc_s")
        if tv and tvd and tvd > 0 and se is not None and sd is not None:
            total_sp = tv / tvd
            tri_saved = se - sd
            total_saved = tv - tvd
            contrib = (tri_saved / total_saved * 100) if total_saved > 0 else 0
            attr_rows.append((n, tv, tvd, total_sp, tri_saved, contrib))
            note = " (>100%: 回变换略慢)" if contrib > 100 else ""
            print(f"  {n:>6}   {tv:>10.3f}   {tvd:>10.3f}   {total_sp:>7.2f}x   {tri_saved:>10.3f}s   {contrib:>6.1f}%{note}")
    print("  " + "-" * 70)
    print("  注：>100% 表示 Tri-eig 节省超过总节省（syevd 回变换 DORMTR 略慢于 syev 的 DORGTR）")
    print()

    # ---- 5. 综合小结 ----
    print()
    print("  5. 综合小结：各因素加速程度")
    print("  " + "-" * 70)
    print("  | 因素            | 作用对象      | 典型加速比    | 说明")
    print("  |-----------------|---------------|---------------|----------------------------------|")
    print("  | 算法(STEQR→STEDC)| Tri-eig       | ~10–25×       | DSTEDC 用 DGEMM，STEQR 无")
    print("  | BLAS(ref→OpenBLAS)| DSTEDC       | ~2–4×         | OpenBLAS 的 DGEMM 优于 ref BLAS")
    print("  | BLAS(ref→OpenBLAS)| DSTEQR       | ~1×           | DSTEQR 无 DGEMM，换 BLAS 无益")
    print("  | SVE(scalar→SVE) | DSTEDC        | ~1.1–1.2×     | SVE 对 DGEMM 有 modest 增益")
    print("  | SVE(scalar→SVE) | DSTEQR        | ~1×           | DSTEQR 无向量化机会")
    print("  " + "-" * 70)
    print()

    # Output CSV
    out_path = args.out
    if out_path is None:
        # default: experiment_4_4/output/compare (sibling of experiment_4_3)
        out_dir = os.path.join(os.path.dirname(os.path.dirname(root_43)), "experiment_4_4", "output", "compare")
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "accelerate_decompose.csv")

    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["section", "N", "dsteqr_s", "dstedc_s", "algo_speedup", "contrib_pct"])
        for n, se, sd, sp in algo_rows:
            w.writerow(["algo", n, round(se, 4), round(sd, 4), round(sp, 4), ""])
        for n, tv, tvd, total_sp, tri_saved, contrib in attr_rows:
            w.writerow(["attr", n, "", "", round(total_sp, 4), round(contrib, 2)])

    print(f"  CSV: {out_path}")
    print()


if __name__ == "__main__":
    main()
