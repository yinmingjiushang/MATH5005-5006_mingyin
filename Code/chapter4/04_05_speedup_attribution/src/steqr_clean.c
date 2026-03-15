/*
 * steqr_clean.c — Clean C implementation of symmetric tridiagonal QR (DSTEQR-style).
 *
 * Purpose: Teaching code to illustrate WHY DSTEQR is slow and constrained on modern
 *          hardware. Used in experiment 4.4 to explain "STEQR limitations".
 *
 * Algorithm: Implicit QR iteration for T (tridiagonal). Each iteration:
 *   1. Compute a shift (e.g. Wilkinson), introduce a bulge.
 *   2. Chase the bulge from top to bottom with Givens rotations (sequential).
 *   3. Apply each Givens to the eigenvector matrix Z (two columns only).
 *
 * Key limitations (see comments in code):
 *   L1: Sequential dependency — bulge chase is inherently sequential; no parallelism.
 *   L2: No DGEMM — only O(n) work per rotation (Givens + apply to 2 columns of Z).
 *   L3: Iteration count can be O(n) or more (e.g. clustered eigenvalues).
 *   L4: Memory access is scattered; no cache blocking; low arithmetic intensity.
 *
 * Storage: Column-major (LAPACK style). d[0..n-1] = diagonal, e[0..n-2] = subdiagonal.
 *          Z is n×n, ldZ = leading dimension.
 */

#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static double hypot2(double a, double b)
{
    double aa = fabs(a), bb = fabs(b);
    if (aa > bb) {
        double t = bb / aa;
        return aa * sqrt(1.0 + t * t);
    }
    if (bb > 0.0) {
        double t = aa / bb;
        return bb * sqrt(1.0 + t * t);
    }
    return 0.0;
}

/*
 * One iteration of implicit QR: chase bulge from row 'l' down to row 'm'.
 * Updates d[], e[], and Z. All work is O(n) and sequential; no matrix-matrix multiply.
 */
static void qr_one_sweep(int n, double *d, double *e, double *Z, int ldZ, int l, int m)
{
    /* Shift: simple choice (could use Wilkinson for better convergence) */
    double g = (d[l + 1] - d[l]) / (2.0 * e[l]);
    double r = hypot2(g, 1.0);
    g = d[m] - d[l] + e[l] / (g + (g >= 0.0 ? r : -r));

    double s = 1.0, c = 1.0, p = 0.0;

    /*
     * L1 (Sequential): Bulge chase — must proceed from i = m-1 down to l.
     * Each step depends on the previous; no way to parallelize or express as DGEMM.
     */
    for (int i = m - 1; i >= l; --i) {
        double f = s * e[i];
        double b = c * e[i];
        /* Givens: zero e[i] */
        if (fabs(f) >= fabs(g)) {
            c = g / f;
            r = hypot2(c, 1.0);
            e[i + 1] = f * r;
            s = 1.0 / r;
            c *= s;
        } else {
            s = f / g;
            r = hypot2(s, 1.0);
            e[i + 1] = g * r;
            c = 1.0 / r;
            s *= c;
        }
        g = d[i + 1] - p;
        r = (d[i] - g) * s + 2.0 * c * b;
        p = s * r;
        d[i + 1] = g + p;
        g = c * r - b;

        /*
         * L2 (No DGEMM): Apply Givens to Z — only columns i and i+1 are updated.
         * This is O(n) per rotation (n rows × 2 columns). There is no bulk
         * matrix-matrix multiply; we cannot call DGEMM here.
         */
        for (int k = 0; k < n; ++k) {
            double z0 = Z[k + (size_t)i * ldZ];
            double z1 = Z[k + (size_t)(i + 1) * ldZ];
            Z[k + (size_t)i * ldZ]     = c * z0 - s * z1;
            Z[k + (size_t)(i + 1) * ldZ] = s * z0 + c * z1;
        }
    }
    d[l] -= p;
    e[l] = g;
    e[m] = 0.0;
}

/*
 * STEQR: Compute eigenvalues and eigenvectors of symmetric tridiagonal (d, e).
 * Returns total number of iterations (sweeps) — can be large for bad eigenvalue distribution.
 */
int steqr_clean(int n, double *d, double *e, double *Z, int ldZ, int *out_iters)
{
    if (n <= 0 || !d || !e || !Z || ldZ < n) return -1;

    double *ec = (double *)malloc((size_t)(n + 1) * sizeof(double));
    if (!ec) return -2;

    for (int i = 0; i < n - 1; ++i) ec[i] = e[i];
    ec[n - 1] = 0.0;

    int total_iters = 0;
    const int max_iters_per_eigenvalue = 30; /* L3: in practice can be much larger */

    for (int l = 0; l < n; ++l) {
        int iter = 0;
        while (1) {
            /* Find last nonzero subdiagonal (deflation) */
            int m = l;
            while (m < n - 1) {
                double dd = fabs(d[m]) + fabs(d[m + 1]);
                if (fabs(ec[m]) <= dd * (1.0 + 1e-14)) break;
                ++m;
            }
            if (m == l) break; /* converged for this eigenvalue */

            if (iter++ >= max_iters_per_eigenvalue) {
                free(ec);
                return -3; /* not converged */
            }
            total_iters++;

            qr_one_sweep(n, d, ec, Z, ldZ, l, m);
        }
    }

    for (int i = 0; i < n - 1; ++i) e[i] = ec[i];
    if (out_iters) *out_iters = total_iters;
    free(ec);
    return 0;
}

/*
 * Sort eigenvalues ascending and permute Z accordingly (O(n^2) selection sort).
 */
void steqr_clean_sort(int n, double *d, double *Z, int ldZ)
{
    for (int i = 0; i < n - 1; ++i) {
        int k = i;
        double p = d[i];
        for (int j = i + 1; j < n; ++j) {
            if (d[j] < p) { k = j; p = d[j]; }
        }
        if (k != i) {
            d[k] = d[i];
            d[i] = p;
            for (int r = 0; r < n; ++r) {
                double t = Z[r + (size_t)i * ldZ];
                Z[r + (size_t)i * ldZ] = Z[r + (size_t)k * ldZ];
                Z[r + (size_t)k * ldZ] = t;
            }
        }
    }
}

#ifdef STEQR_CLEAN_MAIN
#include <stdio.h>
int main(void)
{
    int n = 8;
    double d[] = { 4, 3, 2, 1, 1, 2, 3, 4 };
    double e[] = { 1, 1, 1, 1, 1, 1, 1 };
    double *Z = (double *)calloc((size_t)n * (size_t)n, sizeof(double));
    if (!Z) return 1;
    for (int i = 0; i < n; ++i) Z[i + (size_t)i * n] = 1.0;

    int iters = 0;
    int info = steqr_clean(n, d, e, Z, n, &iters);
    if (info != 0) {
        printf("steqr_clean failed %d\n", info);
        free(Z);
        return 1;
    }
    steqr_clean_sort(n, d, Z, n);

    printf("STEQR clean: n=%d, total iterations=%d\n", n, iters);
    printf("Eigenvalues: ");
    for (int i = 0; i < n; ++i) printf(" %.4f", d[i]);
    printf("\n");
    free(Z);
    return 0;
}
#endif
