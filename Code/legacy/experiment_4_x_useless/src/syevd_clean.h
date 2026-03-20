#ifndef SYEVD_CLEAN_H
#define SYEVD_CLEAN_H

/* Clean C symmetric eigen-solver (teaching version).
 * - Column-major storage (LAPACK style).
 * - A is overwritten by eigenvectors on exit.
 * - W holds eigenvalues in ascending order.
 * Returns 0 on success, nonzero on failure.
 */
int syevd_clean(int n, double *A, int lda, double *W);

#endif
