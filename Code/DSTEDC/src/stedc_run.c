// stedc_run.c — Build a KMS SPD matrix A, reduce to tridiagonal, then
// DSTEDC('V') to get eigenvalues + eigenvectors of A (divide & conquer).
// Portable Fortran symbols; no vendor headers; column-major layout.

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>

/* --------- Fortran LAPACK symbols (vendor-agnostic) --------- */
extern void dsytrd_(const char *UPLO, const int *N,
                    double *A, const int *LDA,
                    double *D, double *E, double *TAU,
                    double *WORK, const int *LWORK, int *INFO);

extern void dorgtr_(const char *UPLO, const int *N,
                    double *A, const int *LDA, double *TAU,
                    double *WORK, const int *LWORK, int *INFO);

extern void dstedc_(const char *COMPZ, const int *N,
                    double *D, double *E,
                    double *Z, const int *LDZ,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

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
    extern char* openblas_get_config(void);
    extern char* openblas_get_corename(void);

    printf("OpenBLAS config: %s\n", openblas_get_config());
    printf("OpenBLAS core  : %s\n", openblas_get_corename());
    /* ---- Config ---- */
    const int   n    = 4000;     // matrix size
    const int   lda  = n;
    const char  uplo = 'U';      // keep 'U' along the whole chain
    const char  compz = 'V';     // we want eigenvectors of A (not only T)
//    const char  compz = 'N';
    const double rho   = 0.95;   // KMS parameter: 0.8 easy ... 0.98 harder
    const double delta = 0.0;    // small positive shift if you want more safety

    /* Print mode at the beginning */
    if (compz == 'N')
        printf("Mode: STEDC (Eigenvalues only, COMPZ='N')\n");
    else if (compz == 'I')
        printf("Mode: STEDC (Eigenvalues + eigenvectors of T, COMPZ='I')\n");
    else if (compz == 'V')
        printf("Mode: STEDC (Eigenvalues + eigenvectors of A, COMPZ='V')\n");

    /* ---- Allocate ---- */
    double *A   = (double*)malloc((size_t)n * (size_t)lda * sizeof(double)); // will become Q, then Z
    double *D   = (double*)malloc((size_t)n * sizeof(double));
    double *E   = (double*)malloc((size_t)(n>0? n-1 : 0) * sizeof(double));
    double *TAU = (double*)malloc((size_t)(n>0? n-1 : 0) * sizeof(double));
    if (!A || !D || (!E && n>1) || (!TAU && n>1)) {
        fprintf(stderr, "Allocation failed.\n");
        free(TAU); free(E); free(D); free(A);
        return 1;
    }

    /* ---- Build dense SPD KMS A ---- */
    fill_kms(A, n, rho, delta);

    /* ---- 1) Reduce A -> T via DSYTRD ---- */
    int info = 0, lwork = -1;
    double wkopt;
    struct timespec t0, t1, t2, t3, t4, t5;

    dsytrd_(&uplo, &n, A, &lda, D, E, TAU, &wkopt, &lwork, &info);
    if (info != 0) { fprintf(stderr, "DSYTRD workspace query failed, info=%d\n", info); goto CLEANUP_ERR; }
    lwork = (int)wkopt;
    if (lwork < 1) lwork = 1;
    double *WORK = (double*)malloc((size_t)lwork * sizeof(double));
    if (!WORK) { fprintf(stderr, "Allocation failed (WORK for DSYTRD)\n"); goto CLEANUP_ERR; }

    clock_gettime(CLOCK_MONOTONIC, &t0);
    dsytrd_(&uplo, &n, A, &lda, D, E, TAU, WORK, &lwork, &info);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    if (info != 0) { fprintf(stderr, "DSYTRD failed, info=%d\n", info); free(WORK); goto CLEANUP_ERR; }
    double time_sytrd = elapsed_seconds(t0, t1);
    free(WORK); WORK = NULL;

    /* ---- 2) Form Q explicitly in-place using DORGTR ---- */
    lwork = -1; dorgtr_(&uplo, &n, A, &lda, TAU, &wkopt, &lwork, &info);
    if (info != 0) { fprintf(stderr, "DORGTR workspace query failed, info=%d\n", info); goto CLEANUP_ERR; }
    lwork = (int)wkopt;
    if (lwork < 1) lwork = 1;
    WORK = (double*)malloc((size_t)lwork * sizeof(double));
    if (!WORK) { fprintf(stderr, "Allocation failed (WORK for DORGTR)\n"); goto CLEANUP_ERR; }

    clock_gettime(CLOCK_MONOTONIC, &t2);
    dorgtr_(&uplo, &n, A, &lda, TAU, WORK, &lwork, &info);
    clock_gettime(CLOCK_MONOTONIC, &t3);
    if (info != 0) { fprintf(stderr, "DORGTR failed, info=%d\n", info); free(WORK); goto CLEANUP_ERR; }
    double time_dorgtr = elapsed_seconds(t2, t3);
    free(WORK); WORK = NULL;

    /* ---- 3) DSTEDC('V') ---- */
    double *Z = A;          // reuse A's storage for Z (Q overwritten to Q*Y)
    int ldz = lda;

    int liwork = -1, iwkopt;
    lwork = -1; wkopt = 0.0;
    clock_gettime(CLOCK_MONOTONIC, &t4);
    dstedc_(&compz, &n, D, E, Z, &ldz, &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) { fprintf(stderr, "DSTEDC workspace query failed, info=%d\n", info); goto CLEANUP_ERR; }
    lwork  = (int)wkopt;
    liwork = iwkopt;
    if (lwork  < 1) lwork  = 1;
    if (liwork < 1) liwork = 1;

    WORK        = (double*)malloc((size_t)lwork  * sizeof(double));
    int *IWORK  = (int*)   malloc((size_t)liwork * sizeof(int));
    if (!WORK || !IWORK) { fprintf(stderr, "Allocation failed (WORK/IWORK for DSTEDC)\n"); free(IWORK); free(WORK); goto CLEANUP_ERR; }

    dstedc_(&compz, &n, D, E, Z, &ldz, WORK, &lwork, IWORK, &liwork, &info);
    clock_gettime(CLOCK_MONOTONIC, &t5);
    if (info != 0) { fprintf(stderr, "DSTEDC failed, info=%d\n", info); free(IWORK); free(WORK); goto CLEANUP_ERR; }
    double time_dstedc = elapsed_seconds(t4, t5);
    free(IWORK); free(WORK);

    /* ---- Report timings ---- */
    printf("DSYTRD (A -> T) took %.3f s\n", time_sytrd);
    printf("DORGTR (form Q) took %.3f s\n", time_dorgtr);
    printf("DSTEDC('V')      took %.3f s\n", time_dstedc);
    printf("Total            took %.3f s\n", time_sytrd + time_dorgtr + time_dstedc);

    /* ---- Write outputs ---- */
    const char *outdir = "../output";
    ensure_dir(outdir);

    char path_time[256], path_w[256], path_v[256];
    snprintf(path_time, sizeof(path_time), "%s/stedc_time.txt", outdir);
    snprintf(path_w,    sizeof(path_w),    "%s/stedc_eigenvalues.txt", outdir);
    snprintf(path_v,    sizeof(path_v),    "%s/stedc_eigenvectors.txt", outdir);

    FILE *ft = fopen(path_time, "w");
    if (ft) {
        fprintf(ft, "Mode: STEDC (COMPZ='%c')\n", compz);
        fprintf(ft, "DSYTRD  %.6f s\n", time_sytrd);
        fprintf(ft, "DORGTR  %.6f s\n", time_dorgtr);
        fprintf(ft, "DSTEDC  %.6f s\n", time_dstedc);
        fprintf(ft, "TOTAL   %.6f s\n", time_sytrd + time_dorgtr + time_dstedc);
        fclose(ft);
    }

    FILE *fw = fopen(path_w, "w");
    if (fw) {
        for (int i = 0; i < n; ++i) fprintf(fw, "%.12e\n", D[i]);
        fclose(fw);
    }

    /* Z columns are eigenvectors of A */
    FILE *fv = fopen(path_v, "w");
    if (fv) {
        for (int j = 0; j < n; ++j) {
            for (int i = 0; i < n; ++i) {
                fprintf(fv, "%.6e%c", Z[i + (size_t)j * n], (i == n-1) ? '\n' : ' ');
            }
        }
        fclose(fv);
    }

    free(TAU); free(E); free(D); free(A);
    return 0;

CLEANUP_ERR:
    free(TAU); free(E); free(D); free(A);
    return 2;
}
