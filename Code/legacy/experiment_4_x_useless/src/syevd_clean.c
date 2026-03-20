// syevd_clean.c
// ------------------------------------------------------------
// Clean C symmetric eigen-solver (teaching version).
// Pipeline: Householder tridiagonalization -> divide-and-conquer tridiagonal eigensolver -> back-transform.
// Column-major storage, LAPACK-style.
// ------------------------------------------------------------

#include "syevd_clean.h"

#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

static void set_identity(double *A, int n)
{
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i < n; ++i) {
            A[i + (size_t)j * n] = (i == j) ? 1.0 : 0.0;
        }
    }
}

static int tridiagonalize(int n, double *A, int lda, double *d, double *e, double *Q)
{
    double *v = (double*)calloc((size_t)n, sizeof(double));
    double *w = (double*)calloc((size_t)n, sizeof(double));
    if (!v || !w) {
        free(v);
        free(w);
        return -1;
    }

    set_identity(Q, n);

    for (int k = 0; k < n - 2; ++k) {
        double norm = 0.0;
        for (int i = k + 1; i < n; ++i) {
            v[i] = A[i + (size_t)k * lda];
            norm += v[i] * v[i];
        }

        if (norm == 0.0) {
            continue;
        }

        norm = sqrt(norm);
        double alpha = (v[k + 1] >= 0.0) ? -norm : norm;
        v[k + 1] -= alpha;

        double beta = 0.0;
        for (int i = k + 1; i < n; ++i) beta += v[i] * v[i];
        if (beta == 0.0) {
            continue;
        }
        double tau = 2.0 / beta;

        for (int i = k + 1; i < n; ++i) {
            double sum = 0.0;
            for (int j = k + 1; j < n; ++j) {
                sum += A[i + (size_t)j * lda] * v[j];
            }
            w[i] = sum;
        }
        double vtw = 0.0;
        for (int i = k + 1; i < n; ++i) vtw += v[i] * w[i];
        double adj = 0.5 * tau * vtw;
        for (int i = k + 1; i < n; ++i) w[i] -= adj * v[i];

        for (int i = k + 1; i < n; ++i) {
            for (int j = i; j < n; ++j) {
                A[i + (size_t)j * lda] -= tau * (v[i] * w[j] + w[i] * v[j]);
            }
        }
        for (int i = k + 1; i < n; ++i) {
            for (int j = k + 1; j < i; ++j) {
                A[i + (size_t)j * lda] = A[j + (size_t)i * lda];
            }
        }

        for (int i = k + 2; i < n; ++i) {
            A[i + (size_t)k * lda] = 0.0;
            A[k + (size_t)i * lda] = 0.0;
        }
        A[k + 1 + (size_t)k * lda] = alpha;
        A[k + (size_t)(k + 1) * lda] = alpha;

        for (int j = 0; j < n; ++j) {
            double dot = 0.0;
            for (int i = k + 1; i < n; ++i) {
                dot += v[i] * Q[i + (size_t)j * n];
            }
            dot *= tau;
            for (int i = k + 1; i < n; ++i) {
                Q[i + (size_t)j * n] -= dot * v[i];
            }
        }

        for (int i = k + 1; i < n; ++i) v[i] = 0.0;
    }

    for (int i = 0; i < n; ++i) d[i] = A[i + (size_t)i * lda];
    for (int i = 0; i < n - 1; ++i) e[i] = A[i + 1 + (size_t)i * lda];

    free(v);
    free(w);
    return 0;
}

