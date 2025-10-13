# -*- coding: utf-8 -*-
"""
Benchmark DSYEV (QR) vs DSYEVD (Divide & Conquer)
Compare both N (eigenvalues only) and V (eigenvalues + eigenvectors)
for symmetric dense matrices of various sizes.

Outputs:
- ./output/result_table.txt (pretty table)
- ./output/result_table.csv (CSV)
- ./output/env.txt (environment info)
"""

import os
# --- Pin BLAS threads to 1 for fair single-thread timing ---
os.environ["OPENBLAS_NUM_THREADS"] = "1"
os.environ["OMP_NUM_THREADS"]      = "1"
os.environ["MKL_NUM_THREADS"]      = "1"
os.environ["NUMEXPR_NUM_THREADS"]  = "1"

import time
import platform
import numpy as np
import pandas as pd
import scipy as sp
from scipy.linalg import lapack

# ------------------ Config ---------------------
sizes = [500, 1000, 2000, 4000, 8000]   # adjust as needed
reps  = 5                                # number of repeats per measurement
seed  = 0                                # RNG seed for reproducibility

output_dir = "./output"
os.makedirs(output_dir, exist_ok=True)
txt_file = os.path.join(output_dir, "result_table.txt")
csv_file = os.path.join(output_dir, "result_table.csv")
env_file = os.path.join(output_dir, "env.txt")

# ------------------ Utilities ---------------------
def time_call(func, *args, **kwargs):
    """Time a single call and return (output, elapsed_seconds)."""
    t0 = time.perf_counter()
    out = func(*args, **kwargs)
    t1 = time.perf_counter()
    return out, (t1 - t0)

def median_time(func, reps, *args, **kwargs):
    """Run `func` `reps` times, return (last_output, median_seconds)."""
    times = []
    out = None
    for _ in range(reps):
        out, dt = time_call(func, *args, **kwargs)
        times.append(dt)
    return out, float(np.median(times))

def make_symmetric_f(n, rng):
    """
    Create a symmetric matrix in Fortran order to avoid internal copying.
    """
    A = rng.standard_normal((n, n))
    A = (A + A.T) * 0.5
    return np.asfortranarray(A)

def write_env(path):
    """Save minimal environment info for reproducibility."""
    with open(path, "w") as f:
        f.write(f"Platform : {platform.platform()}\n")
        f.write(f"Processor: {platform.processor()}\n")
        f.write(f"Python   : {platform.python_version()}\n")
        f.write(f"NumPy    : {np.__version__}\n")
        f.write(f"SciPy    : {sp.__version__}\n")
        # Optional: record BLAS vendor if available
        try:
            import numpy.distutils.system_info as sysinfo
            f.write("\n[BLAS/LAPACK hints]\n")
            f.write(str(sysinfo.get_info('blas')) + "\n")
            f.write(str(sysinfo.get_info('lapack')) + "\n")
        except Exception:
            pass

# ------------------ Warm-up  ---------------------
def warmup():
    rng = np.random.default_rng(12345)
    A = make_symmetric_f(64, rng)
    # DSYEV N/V
    lapack.dsyev(A.copy(order='F'), 0, 0)
    lapack.dsyev(A.copy(order='F'), 1, 0)
    # DSYEVD N/V
    lapack.dsyevd(A.copy(order='F'), 0, 0)
    lapack.dsyevd(A.copy(order='F'), 1, 0)

# ------------------ Benchmark ---------------------
def run_benchmark(sizes, reps, seed):
    np.random.seed(seed)
    rng = np.random.default_rng(seed)
    rows = []  # columns: N, dsyev_N, dsyev_V, dsyevd_N, dsyevd_V, speedup_N, speedup_V

    print("=== Benchmark: DSYEV (QR) vs DSYEVD (Divide & Conquer) ===")
    print(f"Repetitions per point: {reps} (median reported)")
    for n in sizes:
        # prepare symmetric matrix in Fortran order once per size
        A = make_symmetric_f(n, rng)

        print(f"\n--- N = {n} ---")

        # ---------- DSYEV (QR) ----------
        # N: eigenvalues only
        (_, _, info_qr_N), t_qr_N = median_time(
            lapack.dsyev, reps, A.copy(order='F'), 0, 0  # compute_v=0, lower=0 (upper)
        )
        if info_qr_N != 0:
            raise RuntimeError(f"DSYEV(N) failed for n={n}, INFO={info_qr_N}")
        print(f"DSYEV  (N):  {t_qr_N:.3f} s  (median of {reps})")

        # V: eigenvalues + eigenvectors
        (_, _, info_qr_V), t_qr_V = median_time(
            lapack.dsyev, reps, A.copy(order='F'), 1, 0  # compute_v=1, lower=0
        )
        if info_qr_V != 0:
            raise RuntimeError(f"DSYEV(V) failed for n={n}, INFO={info_qr_V}")
        print(f"DSYEV  (V):  {t_qr_V:.3f} s  (median of {reps})")

        # ---------- DSYEVD (Divide & Conquer) ----------
        # N: eigenvalues only
        (_, _, info_dc_N), t_dc_N = median_time(
            lapack.dsyevd, reps, A.copy(order='F'), 0, 0  # compute_v=0, lower=0
        )
        if info_dc_N != 0:
            raise RuntimeError(f"DSYEVD(N) failed for n={n}, INFO={info_dc_N}")
        print(f"DSYEVD (N):  {t_dc_N:.3f} s  (median of {reps})")

        # V: eigenvalues + eigenvectors
        (_, _, info_dc_V), t_dc_V = median_time(
            lapack.dsyevd, reps, A.copy(order='F'), 1, 0  # compute_v=1, lower=0
        )
        if info_dc_V != 0:
            raise RuntimeError(f"DSYEVD(V) failed for n={n}, INFO={info_dc_V}")
        print(f"DSYEVD (V):  {t_dc_V:.3f} s  (median of {reps})")

        # Speedups (QR/DC) > 1 means DSYEVD is faster
        speedup_N = t_qr_N / t_dc_N if t_dc_N > 0 else np.nan
        speedup_V = t_qr_V / t_dc_V if t_dc_V > 0 else np.nan

        rows.append([n, t_qr_N, t_qr_V, t_dc_N, t_dc_V, speedup_N, speedup_V])

    # Build DataFrame
    df = pd.DataFrame(
        rows,
        columns=[
            "Matrix Size (N)",
            "DSYEV (N) [s]",
            "DSYEV (V) [s]",
            "DSYEVD (N) [s]",
            "DSYEVD (V) [s]",
            "Speedup N (QR/DC)",
            "Speedup V (QR/DC)",
        ],
    )
    return df

# ------------------ Main ---------------------
if __name__ == "__main__":
    write_env(env_file)
    warmup()
    df = run_benchmark(sizes, reps, seed)

    # Pretty TXT
    with open(txt_file, "w") as f:
        f.write("Benchmark: DSYEV (QR) vs DSYEVD (Divide & Conquer)\n")
        f.write("Comparing N (eigenvalues only) vs V (eigenvalues + eigenvectors)\n")
        f.write(f"Repetitions per point: {reps} (median)\n\n")
        f.write(df.to_string(index=False, float_format=lambda x: f"{x:.3f}"))

    # CSV
    df.to_csv(csv_file, index=False, float_format="%.6f")

    # Console echo
    print("\n=== Benchmark Completed ===")
    print(df.to_string(index=False, float_format=lambda x: f"{x:.3f}"))
    print(f"\nResults saved to:\n- {txt_file}\n- {csv_file}\n- {env_file}")
