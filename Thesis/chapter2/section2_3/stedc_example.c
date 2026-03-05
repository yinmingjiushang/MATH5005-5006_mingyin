#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define N 6
#define B 3
#define JACOBI_TOL 1e-14
#define JACOBI_MAX_ITERS 100
#define SEC_BISECT_ITERS 120
#define POLE_EPS 1e-12

typedef enum {
    MODE_LATEX,
    MODE_STEP,
    MODE_FULL
} OutputMode;

static const char *mode_name(OutputMode mode)
{
    switch (mode) {
    case MODE_LATEX: return "latex";
    case MODE_STEP: return "step";
    case MODE_FULL: return "full";
    default: return "latex";
    }
}

static double abs_max(double a, double b)
{
    return fabs(a) > fabs(b) ? fabs(a) : fabs(b);
}

static void print_vector(const char *name, const double *x, int n)
{
    int i;
    printf("%s = [", name);
    for (i = 0; i < n; ++i) {
        printf("%s% .4f", i == 0 ? "" : ", ", x[i]);
    }
    printf("]\n");
}

static void print_matrix6(const char *name, double A[N][N])
{
    int i;
    int j;
    printf("%s\n", name);
    for (i = 0; i < N; ++i) {
        printf("  ");
        for (j = 0; j < N; ++j) {
            double v = fabs(A[i][j]) < 1e-14 ? 0.0 : A[i][j];
            printf("%10.4f", v);
        }
        printf("\n");
    }
}

static void print_matrix3(const char *name, double A[B][B])
{
    int i;
    int j;
    printf("%s\n", name);
    for (i = 0; i < B; ++i) {
        printf("  ");
        for (j = 0; j < B; ++j) {
            double v = fabs(A[i][j]) < 1e-14 ? 0.0 : A[i][j];
            printf("%10.4f", v);
        }
        printf("\n");
    }
}

static void mat_identity3(double A[B][B])
{
    int i;
    int j;
    for (i = 0; i < B; ++i) {
        for (j = 0; j < B; ++j) {
            A[i][j] = (i == j) ? 1.0 : 0.0;
        }
    }
}

static void mat_copy3(double dst[B][B], double src[B][B])
{
    memcpy(dst, src, sizeof(double) * B * B);
}

static void matmul6(double C[N][N], double A[N][N], double Bm[N][N])
{
    int i;
    int j;
    int k;
    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            double s = 0.0;
            for (k = 0; k < N; ++k) {
                s += A[i][k] * Bm[k][j];
            }
            C[i][j] = s;
        }
    }
}

static void transpose6(double At[N][N], double A[N][N])
{
    int i;
    int j;
    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            At[j][i] = A[i][j];
        }
    }
}

static void build_base_tridiagonal(double T[N][N], double *d, double *e)
{
    int i;
    int j;
    for (i = 0; i < N; ++i) {
        d[i] = (double)(i + 1);
    }
    for (i = 0; i < N - 1; ++i) {
        e[i] = 1.0;
    }

    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            T[i][j] = 0.0;
        }
        T[i][i] = d[i];
    }
    for (i = 0; i < N - 1; ++i) {
        T[i][i + 1] = e[i];
        T[i + 1][i] = e[i];
    }
}

static void compensated_split(double T[N][N], int m, double rho, double T1[B][B], double T2[B][B], double u[N])
{
    int i;
    int j;

    for (i = 0; i < B; ++i) {
        for (j = 0; j < B; ++j) {
            T1[i][j] = T[i][j];
            T2[i][j] = T[m + i][m + j];
        }
    }

    T1[m - 1][m - 1] -= rho;
    T2[0][0] -= rho;

    for (i = 0; i < N; ++i) {
        u[i] = 0.0;
    }
    u[m - 1] = 1.0;
    u[m] = 1.0;
}

static void sort_eig3(double eval[B], double evec[B][B])
{
    int i;
    int j;
    for (i = 0; i < B - 1; ++i) {
        int k = i;
        for (j = i + 1; j < B; ++j) {
            if (eval[j] < eval[k]) {
                k = j;
            }
        }
        if (k != i) {
            double tv = eval[i];
            eval[i] = eval[k];
            eval[k] = tv;
            for (j = 0; j < B; ++j) {
                double te = evec[j][i];
                evec[j][i] = evec[j][k];
                evec[j][k] = te;
            }
        }
    }
}