static int tqli(int n, double *d, const double *e_sub, double *Z)
{
    double *e = (double*)calloc((size_t)n, sizeof(double));
    if (!e) return -1;

    e[0] = 0.0;
    for (int i = 1; i < n; ++i) e[i] = e_sub[i - 1];

    for (int i = 1; i < n; ++i) e[i - 1] = e[i];
    e[n - 1] = 0.0;

    for (int l = 0; l < n; ++l) {
        int iter = 0;
        while (1) {
            int m;
            for (m = l; m < n - 1; ++m) {
                double dd = fabs(d[m]) + fabs(d[m + 1]);
                if (fabs(e[m]) + dd == dd) break;
            }
            if (m == l) break;
            if (iter++ > 60) {
                free(e);
                return -2;
            }

            double g = (d[l + 1] - d[l]) / (2.0 * e[l]);
            double r = hypot(g, 1.0);
            g = d[m] - d[l] + e[l] / (g + copysign(r, g));
            double s = 1.0, c = 1.0, p = 0.0;

            for (int i = m - 1; i >= l; --i) {
                double f = s * e[i];
                double b = c * e[i];
                if (fabs(f) >= fabs(g)) {
                    c = g / f;
                    r = hypot(c, 1.0);
                    e[i + 1] = f * r;
                    s = 1.0 / r;
                    c *= s;
                } else {
                    s = f / g;
                    r = hypot(s, 1.0);
                    e[i + 1] = g * r;
                    c = 1.0 / r;
                    s *= c;
                }
                g = d[i + 1] - p;
                r = (d[i] - g) * s + 2.0 * c * b;
                p = s * r;
                d[i + 1] = g + p;
                g = c * r - b;

                for (int k = 0; k < n; ++k) {
                    double z1 = Z[k + (size_t)(i + 1) * n];
                    double z0 = Z[k + (size_t)i * n];
                    Z[k + (size_t)(i + 1) * n] = s * z0 + c * z1;
                    Z[k + (size_t)i * n] = c * z0 - s * z1;
                }
            }
            d[l] -= p;
            e[l] = g;
            e[m] = 0.0;
        }
    }

    free(e);
    return 0;
}

static void sort_eigs(int n, double *d, double *Z)
{
    for (int i = 0; i < n - 1; ++i) {
        int k = i;
        double p = d[i];
        for (int j = i + 1; j < n; ++j) {
            if (d[j] < p) {
                k = j;
                p = d[j];
            }
        }
        if (k != i) {
            d[k] = d[i];
            d[i] = p;
            for (int r = 0; r < n; ++r) {
                double tmp = Z[r + (size_t)i * n];
                Z[r + (size_t)i * n] = Z[r + (size_t)k * n];
                Z[r + (size_t)k * n] = tmp;
            }
        }
    }
}

#define SMLSIZ 25

static double secular_f(int n, const double *d, const double *z, double rho, double x)
{
    double sum = 1.0;
    for (int i = 0; i < n; ++i) {
        double denom = d[i] - x;
        sum += rho * (z[i] * z[i]) / denom;
    }
    return sum;
}

