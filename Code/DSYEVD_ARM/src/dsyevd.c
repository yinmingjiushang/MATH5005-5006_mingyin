// dsyedv_run_arm.c (Linux + ARM only)
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <openblas_config.h>
/* Explicit forward declarations in case the header doesn't provide them */
extern const char* openblas_get_config(void);
extern const char* openblas_get_corename(void);

extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA,
                    double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        perror("mkdir");
        exit(5);
    }
}

static void fill_symmetric(double *A, int n) {
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            double v = (i == j) ? (10.0 + 0.01 * i) : (0.1 * (i + j));
            A[i + j * n] = v;
            A[j + i * n] = v;
        }
    }
}

static double elapsed_seconds(struct timespec a, struct timespec b) {
    return (b.tv_sec - a.tv_sec) + (b.tv_nsec - a.tv_nsec) / 1e9;
}

int main(void) {

    printf("Using OpenBLAS: %s | Core: %s\n",
           openblas_get_config(), openblas_get_corename());

    const int n = 4000;
    const int lda = n;
    const char jobz = 'V';
    const char uplo = 'U';

    double *A = (double*)malloc(sizeof(double) * (size_t)n * (size_t)lda);
    double *W = (double*)malloc(sizeof(double) * (size_t)n);
    if (!A || !W) { fprintf(stderr, "Allocation failed.\n"); return 1; }
    fill_symmetric(A, n);

    int info = 0, lwork = -1, liwork = -1;
    double wkopt; int iwkopt;

    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) { fprintf(stderr, "DSYEVD workspace query failed, INFO=%d\n", info); return 2; }

    lwork  = (int)wkopt;
    liwork = iwkopt;

    double *WORK  = (double*)malloc(sizeof(double) * (size_t)lwork);
    int    *IWORK = (int*)   malloc(sizeof(int)    * (size_t)liwork);
    if (!WORK || !IWORK) { fprintf(stderr, "Workspace allocation failed.\n"); return 3; }

    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            WORK, &lwork, IWORK, &liwork, &info);
    clock_gettime(CLOCK_MONOTONIC, &t1);

    if (info != 0) { fprintf(stderr, "DSYEVD failed, INFO=%d\n", info); return 4; }

    double elapsed_sec = elapsed_seconds(t0, t1);
    printf("DSYEVD computation took %.3f seconds.\n", elapsed_sec);

    const char *outdir = "output";
    ensure_dir(outdir);

    char path_time[256], path_w[256], path_v[256];
    snprintf(path_time, sizeof(path_time), "%s/time.txt", outdir);
    snprintf(path_w,    sizeof(path_w),    "%s/eigenvalues.txt", outdir);
    snprintf(path_v,    sizeof(path_v),    "%s/eigenvectors.txt", outdir);

    FILE *ft = fopen(path_time, "w");
    if (ft) { fprintf(ft, "DSYEVD computation took %.3f seconds.\n", elapsed_sec); fclose(ft); }

    FILE *fw = fopen(path_w, "w");
    if (fw) { for (int i = 0; i < n; ++i) fprintf(fw, "%.12e\n", W[i]); fclose(fw); }

    if (jobz == 'V') {
        FILE *fv = fopen(path_v, "w");
        if (fv) {
            for (int j = 0; j < n; ++j) {
                for (int i = 0; i < n; ++i) {
                    fprintf(fv, "%.6e%c", A[i + j * n], (i == n-1) ? '\n' : ' ');
                }
            }
            fclose(fv);
        }
    }

    free(IWORK); free(WORK); free(W); free(A);
    return 0;
}
