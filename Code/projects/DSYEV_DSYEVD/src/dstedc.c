// test_stedc.c — Example driver to run DSTEDC on the tridiagonal from KMS.
#include <stdio.h>
#include <stdlib.h>

/* From the file above */
int kms_to_tridiag(int n, double rho, double delta, double *D, double *E);

/* LAPACK: DSTEDC — eigen of symmetric tridiagonal via divide & conquer */
extern void dstedc_(const char *COMPZ, const int *N,
                    double *D, double *E,
                    double *Z, const int *LDZ,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

int main(void)
{
    const int n = 4000;
    double *D = (double*)malloc((size_t)n * sizeof(double));
    double *E = (double*)malloc((size_t)(n-1) * sizeof(double));
    if (!D || !E) { fprintf(stderr, "alloc D/E failed\n"); return 1; }

    /* Build correct tridiagonal T = (D,E) from the SAME initial KMS matrix */
    int rc = kms_to_tridiag(n, /*rho=*/0.95, /*delta=*/0.0, D, E);
    if (rc != 0) { fprintf(stderr, "kms_to_tridiag failed, info=%d\n", rc); return 2; }

    /* Run DSTEDC. Options:
       COMPZ='N' -> eigenvalues only of T
       COMPZ='I' -> eigenvectors of T; Z returned orthonormal
       COMPZ='V' -> Z must contain the orthogonal matrix from reduction (not used here) */
    char compz = 'N';
    int info = 0, lwork = -1, liwork = -1, ldz = 1;
    double *Z = NULL; /* not needed for 'N' */
    double wkopt; int iwkopt;

    dstedc_(&compz, &n, D, E, Z, &ldz, &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) { fprintf(stderr, "DSTEDC query failed, info=%d\n", info); return 3; }

    lwork  = (int)wkopt;
    liwork = iwkopt;
    double *WORK  = (double*)malloc((size_t)lwork  * sizeof(double));
    int    *IWORK = (int*)   malloc((size_t)liwork * sizeof(int));
    if (!WORK || !IWORK) { fprintf(stderr, "alloc work failed\n"); return 4; }

    dstedc_(&compz, &n, D, E, Z, &ldz, WORK, &lwork, IWORK, &liwork, &info);
    if (info != 0) { fprintf(stderr, "DSTEDC failed, info=%d\n", info); return 5; }

    printf("DSTEDC ok. Example: D[0]=%.6e, D[n-1]=%.6e\n", D[0], D[n-1]);

    free(IWORK); free(WORK); free(E); free(D);
    return 0;
}
