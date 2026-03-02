#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define N 6
#define MAX_SWEEPS 120
#define ZERO_TOL 1e-12
#define DEFL_TOL 1e-10

typedef enum {
    MODE_LATEX,
    MODE_STEP,
    MODE_FULL
} OutputMode;

static double hypot2(double a, double b)
{
    double aa = fabs(a);
    double bb = fabs(b);
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

static void print_vector(const char *name, const double *x, int n)
{
    printf("%s = [", name);
    for (int i = 0; i < n; ++i) {
        printf("%s%10.6f", i == 0 ? "" : ", ", x[i]);
    }
    printf("]\n");
}

static void print_matrix(const char *name, double T[N][N])
{
    printf("%s\n", name);
    for (int i = 0; i < N; ++i) {
        printf("  ");
        for (int j = 0; j < N; ++j) {
            double v = fabs(T[i][j]) < ZERO_TOL ? 0.0 : T[i][j];
            printf("%11.6f", v);
        }
        printf("\n");
    }
}

static const char *mode_name(OutputMode mode)
{
    switch (mode) {
    case MODE_LATEX: return "latex";
    case MODE_STEP: return "step";
    case MODE_FULL: return "full";
    default: return "latex";
    }
}

static void build_tridiagonal(double T[N][N], const double *d, const double *e)
{
    memset(T, 0, sizeof(double) * N * N);
    for (int i = 0; i < N; ++i) {
        T[i][i] = d[i];
    }
    for (int i = 0; i < N - 1; ++i) {
        T[i][i + 1] = e[i];
        T[i + 1][i] = e[i];
    }
}

static void extract_tridiagonal(double T[N][N], double *d, double *e)
{
    for (int i = 0; i < N; ++i) {
        d[i] = T[i][i];
    }
    for (int i = 0; i < N - 1; ++i) {
        e[i] = T[i + 1][i];
    }
}

static void cleanup_matrix(double T[N][N])
{
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) {
            if (fabs(T[i][j]) < ZERO_TOL) {
                T[i][j] = 0.0;
            }
        }
    }
}

static double wilkinson_shift(double T[N][N], int n)
{
    double a = T[n - 2][n - 2];
    double b = T[n - 2][n - 1];
    double c = T[n - 1][n - 1];
    double delta = (a - c) / 2.0;
    double sign = (delta >= 0.0) ? 1.0 : -1.0;
    return c - sign * b * b / (fabs(delta) + hypot2(delta, b));
}

static void compute_givens(double x, double y, double *c, double *s, double *r)
{
    *r = hypot2(x, y);
    if (*r == 0.0) {
        *c = 1.0;
        *s = 0.0;
        return;
    }
    *c = x / *r;
    *s = y / *r;
}

static void apply_similarity(double T[N][N], int k, double c, double s)
{
    double G[N][N];
    double tmp[N][N];
    double out[N][N];

    memset(G, 0, sizeof(G));
    for (int i = 0; i < N; ++i) {
        G[i][i] = 1.0;
    }

    G[k][k] = c;
    G[k][k + 1] = -s;
    G[k + 1][k] = s;
    G[k + 1][k + 1] = c;

    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) {
            tmp[i][j] = 0.0;
            for (int t = 0; t < N; ++t) {
                tmp[i][j] += T[i][t] * G[t][j];
            }
        }
    }

    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < N; ++j) {
            out[i][j] = 0.0;
            for (int t = 0; t < N; ++t) {
                out[i][j] += G[t][i] * tmp[t][j];
            }
        }
    }

    memcpy(T, out, sizeof(out));
    cleanup_matrix(T);
}

static void report_bulge(double T[N][N], int k)
{
    if (k + 2 < N) {
        printf("  bulge moved to (%d,%d), value = %+.6e\n",
               k + 3, k + 1, T[k + 2][k]);
    } else {
        printf("  bulge has exited the matrix; tridiagonal structure is restored.\n");
    }
}

static void print_sweep_header(double T[N][N], int sweep_id)
{
    double mu = wilkinson_shift(T, N);
    printf("\n================ Sweep %d ================\n", sweep_id);
    printf("Wilkinson shift mu = %.10f\n", mu);
    printf("Trailing 2x2 block = [[%.6f, %.6f], [%.6f, %.6f]]\n",
           T[N - 2][N - 2], T[N - 2][N - 2 + 1], T[N - 1][N - 2], T[N - 1][N - 1]);
}

