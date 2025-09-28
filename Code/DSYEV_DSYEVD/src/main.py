# -*- coding: utf-8 -*-
"""
Benchmark DSYEV (QR) vs DSYEVD (Divide & Conquer)
for N = 500, 1000, 2000, 4000, 8000 symmetric dense matrices.
Compute eigenvalues + eigenvectors, write results to output/result.txt.
"""

import os

os.environ["OPENBLAS_NUM_THREADS"] = "1"   # OpenBLAS(pthreads)
os.environ["OMP_NUM_THREADS"]      = "1"   # OpenBLAS(OpenMP) / MKL(OpenMP)
os.environ["MKL_NUM_THREADS"]      = "1"
os.environ["NUMEXPR_NUM_THREADS"]  = "1"


import numpy as np
import time
from scipy.linalg import lapack

# ------------------ Config ---------------------
# sizes = [500, 1000, 2000, 4000, 8000]
sizes = [4000]
output_dir = "../output"
output_file = os.path.join(output_dir, "result.txt")

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# Open file for writing
with open(output_file, "w") as f:
    f.write("Benchmark: DSYEV (QR) vs DSYEVD (Divide & Conquer)\n")
    f.write("Compute eigenvalues + eigenvectors\n\n")

    for n in sizes:
        # Generate random symmetric matrix
        A = np.random.randn(n, n)
        A = (A + A.T) / 2.0  # ensure symmetry

        print(f"\n=== N = {n} ===")
        f.write(f"=== N = {n} ===\n")

        # DSYEV (QR algorithm)
        t0 = time.perf_counter()
        w_qr, v_qr, info_qr = lapack.dsyev(A, compute_v=1, overwrite_a=0)
        t1 = time.perf_counter()
        if info_qr != 0:
            raise RuntimeError(f"DSYEV failed for n={n}, INFO={info_qr}")
        qr_time = t1 - t0
        print(f"DSYEV  (QR):  {qr_time:.3f} s")
        f.write(f"DSYEV  (QR):  {qr_time:.3f} s\n")

        # DSYEVD (Divide & Conquer)
        t2 = time.perf_counter()
        w_dc, v_dc, info_dc = lapack.dsyevd(A, compute_v=1, overwrite_a=0)
        t3 = time.perf_counter()
        if info_dc != 0:
            raise RuntimeError(f"DSYEVD failed for n={n}, INFO={info_dc}")
        dc_time = t3 - t2
        print(f"DSYEVD (DC):  {dc_time:.3f} s")
        f.write(f"DSYEVD (DC):  {dc_time:.3f} s\n\n")

print(f"\nResults written to: {output_file}")
