# -*- coding: utf-8 -*-
"""
Benchmark DSTEVD (LAPACK divide & conquer solver for tridiagonal matrices)
for multiple matrix sizes N = 1000, 2000, 4000.
"""

import os
import time
import numpy as np
from scipy.linalg import lapack

# Optional: limit threads for reproducible timing
os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("MKL_NUM_THREADS", "1")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")

# Problem sizes
sizes = [4000]

for n in sizes:
    # --- Generate a random symmetric tridiagonal matrix ---------------------
    d = np.random.randn(n).astype(np.float64)        # diagonal elements
    e = np.random.randn(n - 1).astype(np.float64)    # off-diagonal elements

    # --- Solve using DSTEVD ------------------------------------------------
    t0 = time.perf_counter()
    vals, vecs, info = lapack.dstevd(d, e, compute_v=1, overwrite_d=0, overwrite_e=0)
    t1 = time.perf_counter()

    if info != 0:
        raise RuntimeError(f"DSTEVD failed for n={n}, INFO={info}")

    print(f"N = {n:4d} | Time = {t1 - t0:.3f} s | Eigenvalues computed = {vals.size}")
