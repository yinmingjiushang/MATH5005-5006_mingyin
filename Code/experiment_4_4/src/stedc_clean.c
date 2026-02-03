/*
 * stedc_clean.c — Clean C implementation of symmetric tridiagonal divide-and-conquer (DSTEDC-style).
 *
 * Purpose: Teaching code to illustrate WHY DSTEDC is fast on modern hardware.
 *          The key is that the MERGE step is a matrix-matrix multiply (DGEMM),
 *          which maps to cache blocking, SIMD, and high arithmetic intensity.
 *
 * Algorithm: Cuppen divide-and-conquer.
 *   1. Split T into two tridiagonal blocks + rank-1 coupling (rho).
 *   2. Recurse: solve each block (eigenvalues + eigenvectors Z1, Z2).
 *   3. Merge: solve secular equation for new eigenvalues; form new eigenvectors
 *      by Z = [Z1 0; 0 Z2] * X, where X is from the rank-1 eigenvector formula.
 *
 * Why it fits modern architecture (see comments in code):
 *   A1: Merge = DGEMM — forming Z is exactly two dense matrix multiplies (Z1*X1, Z2*X2).
 *       In LAPACK this is DLAED3 → DGEMM; replace the triple loop with cblas_dgemm in production.
 *   A2: Cache — DGEMM can be blocked (L1/L2/L3); high arithmetic intensity O(n³)/O(n²).
 *   A3: SIMD — DGEMM kernels use vector instructions; high flops per cycle.
 *   A4: Parallelism — two subproblems are independent; merge is one big DGEMM (parallelizable).
 *
 * Storage: Column-major. d[0..n-1] = diagonal, e[0..n-2] = subdiagonal.
 */

#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#define SMLSIZ 25   /* Base case: n <= SMLSIZ use QR (or 2x2) */

/* Optional: use OpenBLAS/LAPACK DGEMM for merge (define STEDC_USE_CBLAS and link -lopenblas) */
#ifdef STEDC_USE_CBLAS
#include <cblas.h>
#endif
#ifndef STEDC_USE_CBLAS
/* Plain triple loop — this IS the DGEMM pattern; in production use cblas_dgemm. */
static void dgemm_merge(int m, int n, int k,
    const double *A, int lda, const double *B, int ldb, double *C, int ldc)
{
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i < m; ++i) {
            double sum = 0.0;
            for (int p = 0; p < k; ++p)
                sum += A[i + (size_t)p * lda] * B[p + (size_t)j * ldb];
            C[i + (size_t)j * ldc] = sum;
        }
    }
}
#endif

/* External: QR for small tridiagonal (from steqr_clean.c or equivalent) */
extern int steqr_clean(int n, double *d, double *e, double *Z, int ldZ, int *out_iters);
extern void steqr_clean_sort(int n, double *d, double *Z, int ldZ);

static int stedc_recurse(int n, double *d, double *e, double *Z, int ldZ);

static double secular_f(int n, const double *d, const double *z, double rho, double x)
{
    double sum = 1.0;
    for (int i = 0; i < n; ++i) {
        double denom = d[i] - x;
        if (fabs(denom) < 1e-14) denom = (denom >= 0.0 ? 1e-14 : -1e-14);
        sum += rho * (z[i] * z[i]) / denom;
    }
    return sum;
}

/*
 * Merge step: given eigenvalues D and rank-1 vector z (from subproblems),
 * solve secular equation for new eigenvalues lambda, then form eigenvectors
 * X such that merged eigenvectors Z = [Z1 0; 0 Z2] * X.
 *
 * A1 (DGEMM): Forming Z is exactly
 *   Z(1:n1, 1:n) = Z1(1:n1, 1:n1) * X(1:n1, 1:n)
 *   Z(n1+1:n, 1:n) = Z2(1:n2, 1:n2) * X(n1+1:n, 1:n)
 * i.e. two DGEMMs. This is where STEDC aligns with modern architecture —
 * DGEMM is cache-friendly, SIMD-optimized, and parallelizable.
 */
