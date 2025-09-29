#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>

#ifdef _WIN32
  #include <direct.h>   // _mkdir
#else
  #include <sys/stat.h> // mkdir
  #include <sys/types.h>
#endif

/* Fortran LAPACK routine prototype */
extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA,
                    double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

/* portable: ensure output dir exists */
static void ensure_dir(const char *path) {
#ifdef _WIN32
    if (_mkdir(path) != 0 && errno != EEXIST) {
        fprintf(stderr, "Failed to create dir %s (errno=%d)\n", path, errno);
        exit(5);
    }
#else
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        perror("mkdir");
        exit(5);
    }
#endif
}

/* Fill a symmetric matrix (column-major order) with test values */
static void fill_symmetric(double *A, int n) {
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            double v = (i == j) ? (10.0 + 0.01 * i) : (0.1 * (i + j));
            A[i + j * n] = v;
            A[j + i * n] = v;
        }
    }
}

int main(void) {
    const int n    = 4000;
    const int lda  = n;
    const char jobz = 'V';  // compute eigenvalues and eigenvectors
    const char uplo = 'U';  // use upper triangle

    double *A = (double*)malloc(sizeof(double) * (size_t)n * (size_t)lda);
    double *W = (double*)malloc(sizeof(double) * (size_t)n);
    if (!A || !W) { fprintf(stderr, "Allocation failed.\n"); return 1; }
    fill_symmetric(A, n);

    int info = 0, lwork = -1, liwork = -1;
    double wkopt; int iwkopt;

    /* Workspace query */
    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) {
        fprintf(stderr, "DSYEVD workspace query failed, INFO=%d\n", info);
        return 2;
    }

    lwork  = (int)wkopt;
    liwork = iwkopt;

    double *WORK  = (double*)malloc(sizeof(double) * (size_t)lwork);
    int    *IWORK = (int*)   malloc(sizeof(int)    * (size_t)liwork);
    if (!WORK || !IWORK) { fprintf(stderr, "Workspace allocation failed.\n"); return 3; }

    /* --------- Timing start --------- */
    clock_t start = clock();
    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            WORK, &lwork, IWORK, &liwork, &info);
    clock_t end = clock();
    /* --------- Timing end --------- */

    if (info != 0) { fprintf(stderr, "DSYEVD failed, INFO=%d\n", info); return 4; }

    double elapsed_sec = (double)(end - start) / CLOCKS_PER_SEC;

    /* 终端：只打印时间 */
    printf("DSYEVD computation took %.3f seconds.\n", elapsed_sec);

    /* 持久化到 ./output */
    const char *outdir = "output";         // 用相对路径，避免 Windows 对 "./" 的小坑
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
