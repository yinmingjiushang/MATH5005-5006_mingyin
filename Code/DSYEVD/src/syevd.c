// syevd.c — Build a KMS SPD matrix A, then call DSYEVD to get
// eigenvalues (+ eigenvectors if JOBZ='V'). Column-major, vendor-agnostic.

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>

/* --------- Fortran LAPACK symbol (vendor-agnostic) --------- */
extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA, double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

/* (Optional, works when linking OpenBLAS; harmless if you remove) */
extern char* openblas_get_config(void);
extern char* openblas_get_corename(void);

/* --------- Utilities --------- */
static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        perror("mkdir");
        exit(5);
    }
}
static double elapsed_seconds(struct timespec a, struct timespec b) {
    return (b.tv_sec - a.tv_sec) + (b.tv_nsec - a.tv_nsec) / 1e9;
}

/* Fill A (n x n, column-major) with a classic SPD KMS test matrix:
   A_ij = rho^{|i-j|} + delta*(i==j), with |rho|<1, delta>=0. */
static void fill_kms(double *A, int n, double rho, double delta)
{
    if (!(rho > -1.0 && rho < 1.0)) rho = 0.95;
    if (delta < 0.0) delta = 0.0;

    double arho = fabs(rho);
    double *rp = (double*)malloc((size_t)n * sizeof(double));
    if (!rp) { fprintf(stderr, "Allocation failed (rp)\n"); exit(6); }

    rp[0] = 1.0;
    for (int k = 1; k < n; ++k) rp[k] = rp[k-1] * arho;

    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            int d = j - i;
            double v = rp[d];
            if (i == j) v += delta;
            A[i + (size_t)j * n] = v;   // upper
            A[j + (size_t)i * n] = v;   // mirror to lower
        }
    }
    free(rp);
}

int main(void)
{
    /* ---- Config ---- */
    const int   n     = 4000;   // matrix size
    const int   lda   = n;
    const char  uplo  = 'U';    // keep 'U' consistently
    const char  jobz  = 'N';    // 'V' for eigenvectors, 'N' for values only
    const double rho   = 0.95;  // KMS difficulty: 0.8 easy ... 0.98 harder
    const double delta = 0.0;   // small positive shift if desired

    /* Optional OpenBLAS banner (comment out if linking another LAPACK) */
    #ifdef __OPENBLAS_CONFIG_H__
    printf("OpenBLAS config: %s\n", openblas_get_config());
    printf("OpenBLAS core  : %s\n", openblas_get_corename());
    #endif

    if (jobz == 'N')
        printf("Mode: DSYEVD (Eigenvalues only, JOBZ='N')\n");
    else
        printf("Mode: DSYEVD (Eigenvalues + eigenvectors, JOBZ='V')\n");

    /* ---- Allocate ---- */
    double *A = (double*)malloc((size_t)n * (size_t)lda * sizeof(double)); // input & (on exit) eigenvectors
    double *W = (double*)malloc((size_t)n * sizeof(double));               // eigenvalues
    if (!A || !W) {
        fprintf(stderr, "Allocation failed.\n");
        free(W); free(A);
        return 1;
    }

    /* ---- Build dense SPD KMS A ---- */
    fill_kms(A, n, rho, delta);

    /* ---- Workspace query ---- */
    int info = 0;
    int lwork = -1, liwork = -1, iwkopt = 0;
    double wkopt = 0.0;

    dsyevd_(&jobz, &uplo, &n, A, &lda, W, &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) { fprintf(stderr, "DSYEVD workspace query failed, info=%d\n", info); goto CLEANUP_ERR; }

    lwork  = (int)wkopt;   if (lwork  < 1) lwork  = 1;
    liwork = iwkopt;       if (liwork < 1) liwork = 1;

    double *WORK = (double*)malloc((size_t)lwork  * sizeof(double));
    int    *IWORK= (int*)   malloc((size_t)liwork * sizeof(int));
    if (!WORK || !IWORK) { fprintf(stderr, "Allocation failed (WORK/IWORK)\n"); free(IWORK); free(WORK); goto CLEANUP_ERR; }

    /* ---- Call DSYEVD & time it ---- */
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    dsyevd_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, IWORK, &liwork, &info);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    if (info != 0) { fprintf(stderr, "DSYEVD failed, info=%d\n", info); free(IWORK); free(WORK); goto CLEANUP_ERR; }
    double time_syevd = elapsed_seconds(t0, t1);

    free(IWORK); free(WORK);

    /* ---- Report timings ---- */
    printf("DSYEVD took %.3f s\n", time_syevd);

    /* ---- Write outputs (same pattern as before) ---- */
    const char *outdir = "../output";
    ensure_dir(outdir);

    char path_time[256], path_w[256], path_v[256];
    snprintf(path_time, sizeof(path_time), "%s/syevd_time.txt", outdir);
    snprintf(path_w,    sizeof(path_w),    "%s/syevd_eigenvalues.txt", outdir);
    snprintf(path_v,    sizeof(path_v),    "%s/syevd_eigenvectors.txt", outdir);

    FILE *ft = fopen(path_time, "w");
    if (ft) {
        fprintf(ft, "Mode: DSYEVD (JOBZ='%c', UPLO='%c')\n", jobz, uplo);
        fprintf(ft, "DSYEVD %.6f s\n", time_syevd);
        fclose(ft);
    }

    FILE *fw = fopen(path_w, "w");
    if (fw) {
        for (int i = 0; i < n; ++i) fprintf(fw, "%.12e\n", W[i]);
        fclose(fw);
    }

    /* On exit, A contains eigenvectors in columns (if JOBZ='V') */
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

    free(W); free(A);
    return 0;

CLEANUP_ERR:
    free(W); free(A);
    return 2;
}