static void canonicalize_evec_signs3(double evec[B][B])
{
    int col;
    for (col = 0; col < B; ++col) {
        int r = 0;
        double best = fabs(evec[0][col]);
        int i;
        for (i = 1; i < B; ++i) {
            double a = fabs(evec[i][col]);
            if (a > best) {
                best = a;
                r = i;
            }
        }
        if (evec[r][col] < 0.0) {
            for (i = 0; i < B; ++i) {
                evec[i][col] = -evec[i][col];
            }
        }
    }
}

static int jacobi_eigen3(double Ain[B][B], double eval[B], double evec[B][B], OutputMode mode, const char *tag)
{
    int iter;
    double A[B][B];

    mat_copy3(A, Ain);
    mat_identity3(evec);

    for (iter = 0; iter < JACOBI_MAX_ITERS; ++iter) {
        int p = 0;
        int q = 1;
        int i;
        int j;
        double max_off = fabs(A[0][1]);

        for (i = 0; i < B; ++i) {
            for (j = i + 1; j < B; ++j) {
                double a = fabs(A[i][j]);
                if (a > max_off) {
                    max_off = a;
                    p = i;
                    q = j;
                }
            }
        }

        if (max_off < JACOBI_TOL) {
            break;
        }

        {
            double app = A[p][p];
            double aqq = A[q][q];
            double apq = A[p][q];
            double phi = 0.5 * atan2(2.0 * apq, aqq - app);
            double c = cos(phi);
            double s = sin(phi);

            for (i = 0; i < B; ++i) {
                if (i != p && i != q) {
                    double aip = A[i][p];
                    double aiq = A[i][q];
                    A[i][p] = c * aip - s * aiq;
                    A[p][i] = A[i][p];
                    A[i][q] = s * aip + c * aiq;
                    A[q][i] = A[i][q];
                }
            }

            A[p][p] = c * c * app - 2.0 * s * c * apq + s * s * aqq;
            A[q][q] = s * s * app + 2.0 * s * c * apq + c * c * aqq;
            A[p][q] = 0.0;
            A[q][p] = 0.0;

            for (i = 0; i < B; ++i) {
                double vip = evec[i][p];
                double viq = evec[i][q];
                evec[i][p] = c * vip - s * viq;
                evec[i][q] = s * vip + c * viq;
            }

            if (mode == MODE_FULL) {
                printf("  [%s] Jacobi iter %d: zero A(%d,%d), offdiag_max=%.3e\n",
                       tag, iter + 1, p + 1, q + 1, max_off);
            }
        }
    }

    if (iter == JACOBI_MAX_ITERS) {
        return 0;
    }

    for (iter = 0; iter < B; ++iter) {
        eval[iter] = A[iter][iter];
    }

    sort_eig3(eval, evec);
    canonicalize_evec_signs3(evec);
    return 1;
}

static void build_Q0(double Q1[B][B], double Q2[B][B], double Q0[N][N])
{
    int i;
    int j;
    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            Q0[i][j] = 0.0;
        }
    }
    for (i = 0; i < B; ++i) {
        for (j = 0; j < B; ++j) {
            Q0[i][j] = Q1[i][j];
            Q0[B + i][B + j] = Q2[i][j];
        }
    }
}

static void matvec6_transpose(double y[N], double A[N][N], const double x[N])
{
    int i;
    int j;
    for (i = 0; i < N; ++i) {
        double s = 0.0;
        for (j = 0; j < N; ++j) {
            s += A[j][i] * x[j];
        }
        y[i] = s;
    }
}

static void build_D_unsorted(const double lam1[B], const double lam2[B], double d_uns[N])
{
    int i;
    for (i = 0; i < B; ++i) {
        d_uns[i] = lam1[i];
        d_uns[B + i] = lam2[i];
    }
}

static void build_rank_one_matrix(double M[N][N], const double d[N], const double v[N], double rho)
{
    int i;
    int j;
    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            M[i][j] = rho * v[i] * v[j];
        }
        M[i][i] += d[i];
    }
}

static void sort_diag_and_vector(const double d_uns[N], const double v_uns[N], double d[N], double v[N], int perm_sorted_to_uns[N])
{
    int used[N] = {0, 0, 0, 0, 0, 0};
    int i;

    for (i = 0; i < N; ++i) {
        int best = -1;
        int j;
        for (j = 0; j < N; ++j) {
            if (used[j]) {
                continue;
            }
            if (best < 0 || d_uns[j] < d_uns[best]) {
                best = j;
            }
        }
        used[best] = 1;
        perm_sorted_to_uns[i] = best;
        d[i] = d_uns[best];
        v[i] = v_uns[best];
    }
}