static int merge_rank1(int n, int n1, int n2, double rho,
    const double *Z1, int ld1, const double *Z2, int ld2,
    double *D, double *z, int *perm,
    double *lambda, double *X, double *Z, int ldZ)
{
    const double eps = 1e-12;
    double z2sum = 0.0;
    for (int i = 0; i < n; ++i) z2sum += z[i] * z[i];
    double bound = fabs(rho) * z2sum + 1.0;

    /* Solve secular equation for each eigenvalue (simplified: bisection) */
    for (int k = 0; k < n; ++k) {
        double lo, hi;
        if (rho > 0.0) {
            lo = (k < n - 1) ? D[k] + eps : D[n - 1] + eps;
            hi = (k < n - 1) ? D[k + 1] - eps : D[n - 1] + bound;
        } else {
            lo = (k == 0) ? D[0] - bound : D[k - 1] + eps;
            hi = (k == 0) ? D[0] - eps : D[k] - eps;
        }
        for (int it = 0; it < 80; ++it) {
            double mid = 0.5 * (lo + hi);
            double f = secular_f(n, D, z, rho, mid);
            if (f > 0.0) lo = mid; else hi = mid;
            if (fabs(hi - lo) <= 1e-10 * (fabs(lo) + fabs(hi) + 1.0)) { lo = mid; break; }
        }
        lambda[k] = 0.5 * (lo + hi);

        /* Eigenvector of rank-1 modified diagonal: x_i = z_i / (d_i - lambda) */
        double norm = 0.0;
        for (int i = 0; i < n; ++i) {
            double v = z[i] / (D[i] - lambda[k]);
            X[i + (size_t)k * n] = v;
            norm += v * v;
        }
        norm = sqrt(norm);
        for (int i = 0; i < n; ++i) X[i + (size_t)k * n] /= norm;
    }

    /* Permute X back to original order (perm was from sorting D) */
    double *X0 = (double *)malloc((size_t)n * (size_t)n * sizeof(double));
    if (!X0) return -1;
    for (int j = 0; j < n; ++j)
        for (int i = 0; i < n; ++i)
            X0[perm[i] + (size_t)j * n] = X[i + (size_t)j * n];

    /*
     * A1 (DGEMM): Z = [Z1 0; 0 Z2] * X0.
     * Left block: Z(0:n1-1, 0:n-1) = Z1(0:n1-1, 0:n1-1) * X0(0:n1-1, 0:n-1)  — DGEMM(n1, n, n1)
     * Right block: Z(n1:n-1, 0:n-1) = Z2(0:n2-1, 0:n2-1) * X0(n1:n-1, 0:n-1) — DGEMM(n2, n, n2)
     * In LAPACK/OpenBLAS this is exactly two DGEMM calls; it is this structure that
     * allows cache blocking, SIMD, and high GFLOPS.
     */
#ifdef STEDC_USE_CBLAS
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, n1, n, n1, 1.0,
        Z1, ld1, X0, n, 0.0, Z, ldZ);
    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, n2, n, n2, 1.0,
        Z2, ld2, X0 + n1, n, 0.0, Z + (size_t)n1 * ldZ, ldZ);
#else
    dgemm_merge(n1, n, n1, Z1, ld1, X0, n, Z, ldZ);
    dgemm_merge(n2, n, n2, Z2, ld2, X0 + n1, n, Z + (size_t)n1 * ldZ, ldZ);
#endif

    free(X0);
    return 0;
}

