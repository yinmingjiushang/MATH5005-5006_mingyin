#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <math.h>

/* Fortran LAPACK prototypes */
extern void dsyev_(const char *JOBZ, const char *UPLO, const int *N,
                   double *A, const int *LDA,
                   double *W,
                   double *WORK, const int *LWORK,
                   int *INFO);

extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA,
                    double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

/* -------- timing (seconds) -------- */
static double now_seconds(void) {
#if defined(_POSIX_TIMERS) && (_POSIX_TIMERS > 0)
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec * 1e-9;
#else
    return (double)clock() / (double)CLOCKS_PER_SEC;
#endif
}

/* -------- fs helpers -------- */
static void ensure_output_dir(void) {
    int rc = mkdir("../output", 0777);
    if (rc != 0 && errno != EEXIST) {
        perror("mkdir ../output");
        exit(1);
    }
}

/* -------- data helpers -------- */
static void fill_symmetric(double *A, int n) {
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            double v = (i == j)
                       ? (10.0 + 1e-3 * (i + 1))
                       : (0.1 * ((double)(i + 1) + (double)(j + 1)));
            A[i + j * n] = v;
            A[j + i * n] = v;
        }
    }
}

/* lightweight digest to avoid DCE; sample grid over V */
static void digest_vectors(const double *V, int n, double *out_sum, double *out_l2) {
    int step = (n / 16 > 0) ? (n / 16) : 1;
    double s = 0.0, l2 = 0.0;
    for (int j = 0; j < n; j += step) {
        for (int i = 0; i < n; i += step) {
            double x = V[i + j * n];
            s  += x;
            l2 += x * x;
        }
    }
    *out_sum = s;
    *out_l2  = sqrt(l2);
}

/* -------- io helpers (not timed) -------- */
static void write_eigs(const char *path, const double *W, int n) {
    FILE *fp = fopen(path, "w");
    if (!fp) { perror("fopen eigenvalues"); exit(1); }
    for (int i = 0; i < n; ++i) fprintf(fp, "%.17g\n", W[i]);
    fclose(fp);
}

static void write_digest(const char *path, double sumv, double l2v) {
    FILE *fp = fopen(path, "w");
    if (!fp) { perror("fopen digest"); exit(1); }
    fprintf(fp, "sum(V_samples)=%.17g\n", sumv);
    fprintf(fp, "l2(V_samples)=%.17g\n", l2v);
    fclose(fp);
}

int main(void) {
    /* -------- config -------- */
    const int  N    = 2000;     /* set matrix size here */
    const int  LDA  = N;
    const char JOBZ = 'V';
    const char UPLO = 'L';

    ensure_output_dir();

    /* -------- allocate -------- */
    size_t nn   = (size_t)N * (size_t)N;
    double *A0  = (double*)malloc(nn * sizeof(double));
    double *A1  = (double*)malloc(nn * sizeof(double));
    double *A2  = (double*)malloc(nn * sizeof(double));
    double *W1  = (double*)malloc((size_t)N * sizeof(double));
    double *W2  = (double*)malloc((size_t)N * sizeof(double));
    if (!A0 || !A1 || !A2 || !W1 || !W2) {
        fprintf(stderr, "Allocation failed\n");
        return 1;
    }

    /* -------- init matrix -------- */
    fill_symmetric(A0, N);
    memcpy(A1, A0, nn * sizeof(double));
    memcpy(A2, A0, nn * sizeof(double));

    /* -------- DSYEV -------- */
    int    info = 0;
    int    lwork = -1;
    double wkopt = 0.0;

    dsyev_(&JOBZ, &UPLO, &N, A1, &LDA, W1, &wkopt, &lwork, &info);
    if (info != 0) {
        fprintf(stderr, "dsyev_ workspace query failed: INFO=%d\n", info);
        return 2;
    }
    lwork = (int)wkopt; /* per request: no ceil() */
    if (lwork <= 0) { fprintf(stderr, "Invalid lwork for DSYEV: %d\n", lwork); return 2; }

    double *work1 = (double*)malloc((size_t)lwork * sizeof(double));
    if (!work1) { fprintf(stderr, "Alloc work1 failed\n"); return 2; }

    double t0 = now_seconds();
    dsyev_(&JOBZ, &UPLO, &N, A1, &LDA, W1, work1, &lwork, &info);
    double t1 = now_seconds();

    if (info != 0) {
        fprintf(stderr, "DSYEV failed: INFO=%d\n", info);
        free(work1);
        return 2;
    }
    double time_dsyev = t1 - t0;
    free(work1);

    /* -------- DSYEVD -------- */
    int    lwork2  = -1, liwork2 = -1;
    double wkopt2  = 0.0;
    int    iwkopt2 = 0;

    dsyevd_(&JOBZ, &UPLO, &N, A2, &LDA, W2, &wkopt2, &lwork2, &iwkopt2, &liwork2, &info);
    if (info != 0) {
        fprintf(stderr, "dsyevd_ workspace query failed: INFO=%d\n", info);
        return 3;
    }

    lwork2  = (int)wkopt2;   /* per request: no ceil() */
    liwork2 = iwkopt2;       /* already integer advice */
    if (lwork2 <= 0 || liwork2 <= 0) {
        fprintf(stderr, "Invalid workspace for DSYEVD: lwork=%d liwork=%d\n", lwork2, liwork2);
        return 3;
    }

    double *work2  = (double*)malloc((size_t)lwork2  * sizeof(double));
    int    *iwork2 = (int*)   malloc((size_t)liwork2 * sizeof(int));
    if (!work2 || !iwork2) {
        fprintf(stderr, "Alloc work2/iwork2 failed\n");
        free(work2); free(iwork2);
        return 3;
    }

    t0 = now_seconds();
    dsyevd_(&JOBZ, &UPLO, &N, A2, &LDA, W2, work2, &lwork2, iwork2, &liwork2, &info);
    t1 = now_seconds();

    if (info != 0) {
        fprintf(stderr, "DSYEVD failed: INFO=%d\n", info);
        free(work2); free(iwork2);
        return 3;
    }
    double time_dsyevd = t1 - t0;

    free(work2);
    free(iwork2);

    /* -------- report (stdout not timed) -------- */
    printf("[DSYEV ] n=%d time=%.6f s\n", N, time_dsyev);
    printf("[DSYEVD] n=%d time=%.6f s\n", N, time_dsyevd);
    fflush(stdout);

    /* -------- persist outputs (not timed) -------- */
    double sumV1, l2V1, sumV2, l2V2;
    digest_vectors(A1, N, &sumV1, &l2V1);  /* A1 holds eigenvectors from DSYEV  */
    digest_vectors(A2, N, &sumV2, &l2V2);  /* A2 holds eigenvectors from DSYEVD */

    write_eigs("../output/dsyev_eigs.txt",   W1, N);
    write_eigs("../output/dsyevd_eigs.txt",  W2, N);
    write_digest("../output/dsyev_digest.txt",  sumV1, l2V1);
    write_digest("../output/dsyevd_digest.txt", sumV2, l2V2);

    FILE *tf = fopen("../output/timings.txt", "w");
    if (tf) {
        fprintf(tf, "DSYEV  %.9f\n",  time_dsyev);
        fprintf(tf, "DSYEVD %.9f\n",  time_dsyevd);
        fclose(tf);
    } else {
        perror("fopen ../output/timings.txt");
    }

    /* -------- cleanup -------- */
    free(W2); free(W1);
    free(A2); free(A1); free(A0);

    printf("Results written to ../output/\n");
    return 0;
}
