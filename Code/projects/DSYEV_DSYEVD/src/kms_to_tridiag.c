// kms_to_tridiag.c — Build KMS SPD, reduce with DSYTRD, return tridiagonal D,E.
// Portable: no LAPACKE, vendor-agnostic Fortran symbols.

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* Fortran LAPACK symbols */
extern void dsytrd_(const char *UPLO, const int *N,
                    double *A, const int *LDA,
                    double *D, double *E, double *TAU,
                    double *WORK, const int *LWORK, int *INFO);

/* KMS filler: A_ij = rho^{|i-j|} + delta * (i==j), column-major */
static void fill_kms(double *A, int n, double rho, double delta)
{
    if (!(rho > -1.0 && rho < 1.0)) rho = 0.95;
    if (delta < 0.0) delta = 0.0;

    double arho = fabs(rho);
    double *rp = (double*)malloc((size_t)n * sizeof(double));
    if (!rp) { fprintf(stderr, "alloc rp failed\n"); exit(10); }
    rp[0] = 1.0;
    for (int k = 1; k < n; ++k) rp[k] = rp[k-1] * arho;

    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            int d = j - i;
            double v = rp[d];
            if (i == j) v += delta;
            A[i + (size_t)j * n] = v;
            A[j + (size_t)i * n] = v;
        }
    }
    free(rp);
}

/* Public API:
   - Build KMS A (rho,delta), reduce to tridiagonal with DSYTRD (UPLO='U').
   - Output:
       D[0..n-1] = diagonal of T
       E[0..n-2] = off-diagonal of T  (E has length n-1; the last entry is unused by LAPACK)
   - Returns 0 on success, nonzero on failure. */
int kms_to_tridiag(int n, double rho, double delta, double *D, double *E)
{
    if (n <= 0 || !D || !E) return -1;
    int lda = n, info = 0, lwork = -1;
    char uplo = 'U';

    /* 1) Allocate and fill dense KMS matrix */
    double *A   = (double*)malloc((size_t)n * (size_t)n * sizeof(double));
    double *TAU = (double*)malloc((size_t)n * sizeof(double)); /* DSYTRD needs TAU (n-1 used) */
    if (!A || !TAU) { free(A); free(TAU); return -2; }
    fill_kms(A, n, rho, delta);

    /* 2) Workspace query for DSYTRD */
    double wkopt;
    dsytrd_(&uplo, &n, A, &lda, D, E, TAU, &wkopt, &lwork, &info);
    if (info != 0) { free(TAU); free(A); return -3; }

    lwork = (int)wkopt;
    if (lwork < 1) lwork = 1;
    double *WORK = (double*)malloc((size_t)lwork * sizeof(double));
    if (!WORK) { free(TAU); free(A); return -4; }

    /* 3) Actual reduction: A -> T (D,E,TAU), reflectors stored in A (not needed for STEDC) */
    dsytrd_(&uplo, &n, A, &lda, D, E, TAU, WORK, &lwork, &info);

    free(WORK);
    free(TAU);
    free(A);
    return info; /* 0 = success */
}