int stedc_clean(int n, double *d, double *e, double *Z, int ldZ)
{
    if (n <= 0 || !d || !e || !Z || ldZ < n) return -1;
    if (n == 1) {
        Z[0] = 1.0;
        return 0;
    }

    int n1 = n / 2, n2 = n - n1;
    double rho = e[n1 - 1];
    e[n1 - 1] = 0.0;

    if (fabs(rho) < 1e-14) {
        /* No coupling: block diagonal; recurse and paste */
        double *Z1 = (double *)malloc((size_t)n1 * (size_t)n1 * sizeof(double));
        double *Z2 = (double *)malloc((size_t)n2 * (size_t)n2 * sizeof(double));
        if (!Z1 || !Z2) { free(Z1); free(Z2); return -2; }
        for (int i = 0; i < n1 * n1; ++i) Z1[i] = 0.0;
        for (int i = 0; i < n2 * n2; ++i) Z2[i] = 0.0;
        for (int i = 0; i < n1; ++i) Z1[i + (size_t)i * n1] = 1.0;
        for (int i = 0; i < n2; ++i) Z2[i + (size_t)i * n2] = 1.0;

        if (stedc_recurse(n1, d, e, Z1, n1) != 0) { free(Z1); free(Z2); return -3; }
        if (stedc_recurse(n2, d + n1, e + n1, Z2, n2) != 0) { free(Z1); free(Z2); return -4; }

        for (int j = 0; j < n; ++j)
            for (int i = 0; i < n; ++i)
                Z[i + (size_t)j * ldZ] = 0.0;
        for (int j = 0; j < n1; ++j)
            for (int i = 0; i < n1; ++i)
                Z[i + (size_t)j * ldZ] = Z1[i + (size_t)j * n1];
        for (int j = 0; j < n2; ++j)
            for (int i = 0; i < n2; ++i)
                Z[(i + n1) + (size_t)(j + n1) * ldZ] = Z2[i + (size_t)j * n2];

        free(Z1); free(Z2);
        return 0;
    }

    /* Rank-1 modification: shift diagonals */
    d[n1 - 1] -= rho;
    d[n1]     -= rho;

    double *Z1 = (double *)malloc((size_t)n1 * (size_t)n1 * sizeof(double));
    double *Z2 = (double *)malloc((size_t)n2 * (size_t)n2 * sizeof(double));
    if (!Z1 || !Z2) { free(Z1); free(Z2); return -5; }
    for (int i = 0; i < n1 * n1; ++i) Z1[i] = 0.0;
    for (int i = 0; i < n2 * n2; ++i) Z2[i] = 0.0;
    for (int i = 0; i < n1; ++i) Z1[i + (size_t)i * n1] = 1.0;
    for (int i = 0; i < n2; ++i) Z2[i + (size_t)i * n2] = 1.0;

    if (stedc_recurse(n1, d, e, Z1, n1) != 0) { free(Z1); free(Z2); return -6; }
    if (stedc_recurse(n2, d + n1, e + n1, Z2, n2) != 0) { free(Z1); free(Z2); return -7; }

    /* Build z = last row of Z1 and first row of Z2 (rank-1 update vector) */
    double *D0 = (double *)malloc((size_t)n * sizeof(double));
    double *z = (double *)malloc((size_t)n * sizeof(double));
    int *perm = (int *)malloc((size_t)n * sizeof(int));
    if (!D0 || !z || !perm) {
        free(D0); free(z); free(perm); free(Z1); free(Z2);
        return -8;
    }
    for (int i = 0; i < n; ++i) { D0[i] = d[i]; perm[i] = i; }
    for (int i = 0; i < n1; ++i) z[i] = Z1[(n1 - 1) + (size_t)i * n1];
    for (int i = 0; i < n2; ++i) z[n1 + i] = Z2[0 + (size_t)i * n2];

    /* Sort D0 and perm; apply same permutation to z */
    for (int i = 0; i < n - 1; ++i) {
        int k = i;
        for (int j = i + 1; j < n; ++j) { if (D0[perm[j]] < D0[perm[k]]) k = j; }
        if (k != i) { int t = perm[i]; perm[i] = perm[k]; perm[k] = t; }
    }
    double *D = (double *)malloc((size_t)n * sizeof(double));
    double *zs = (double *)malloc((size_t)n * sizeof(double));
    if (!D || !zs) {
        free(D0); free(z); free(perm); free(D); free(zs); free(Z1); free(Z2);
        return -9;
    }
    for (int i = 0; i < n; ++i) { D[i] = D0[perm[i]]; zs[i] = z[perm[i]]; }

    double *lambda = (double *)malloc((size_t)n * sizeof(double));
    double *X = (double *)malloc((size_t)n * (size_t)n * sizeof(double));
    if (!lambda || !X) {
        free(D0); free(z); free(perm); free(D); free(zs); free(lambda); free(X); free(Z1); free(Z2);
        return -10;
    }

    int err = merge_rank1(n, n1, n2, rho, Z1, n1, Z2, n2, D, zs, perm, lambda, X, Z, ldZ);
    if (err != 0) {
        free(D0); free(z); free(perm); free(D); free(zs); free(lambda); free(X); free(Z1); free(Z2);
        return -11;
    }

    for (int i = 0; i < n; ++i) d[i] = lambda[i];
    free(D0); free(z); free(perm); free(D); free(zs); free(lambda); free(X); free(Z1); free(Z2);
    return 0;
}

static int stedc_recurse(int n, double *d, double *e, double *Z, int ldZ)
{
    if (n <= SMLSIZ) {
        int iters;
        if (steqr_clean(n, d, e, Z, ldZ, &iters) != 0) return -1;
        steqr_clean_sort(n, d, Z, ldZ);
        return 0;
    }
    return stedc_clean(n, d, e, Z, ldZ);
}

#ifdef STEDC_CLEAN_MAIN
#include <stdio.h>
int main(void)
{
    int n = 8;
    double d[] = { 4, 3, 2, 1, 1, 2, 3, 4 };
    double e[] = { 1, 1, 1, 1, 1, 1, 1 };
    double *Z = (double *)calloc((size_t)n * (size_t)n, sizeof(double));
    if (!Z) return 1;
    for (int i = 0; i < n; ++i) Z[i + (size_t)i * n] = 1.0;

    int info = stedc_clean(n, d, e, Z, n);
    if (info != 0) {
        printf("stedc_clean failed %d\n", info);
        free(Z);
        return 1;
    }

    printf("STEDC clean: n=%d\n", n);
    printf("Eigenvalues: ");
    for (int i = 0; i < n; ++i) printf(" %.4f", d[i]);
    printf("\n");
    free(Z);
    return 0;
}
#endif