static int stedc_dc(int n, double *d, double *e, double *Z)
{
    if (n == 1) {
        Z[0] = 1.0;
        return 0;
    }
    if (n <= SMLSIZ) {
        set_identity(Z, n);
        if (tqli(n, d, e, Z) != 0) return -1;
        sort_eigs(n, d, Z);
        return 0;
    }

    int n1 = n / 2;
    int n2 = n - n1;
    double rho = e[n1 - 1];

    if (rho == 0.0) {
        double *Z1 = (double*)malloc((size_t)n1 * (size_t)n1 * sizeof(double));
        double *Z2 = (double*)malloc((size_t)n2 * (size_t)n2 * sizeof(double));
        if (!Z1 || !Z2) { free(Z1); free(Z2); return -2; }
        if (stedc_dc(n1, d, e, Z1) != 0) { free(Z1); free(Z2); return -3; }
        if (stedc_dc(n2, d + n1, e + n1, Z2) != 0) { free(Z1); free(Z2); return -4; }
        for (int j = 0; j < n; ++j) {
            for (int i = 0; i < n; ++i) Z[i + (size_t)j * n] = 0.0;
        }
        for (int j = 0; j < n1; ++j) {
            for (int i = 0; i < n1; ++i) {
                Z[i + (size_t)j * n] = Z1[i + (size_t)j * n1];
            }
        }
        for (int j = 0; j < n2; ++j) {
            for (int i = 0; i < n2; ++i) {
                Z[(i + n1) + (size_t)(j + n1) * n] = Z2[i + (size_t)j * n2];
            }
        }
        sort_eigs(n, d, Z);
        free(Z1);
        free(Z2);
        return 0;
    }

    d[n1 - 1] -= rho;
    d[n1]     -= rho;
    e[n1 - 1]  = 0.0;

    double *Z1 = (double*)malloc((size_t)n1 * (size_t)n1 * sizeof(double));
    double *Z2 = (double*)malloc((size_t)n2 * (size_t)n2 * sizeof(double));
    if (!Z1 || !Z2) { free(Z1); free(Z2); return -5; }

    if (stedc_dc(n1, d, e, Z1) != 0) { free(Z1); free(Z2); return -6; }
    if (stedc_dc(n2, d + n1, e + n1, Z2) != 0) { free(Z1); free(Z2); return -7; }

    double *D0 = (double*)malloc((size_t)n * sizeof(double));
    double *z0 = (double*)malloc((size_t)n * sizeof(double));
    int *perm = (int*)malloc((size_t)n * sizeof(int));
    if (!D0 || !z0 || !perm) {
        free(D0); free(z0); free(perm); free(Z1); free(Z2);
        return -8;
    }
    for (int i = 0; i < n; ++i) {
        D0[i] = d[i];
        perm[i] = i;
    }
    for (int i = 0; i < n1; ++i) z0[i] = Z1[(n1 - 1) + (size_t)i * n1];
    for (int i = 0; i < n2; ++i) z0[n1 + i] = Z2[0 + (size_t)i * n2];

    for (int i = 0; i < n - 1; ++i) {
        int k = i;
        for (int j = i + 1; j < n; ++j) {
            if (D0[perm[j]] < D0[perm[k]]) k = j;
        }
        if (k != i) {
            int tmp = perm[i];
            perm[i] = perm[k];
            perm[k] = tmp;
        }
    }

    double *D = (double*)malloc((size_t)n * sizeof(double));
    double *z = (double*)malloc((size_t)n * sizeof(double));
    if (!D || !z) {
        free(D0); free(z0); free(perm); free(D); free(z); free(Z1); free(Z2);
        return -9;
    }
    for (int i = 0; i < n; ++i) {
        D[i] = D0[perm[i]];
        z[i] = z0[perm[i]];
    }

    double z2sum = 0.0;
    for (int i = 0; i < n; ++i) z2sum += z[i] * z[i];
    if (z2sum == 0.0) {
        free(D0); free(z0); free(perm); free(D); free(z); free(Z1); free(Z2);
        return -10;
    }

    double *X_sorted = (double*)malloc((size_t)n * (size_t)n * sizeof(double));
    double *X0 = (double*)malloc((size_t)n * (size_t)n * sizeof(double));
    double *lambda = (double*)malloc((size_t)n * sizeof(double));
    if (!X_sorted || !X0 || !lambda) {
        free(D0); free(z0); free(perm); free(D); free(z);
        free(X_sorted); free(X0); free(lambda);
        free(Z1); free(Z2);
        return -11;
    }

    const double eps = 1e-12;
    const double bound = fabs(rho) * z2sum + 1.0;
    for (int k = 0; k < n; ++k) {
        double lo, hi;
        if (rho > 0.0) {
            if (k < n - 1) {
                lo = D[k] + eps;
                hi = D[k + 1] - eps;
            } else {
                lo = D[n - 1] + eps;
                hi = D[n - 1] + bound;
            }
        } else {
            if (k == 0) {
                lo = D[0] - bound;
                hi = D[0] - eps;
            } else {
                lo = D[k - 1] + eps;
                hi = D[k] - eps;
            }
        }

        double f_lo = secular_f(n, D, z, rho, lo);
        double f_hi = secular_f(n, D, z, rho, hi);
        if (f_lo == 0.0) {
            lambda[k] = lo;
        } else if (f_hi == 0.0) {
            lambda[k] = hi;
        } else {
            for (int it = 0; it < 100; ++it) {
                double mid = 0.5 * (lo + hi);
                double f_mid = secular_f(n, D, z, rho, mid);
                if ((f_lo > 0.0 && f_mid > 0.0) || (f_lo < 0.0 && f_mid < 0.0)) {
                    lo = mid;
                    f_lo = f_mid;
                } else {
                    hi = mid;
                    f_hi = f_mid;
                }
                if (fabs(hi - lo) <= 1e-10 * (fabs(hi) + fabs(lo) + 1.0)) break;
            }
            lambda[k] = 0.5 * (lo + hi);
        }

        double norm = 0.0;
        for (int i = 0; i < n; ++i) {
            double v = z[i] / (D[i] - lambda[k]);
            X_sorted[i + (size_t)k * n] = v;
            norm += v * v;
        }
        norm = sqrt(norm);
        if (norm == 0.0) {
            free(D0); free(z0); free(perm); free(D); free(z);
            free(X_sorted); free(X0); free(lambda);
            free(Z1); free(Z2);
            return -12;
        }
        for (int i = 0; i < n; ++i) {
            X_sorted[i + (size_t)k * n] /= norm;
        }
    }

    for (int j = 0; j < n; ++j) {
        for (int i = 0; i < n; ++i) {
            X0[perm[i] + (size_t)j * n] = X_sorted[i + (size_t)j * n];
        }
    }

    for (int j = 0; j < n; ++j) {
        for (int i = 0; i < n1; ++i) {
            double sum = 0.0;
            for (int k = 0; k < n1; ++k) {
                sum += Z1[i + (size_t)k * n1] * X0[k + (size_t)j * n];
            }
            Z[i + (size_t)j * n] = sum;
        }
        for (int i = 0; i < n2; ++i) {
            double sum = 0.0;
            for (int k = 0; k < n2; ++k) {
                sum += Z2[i + (size_t)k * n2] * X0[(n1 + k) + (size_t)j * n];
            }
            Z[(n1 + i) + (size_t)j * n] = sum;
        }
    }

    for (int i = 0; i < n; ++i) d[i] = lambda[i];

    free(D0);
    free(z0);
    free(perm);
    free(D);
    free(z);
    free(X_sorted);
    free(X0);
    free(lambda);
    free(Z1);
    free(Z2);
    return 0;
}