static void build_permutation_P(double P[N][N], const int perm_sorted_to_uns[N])
{
    int i;
    int j;
    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            P[i][j] = 0.0;
        }
    }

    for (i = 0; i < N; ++i) {
        int old_idx = perm_sorted_to_uns[i];
        P[old_idx][i] = 1.0;
    }
}

static double secular_f(double lambda, const double d[N], const double v[N], double rho)
{
    int i;
    double s = 1.0;
    for (i = 0; i < N; ++i) {
        s -= rho * (v[i] * v[i]) / (lambda - d[i]);
    }
    return s;
}

static double solve_bisect(double left, double right, const double d[N], const double v[N], double rho)
{
    int iter;
    double fl = secular_f(left, d, v, rho);
    double fr = secular_f(right, d, v, rho);

    if (!(fl * fr < 0.0)) {
        return NAN;
    }

    for (iter = 0; iter < SEC_BISECT_ITERS; ++iter) {
        double mid = 0.5 * (left + right);
        double fm = secular_f(mid, d, v, rho);
        if (fl * fm < 0.0) {
            right = mid;
            fr = fm;
        } else {
            left = mid;
            fl = fm;
        }
    }
    return 0.5 * (left + right);
}

static int solve_secular_roots(const double d[N], const double v[N], double rho, double lambda[N], OutputMode mode)
{
    int k;

    for (k = 0; k < N - 1; ++k) {
        double eps_l = POLE_EPS * (1.0 + fabs(d[k]));
        double eps_r = POLE_EPS * (1.0 + fabs(d[k + 1]));
        double left = d[k] + eps_l;
        double right = d[k + 1] - eps_r;
        double fl = secular_f(left, d, v, rho);
        double fr = secular_f(right, d, v, rho);

        if (!(fl * fr < 0.0)) {
            double widen = 2.0;
            int tries;
            for (tries = 0; tries < 12 && !(fl * fr < 0.0); ++tries) {
                left = d[k] + eps_l * widen;
                right = d[k + 1] - eps_r * widen;
                fl = secular_f(left, d, v, rho);
                fr = secular_f(right, d, v, rho);
                widen *= 2.0;
            }
        }

        lambda[k] = solve_bisect(left, right, d, v, rho);
        if (isnan(lambda[k])) {
            return 0;
        }

        if (mode != MODE_LATEX) {
            printf("  root %d in (d_%d, d_%d) = (% .4f, % .4f): lambda_%d = %.4f\n",
                   k + 1, k + 1, k + 2, d[k], d[k + 1], k + 1, lambda[k]);
        }
    }

    {
        double eps = POLE_EPS * (1.0 + fabs(d[N - 1]));
        double left = d[N - 1] + eps;
        double right = d[N - 1] + 1.0;
        double fl = secular_f(left, d, v, rho);
        double fr = secular_f(right, d, v, rho);
        int expand = 0;

        while (!(fl * fr < 0.0) && expand < 80) {
            right = d[N - 1] + pow(2.0, expand + 1);
            fr = secular_f(right, d, v, rho);
            ++expand;
        }

        lambda[N - 1] = solve_bisect(left, right, d, v, rho);
        if (isnan(lambda[N - 1])) {
            return 0;
        }

        if (mode != MODE_LATEX) {
            printf("  root %d in (d_%d, +inf): lambda_%d = %.4f\n",
                   N, N, N, lambda[N - 1]);
        }
    }

    return 1;
}

static void build_Y_from_secular(double Y[N][N], const double d[N], const double v[N], const double lambda[N])
{
    int j;
    for (j = 0; j < N; ++j) {
        int i;
        double nrm2 = 0.0;
        for (i = 0; i < N; ++i) {
            double denom = lambda[j] - d[i];
            Y[i][j] = v[i] / denom;
            nrm2 += Y[i][j] * Y[i][j];
        }
        nrm2 = sqrt(nrm2);
        for (i = 0; i < N; ++i) {
            Y[i][j] /= nrm2;
        }
    }
}

