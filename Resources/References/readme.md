# Reference Materials

This folder contains reference documents and online resources used in the project.

---

## Papers

- `Anderson1992_DivideAndConquer.pdf`
  *Original paper introducing the divide-and-conquer method for symmetric eigenvalue problems.*



---

## Web Resources

- [LAPACK Users' Guide](https://www.netlib.org/lapack/lug/)
  *General guide to LAPACK routines and their usage.*

- [DSYEV routine (Netlib)](https://www.netlib.org/lapack/explore-html/d2/d8a/group__double_s_yeigen.html)
  *Documentation for the DSYEV routine (QR-based solver for symmetric eigenproblems).*

- [DSYEVD routine (Netlib)](https://www.netlib.org/lapack/explore-html/d2/d8a/group__double_s_yeigen_ga694ddc6e5527b6223748e.html#ga694ddc6e5527b6223748e)
  *Documentation for the DSYEVD routine (Divide-and-Conquer solver for symmetric eigenproblems).*

- [LAPACK User’s Guide: Eigenvalue Problems](https://www.netlib.org/lapack/lug/node70.html)  
  Introduction of the divide-and-conquer algorithm `xSTEDC` (added in LAPACK v2.0), which is faster than the traditional `xSTEQR` because it leverages BLAS Level 2/3 operations.

- [LAPACK User’s Guide: Symmetric Eigenproblems](https://www.netlib.org/lapack/lug/node48.html#subseccompsep)  
  Overview of algorithms for symmetric eigenproblems. Highlights that the divide-and-conquer method `xSTEDC` is much faster than the traditional QR-based `xSTEQR` for large matrices, and that the RRR-based algorithm `xSTEGR` (LAPACK v3.0) is usually even faster and more memory-efficient than `xSTEDC`.