/* ----- LAPACK-like stages (clean C, same call order) ----- */
static int dsytrd_clean(int n, double *A, int lda, double *d, double *e, double *Q)
{
    return tridiagonalize(n, A, lda, d, e, Q);
}

static int dstedc_clean(int n, double *d, double *e, double *Z)
{
    return stedc_dc(n, d, e, Z);
}

static void dormtr_clean(int n, const double *Q, const double *Z, double *A, int lda)
{
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i < n; ++i) {
            double sum = 0.0;
            for (int k = 0; k < n; ++k) {
                sum += Q[i + (size_t)k * n] * Z[k + (size_t)j * n];
            }
            A[i + (size_t)j * lda] = sum;
        }
    }
}

int syevd_clean(int n, double *A, int lda, double *W)
{
    if (n <= 0 || lda < n || !A || !W) return -1;

    double *Q = (double*)malloc((size_t)n * (size_t)n * sizeof(double));
    double *Z = (double*)malloc((size_t)n * (size_t)n * sizeof(double));
    double *d = (double*)malloc((size_t)n * sizeof(double));
    double *e = (double*)malloc((size_t)(n - 1) * sizeof(double));
    if (!Q || !Z || !d || (!e && n > 1)) {
        free(Q); free(Z); free(d); free(e);
        return -2;
    }

    /* DSYTRD */
    if (dsytrd_clean(n, A, lda, d, e, Q) != 0) {
        free(Q); free(Z); free(d); free(e);
        return -3;
    }

    /* DSTEDC */
    if (dstedc_clean(n, d, e, Z) != 0) {
        free(Q); free(Z); free(d); free(e);
        return -4;
    }

    /* DORMTR */
    dormtr_clean(n, Q, Z, A, lda);

    memcpy(W, d, (size_t)n * sizeof(double));

    free(Q);
    free(Z);
    free(d);
    free(e);
    return 0;
}