static void print_Y_columns(double Y[N][N], const char *prefix)
{
    int j;
    for (j = 0; j < N; ++j) {
        int i;
        printf("%s%d = [", prefix, j + 1);
        for (i = 0; i < N; ++i) {
            printf("%s% .4f", i == 0 ? "" : ", ", Y[i][j]);
        }
        printf("]\n");
    }
}

static double residual_rank_one(const double d[N], const double v[N], double rho, double Y[N][N], const double lambda[N])
{
    int j;
    double max_abs = 0.0;
    for (j = 0; j < N; ++j) {
        int i;
        double vtq = 0.0;
        for (i = 0; i < N; ++i) {
            vtq += v[i] * Y[i][j];
        }

        for (i = 0; i < N; ++i) {
            double lhs = d[i] * Y[i][j] + rho * v[i] * vtq;
            double rhs = lambda[j] * Y[i][j];
            max_abs = abs_max(max_abs, lhs - rhs);
        }
    }
    return max_abs;
}

static double orthogonality_error(double Q[N][N])
{
    int i;
    int j;
    int k;
    double max_abs = 0.0;

    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            double s = 0.0;
            for (k = 0; k < N; ++k) {
                s += Q[k][i] * Q[k][j];
            }
            if (i == j) {
                s -= 1.0;
            }
            max_abs = abs_max(max_abs, s);
        }
    }

    return max_abs;
}

static void build_diag_matrix(double L[N][N], const double lambda[N])
{
    int i;
    int j;
    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            L[i][j] = 0.0;
        }
        L[i][i] = lambda[i];
    }
}

static double matrix_diff_fro(double A[N][N], double Bm[N][N], double *max_abs_out)
{
    int i;
    int j;
    double s = 0.0;
    double max_abs = 0.0;

    for (i = 0; i < N; ++i) {
        for (j = 0; j < N; ++j) {
            double d = A[i][j] - Bm[i][j];
            s += d * d;
            max_abs = abs_max(max_abs, d);
        }
    }

    *max_abs_out = max_abs;
    return sqrt(s);
}

static void print_interval_table(const double d[N], const double lambda[N])
{
    int i;
    printf("Interlacing check (rho > 0):\n");
    for (i = 0; i < N - 1; ++i) {
        printf("  d_%d = %.4f < lambda_%d = %.4f < d_%d = %.4f\n",
               i + 1, d[i], i + 1, lambda[i], i + 2, d[i + 1]);
    }
    printf("  d_%d = %.4f < lambda_%d = %.4f\n", N, d[N - 1], N, lambda[N - 1]);
}

static void canonicalize_vector_sign(double x[N])
{
    int i;
    int pivot = 0;
    double best = fabs(x[0]);

    for (i = 1; i < N; ++i) {
        double a = fabs(x[i]);
        if (a > best) {
            best = a;
            pivot = i;
        }
    }

    if (x[pivot] < 0.0) {
        for (i = 0; i < N; ++i) {
            x[i] = -x[i];
        }
    }
}

