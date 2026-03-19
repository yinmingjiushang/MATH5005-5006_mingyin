// dsyevd_run.c — portable (OpenBLAS / ArmPL / Netlib), no vendor headers, no macros
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>   // for fabs()

/* Fortran LAPACK symbol (vendor-agnostic) */
extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA,
                    double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

/* Create directory if it does not exist */
static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        perror("mkdir");
        exit(5);
    }
}

/* Fill A (n x n, column-major) with a classic SPD test matrix:
   Kac–Murdock–Szegő (KMS): A_ij = rho^{|i-j|} + delta * (i==j)
   - |rho| < 1 ensures positive definiteness (SPD).
   - delta >= 0 is an optional diagonal shift to push eigenvalues away from 0.
   - This is dense, symmetric, reproducible, and scale-stable up to n=8000. */
static void fill_symmetric(double *A, int n) {
    const double rho   = 0.95;   /* adjust: 0.8 (easier) … 0.98 (harder / higher cond) */
    const double delta = 0.0;    /* adjust: e.g., 1e-6 if you want a small safety shift */

    /* Guard against invalid parameters; clamp to a safe SPD configuration. */
    double arho = fabs(rho);
    if (!(arho > 0.0 && arho < 1.0)) {
        arho = 0.95; /* fallback */
    }

    /* Precompute rp[k] = |rho|^k to avoid repeated pow() calls. */
    double *rp = (double*)malloc((size_t)n * sizeof(double));
    if (!rp) {
        fprintf(stderr, "Allocation failed (rp).\n");
        exit(6);
    }
    rp[0] = 1.0;
    for (int k = 1; k < n; ++k) rp[k] = rp[k-1] * arho;

    /* Fill upper triangle and mirror to lower triangle (column-major). */
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            int d = j - i;                 /* |i - j| when i <= j */
            double v = rp[d];
            if (i == j) v += delta;        /* optional diagonal shift */
            A[i + (size_t)j * n] = v;      /* upper triangle */
            A[j + (size_t)i * n] = v;      /* symmetric fill (lower triangle) */
        }
    }
    free(rp);
}

/* Elapsed time helper (seconds) */
static double elapsed_seconds(struct timespec a, struct timespec b) {
    return (b.tv_sec - a.tv_sec) + (b.tv_nsec - a.tv_nsec) / 1e9;
}

int main(void) {
    const int n = 4000;
    const int lda = n;
    const char jobz = 'V';   /* 'N' for eigenvalues only; 'V' to compute eigenvectors */
    const char uplo = 'U';   /* we fill the full matrix; choose 'U' or 'L' consistently */

    if (jobz == 'N') {
        printf("Mode: Eigenvalues only (JOBZ = 'N')\n");
    } else {
        printf("Mode: Eigenvalues and Eigenvectors (JOBZ = 'V')\n");
    }

    /* Allocate matrix and eigenvalue array */
    double *A = (double*)malloc((size_t)n * (size_t)lda * sizeof(double));
    double *W = (double*)malloc((size_t)n * sizeof(double));
    if (!A || !W) {
        fprintf(stderr, "Allocation failed.\n");
        free(W); free(A);
        return 1;
    }

    /* Fill A with a classic SPD test matrix (KMS) */
    fill_symmetric(A, n);

    /* Workspace query */
    int info = 0, lwork = -1, liwork = -1;
    double wkopt; int iwkopt;

    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) {
        fprintf(stderr, "DSYEVD workspace query failed, INFO=%d\n", info);
        free(W); free(A);
        return 2;
    }

    lwork  = (int)wkopt;
    liwork = iwkopt;

    double *WORK  = (double*)malloc((size_t)lwork  * sizeof(double));
    int    *IWORK = (int*)   malloc((size_t)liwork * sizeof(int));
    if (!WORK || !IWORK) {
        fprintf(stderr, "Workspace allocation failed.\n");
        free(IWORK); free(WORK); free(W); free(A);
        return 3;
    }

    /* Time the SYEVD computation */
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            WORK, &lwork, IWORK, &liwork, &info);
    clock_gettime(CLOCK_MONOTONIC, &t1);

    if (info != 0) {
        fprintf(stderr, "DSYEVD failed, INFO=%d\n", info);
        free(IWORK); free(WORK); free(W); free(A);
        return 4;
    }

    double elapsed_sec = elapsed_seconds(t0, t1);
    printf("DSYEVD computation took %.3f seconds.\n", elapsed_sec);

    /* Outputs */
    const char *outdir = "../output";
    ensure_dir(outdir);

    char path_time[256], path_w[256], path_v[256];
    snprintf(path_time, sizeof(path_time), "%s/time.txt", outdir);
    snprintf(path_w,    sizeof(path_w),    "%s/eigenvalues.txt", outdir);
    snprintf(path_v,    sizeof(path_v),    "%s/eigenvectors.txt", outdir);

    FILE *ft = fopen(path_time, "w");
    if (ft) {
        fprintf(ft, "DSYEVD computation took %.3f seconds.\n", elapsed_sec);
        fclose(ft);
    }

    FILE *fw = fopen(path_w, "w");
    if (fw) {
        for (int i = 0; i < n; ++i) fprintf(fw, "%.12e\n", W[i]);
        fclose(fw);
    }

    if (jobz == 'V') {
        FILE *fv = fopen(path_v, "w");
        if (fv) {
            for (int j = 0; j < n; ++j) {
                for (int i = 0; i < n; ++i) {
                    fprintf(fv, "%.6e%c", A[i + (size_t)j * n], (i == n-1) ? '\n' : ' ');
                }
            }
            fclose(fv);
        }
    }

    free(IWORK); free(WORK); free(W); free(A);
    return 0;
}