static void print_step_intro(int k, double x, double y)
{
    if (k == 0) {
        printf("\nStep %d: introduce the shift implicitly on rows/cols (1,2)\n", k + 1);
        printf("  x = [d1 - mu, e1]^T = [% .6f, % .6f]^T\n", x, y);
    } else {
        printf("\nStep %d: chase the bulge using rows/cols (%d,%d)\n", k + 1, k + 1, k + 2);
        printf("  x = [T(%d,%d), T(%d,%d)]^T = [% .6f, % .6f]^T\n",
               k + 1, k, k + 2, k, x, y);
    }
}

static void run_first_sweep(double T[N][N], OutputMode mode)
{
    print_sweep_header(T, 1);

    for (int k = 0; k < N - 1; ++k) {
        double x;
        double y;
        double c;
        double s;
        double r;

        if (k == 0) {
            double mu = wilkinson_shift(T, N);
            x = T[0][0] - mu;
            y = T[1][0];
        } else {
            x = T[k][k - 1];
            y = T[k + 1][k - 1];
        }

        print_step_intro(k, x, y);
        compute_givens(x, y, &c, &s, &r);
        printf("  G_%d parameters: c = % .6f, s = % .6f, r = %.6f\n", k + 1, c, s, r);

        apply_similarity(T, k, c, s);
        report_bulge(T, k);

        if (mode == MODE_FULL) {
            print_matrix("  Updated matrix after G^T T G:", T);
        }
    }
}

static int converged(double T[N][N])
{
    for (int i = 0; i < N - 1; ++i) {
        if (fabs(T[i + 1][i]) >= DEFL_TOL) {
            return 0;
        }
    }
    return 1;
}

static int cmp_double(const void *a, const void *b)
{
    double da = *(const double *)a;
    double db = *(const double *)b;
    if (da < db) return -1;
    if (da > db) return 1;
    return 0;
}

int main(int argc, char **argv)
{
    double d[N] = {1, 2, 3, 4, 5, 6};
    double e[N - 1] = {1, 1, 1, 1, 1};
    double T[N][N];
    OutputMode mode = MODE_LATEX;

    if (argc > 1) {
        if (strcmp(argv[1], "latex") == 0) {
            mode = MODE_LATEX;
        } else if (strcmp(argv[1], "step") == 0) {
            mode = MODE_STEP;
        } else if (strcmp(argv[1], "full") == 0) {
            mode = MODE_FULL;
        } else {
            fprintf(stderr, "usage: %s [latex|step|full]\n", argv[0]);
            return 1;
        }
    }

    build_tridiagonal(T, d, e);

    printf("Teaching demo: symmetric tridiagonal implicit QR (STEQR-style)\n");
    printf("Output mode: %s\n", mode_name(mode));
    printf("Example matrix from Section 2.2:\n");
    print_vector("d", d, N);
    print_vector("e", e, N - 1);
    if (mode == MODE_FULL) {
        print_matrix("Initial T:", T);
    }

    run_first_sweep(T, mode);

    extract_tridiagonal(T, d, e);
    printf("\nAfter the first implicit QR sweep:\n");
    print_vector("d", d, N);
    print_vector("e", e, N - 1);
    printf("|e_5| changed from 1.000000 to %.6e\n", fabs(e[N - 2]));

    printf("\nConvergence summary:\n");
    for (int sweep = 2; sweep <= MAX_SWEEPS; ++sweep) {
        double mu = wilkinson_shift(T, N);
        for (int k = 0; k < N - 1; ++k) {
            double x;
            double y;
            double c;
            double s;
            double r;

            if (k == 0) {
                x = T[0][0] - mu;
                y = T[1][0];
            } else {
                x = T[k][k - 1];
                y = T[k + 1][k - 1];
            }

            compute_givens(x, y, &c, &s, &r);
            apply_similarity(T, k, c, s);
        }

        extract_tridiagonal(T, d, e);
        printf("  sweep %2d: |e_1|=%9.2e |e_2|=%9.2e |e_3|=%9.2e |e_4|=%9.2e |e_5|=%9.2e\n",
               sweep, fabs(e[0]), fabs(e[1]), fabs(e[2]), fabs(e[3]), fabs(e[4]));

        if (converged(T)) {
            printf("  all subdiagonal entries are effectively zero after sweep %d.\n", sweep);
            break;
        }
    }

    extract_tridiagonal(T, d, e);
    if (mode != MODE_LATEX) {
        printf("\nDemonstration state after repeated sweeps:\n");
        print_vector("diag(T)", d, N);

        qsort(d, N, sizeof(double), cmp_double);
        printf("sorted diag(T) (for illustration of convergence trend):\n");
        print_vector("lambda_like", d, N);
    }

    return 0;
}