int main(int argc, char **argv)
{
    OutputMode mode = MODE_LATEX;
    double T[N][N];
    double d0[N];
    double e0[N - 1];

    int m = 3;
    double rho = 1.0;

    double T1[B][B];
    double T2[B][B];
    double u[N];

    double lam1[B];
    double lam2[B];
    double Q1[B][B];
    double Q2[B][B];
    double Q0[N][N];
    double v_uns[N];
    double d_uns[N];

    int perm_sorted_to_uns[N];
    double d[N];
    double v[N];

    double M_uns[N][N];
    double M[N][N];
    double lambda[N];
    double Y[N][N];

    double P[N][N];
    double Utmp[N][N];
    double U[N][N];
    double L[N][N];
    double Ut[N][N];
    double Recon[N][N];

    double Q0t[N][N];
    double T_from_rank1[N][N];
    double tmpA[N][N];

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

    build_base_tridiagonal(T, d0, e0);
    compensated_split(T, m, rho, T1, T2, u);

    printf("Teaching demo: STEDC-style divide-and-conquer on a 6x6 tridiagonal matrix\n");
    printf("Output mode: %s\n", mode_name(mode));
    printf("Example setup (Section 2.3):\n");
    print_vector("d", d0, N);
    print_vector("e", e0, N - 1);
    printf("split index m = %d, rho = %.4f\n", m, rho);

    if (mode == MODE_FULL) {
        print_matrix6("Original T:", T);
    }

    print_matrix3("Compensated block T1:", T1);
    print_matrix3("Compensated block T2:", T2);
    print_vector("u = e_m + e_{m+1}", u, N);

    if (!jacobi_eigen3(T1, lam1, Q1, mode, "T1")) {
        fprintf(stderr, "Jacobi did not converge on T1\n");
        return 2;
    }
    if (!jacobi_eigen3(T2, lam2, Q2, mode, "T2")) {
        fprintf(stderr, "Jacobi did not converge on T2\n");
        return 2;
    }

    printf("\nSubproblem diagonalization:\n");
    print_vector("lambda(T1)", lam1, B);
    print_vector("lambda(T2)", lam2, B);

    if (mode != MODE_LATEX) {
        print_matrix3("Q1 (eigenvectors as columns):", Q1);
        print_matrix3("Q2 (eigenvectors as columns):", Q2);
    }

    build_Q0(Q1, Q2, Q0);
    matvec6_transpose(v_uns, Q0, u);
    build_D_unsorted(lam1, lam2, d_uns);

    printf("\nRank-one setup in block-eigen basis:\n");
    print_vector("D (unsorted block order)", d_uns, N);
    print_vector("v = Q0^T u (unsorted block order)", v_uns, N);

    sort_diag_and_vector(d_uns, v_uns, d, v, perm_sorted_to_uns);
    build_permutation_P(P, perm_sorted_to_uns);

    printf("\nAfter global sorting (for secular solve):\n");
    print_vector("d (sorted)", d, N);
    print_vector("v (permuted with d)", v, N);

    build_rank_one_matrix(M_uns, d_uns, v_uns, rho);
    build_rank_one_matrix(M, d, v, rho);
    if (mode != MODE_STEP) {
        print_matrix6("D + rho*v*v^T:", M);
    }

    printf("\nSecular equation solve f(lambda)=0:\n");
    if (!solve_secular_roots(d, v, rho, lambda, mode)) {
        fprintf(stderr, "Secular root solve failed\n");
        return 3;
    }
    print_vector("lambda (roots)", lambda, N);
    print_interval_table(d, lambda);

    build_Y_from_secular(Y, d, v, lambda);
    if (mode == MODE_FULL) {
        printf("\nEigenvectors of D+rho*v*v^T in sorted basis (columns):\n");
        print_Y_columns(Y, "y_");
    }

    {
        double eig_res = residual_rank_one(d, v, rho, Y, lambda);
        double ortho_err = orthogonality_error(Y);
        printf("\nQuality checks in secular stage:\n");
        printf("  max ||(D+rho vv^T) y_i - lambda_i y_i||_inf = %.4e\n", eig_res);
        printf("  max ||Y^T Y - I||_max = %.4e\n", ortho_err);
    }

    {
        double max_abs_rank1;
        double fro_rank1;

        transpose6(Q0t, Q0);
        matmul6(tmpA, Q0, M_uns);
        matmul6(T_from_rank1, tmpA, Q0t);

        fro_rank1 = matrix_diff_fro(T, T_from_rank1, &max_abs_rank1);
        printf("\nCheck T = Q0 (D_unsorted+rho v_unsorted v_unsorted^T) Q0^T:\n");
        printf("  Frobenius error = %.4e, max abs error = %.4e\n", fro_rank1, max_abs_rank1);
        if (mode == MODE_FULL) {
            print_matrix6("Reconstructed T from rank-one stage:", T_from_rank1);
        }
    }

    {
        double max_abs_spec;
        double fro_spec;
        double z1[N];
        int i;

        matmul6(Utmp, Q0, P);
        matmul6(U, Utmp, Y);

        for (i = 0; i < N; ++i) {
            z1[i] = U[i][0];
        }
        canonicalize_vector_sign(z1);

        printf("\nRepresentative eigenvector of T:\n");
        printf("  associated eigenvalue lambda_1 = %.4f\n", lambda[0]);
        print_vector("z_1", z1, N);

        build_diag_matrix(L, lambda);
        transpose6(Ut, U);
        matmul6(tmpA, U, L);
        matmul6(Recon, tmpA, Ut);

        fro_spec = matrix_diff_fro(T, Recon, &max_abs_spec);
        printf("\nFinal reconstruction T = U*Lambda*U^T:\n");
        printf("  Frobenius error = %.4e, max abs error = %.4e\n", fro_spec, max_abs_spec);

        if (mode == MODE_FULL) {
            print_matrix6("U*Lambda*U^T:", Recon);
        }
    }

    return 0;
}
