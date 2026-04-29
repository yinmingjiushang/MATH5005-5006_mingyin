// post_reduction_threshold.c
// Measure only the post-reduction branch used by slide 12:
//   DSYEV  post = DORGTR + DSTEQR
//   DSYEVD post = DSTEDC + DORMTR
// Each requested size is measured once.

#define _POSIX_C_SOURCE 200112L

#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>

extern void dsyev_(const char *JOBZ, const char *UPLO, const int *N,
                   double *A, const int *LDA, double *W,
                   double *WORK, const int *LWORK, int *INFO);

extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA, double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

extern void __real_dorgtr_(char *UPLO, int *N, double *A, int *LDA,
                           double *TAU, double *WORK, int *LWORK, int *INFO);
extern void __real_dsteqr_(char *COMPZ, int *N, double *D, double *E,
                           double *Z, int *LDZ, double *WORK, int *INFO);
extern void __real_dstedc_(char *COMPZ, int *N, double *D, double *E,
                           double *Z, int *LDZ, double *WORK, int *LWORK,
                           int *IWORK, int *LIWORK, int *INFO);
extern void __real_dormtr_(char *SIDE, char *UPLO, char *TRANS,
                           int *M, int *N, double *A, int *LDA, double *TAU,
                           double *C, int *LDC, double *WORK, int *LWORK,
                           int *INFO);

__attribute__((weak)) void openblas_set_num_threads(int);
__attribute__((weak)) void mkl_set_num_threads(int);

typedef struct {
    double dorgtr_s;
    double dsteqr_s;
    double dstedc_s;
    double dormtr_s;
} timers_t;

static timers_t G_TIMERS;

static double now_s(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

static void timers_reset(void) {
    memset(&G_TIMERS, 0, sizeof(G_TIMERS));
}

void __wrap_dorgtr_(char *UPLO, int *N, double *A, int *LDA,
                    double *TAU, double *WORK, int *LWORK, int *INFO) {
    double t0 = now_s();
    __real_dorgtr_(UPLO, N, A, LDA, TAU, WORK, LWORK, INFO);
    G_TIMERS.dorgtr_s += now_s() - t0;
}

void __wrap_dsteqr_(char *COMPZ, int *N, double *D, double *E,
                    double *Z, int *LDZ, double *WORK, int *INFO) {
    double t0 = now_s();
    __real_dsteqr_(COMPZ, N, D, E, Z, LDZ, WORK, INFO);
    G_TIMERS.dsteqr_s += now_s() - t0;
}

void __wrap_dstedc_(char *COMPZ, int *N, double *D, double *E,
                    double *Z, int *LDZ, double *WORK, int *LWORK,
                    int *IWORK, int *LIWORK, int *INFO) {
    double t0 = now_s();
    __real_dstedc_(COMPZ, N, D, E, Z, LDZ, WORK, LWORK, IWORK, LIWORK, INFO);
    G_TIMERS.dstedc_s += now_s() - t0;
}

void __wrap_dormtr_(char *SIDE, char *UPLO, char *TRANS,
                    int *M, int *N, double *A, int *LDA, double *TAU,
                    double *C, int *LDC, double *WORK, int *LWORK, int *INFO) {
    double t0 = now_s();
    __real_dormtr_(SIDE, UPLO, TRANS, M, N, A, LDA, TAU, C, LDC, WORK, LWORK, INFO);
    G_TIMERS.dormtr_s += now_s() - t0;
}

static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        perror(path);
        exit(5);
    }
}

static void set_threads(int t) {
    char buf[16];
    snprintf(buf, sizeof(buf), "%d", t);
    setenv("OMP_NUM_THREADS", buf, 1);
    setenv("OPENBLAS_NUM_THREADS", buf, 1);
    setenv("ARMPL_NUM_THREADS", buf, 1);
    if (openblas_set_num_threads) openblas_set_num_threads(t);
    if (mkl_set_num_threads) mkl_set_num_threads(t);
}

static void fill_kms(double *A, int n, double rho) {
    double arho = fabs(rho);
    double *rp = (double *)malloc((size_t)n * sizeof(double));
    if (!rp) {
        fprintf(stderr, "malloc failed for powers, n=%d\n", n);
        exit(6);
    }
    rp[0] = 1.0;
    for (int k = 1; k < n; ++k) rp[k] = rp[k - 1] * arho;
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            double v = rp[j - i];
            A[i + (size_t)j * n] = v;
            A[j + (size_t)i * n] = v;
        }
    }
    free(rp);
}

static double run_dsyev_post(int n, double rho, double *dorgtr_s, double *dsteqr_s) {
    const char jobz = 'V';
    const char uplo = 'U';
    int lda = n;
    int info = 0;
    int lwork = -1;
    double wkopt = 0.0;
    size_t nn = (size_t)n * (size_t)n;

    double *A = (double *)malloc(nn * sizeof(double));
    double *W = (double *)malloc((size_t)n * sizeof(double));
    if (!A || !W) {
        fprintf(stderr, "DSYEV allocation failed, n=%d\n", n);
        exit(7);
    }

    fill_kms(A, n, rho);
    dsyev_(&jobz, &uplo, &n, A, &lda, W, &wkopt, &lwork, &info);
    if (info != 0) {
        fprintf(stderr, "DSYEV workspace query failed, n=%d, info=%d\n", n, info);
        exit(8);
    }

    lwork = (int)wkopt;
    if (lwork < 1) lwork = 1;
    double *WORK = (double *)malloc((size_t)lwork * sizeof(double));
    if (!WORK) {
        fprintf(stderr, "DSYEV work allocation failed, n=%d\n", n);
        exit(9);
    }

    fill_kms(A, n, rho);
    timers_reset();
    dsyev_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, &info);
    if (info != 0) {
        fprintf(stderr, "DSYEV failed, n=%d, info=%d\n", n, info);
        exit(10);
    }

    *dorgtr_s = G_TIMERS.dorgtr_s;
    *dsteqr_s = G_TIMERS.dsteqr_s;

    free(WORK);
    free(W);
    free(A);
    return *dorgtr_s + *dsteqr_s;
}

static double run_dsyevd_post(int n, double rho, double *dstedc_s, double *dormtr_s) {
    const char jobz = 'V';
    const char uplo = 'U';
    int lda = n;
    int info = 0;
    int lwork = -1;
    int liwork = -1;
    int iwkopt = 0;
    double wkopt = 0.0;
    size_t nn = (size_t)n * (size_t)n;

    double *A = (double *)malloc(nn * sizeof(double));
    double *W = (double *)malloc((size_t)n * sizeof(double));
    if (!A || !W) {
        fprintf(stderr, "DSYEVD allocation failed, n=%d\n", n);
        exit(11);
    }

    fill_kms(A, n, rho);
    dsyevd_(&jobz, &uplo, &n, A, &lda, W, &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) {
        fprintf(stderr, "DSYEVD workspace query failed, n=%d, info=%d\n", n, info);
        exit(12);
    }

    lwork = (int)wkopt;
    liwork = iwkopt;
    if (lwork < 1) lwork = 1;
    if (liwork < 1) liwork = 1;
    double *WORK = (double *)malloc((size_t)lwork * sizeof(double));
    int *IWORK = (int *)malloc((size_t)liwork * sizeof(int));
    if (!WORK || !IWORK) {
        fprintf(stderr, "DSYEVD work allocation failed, n=%d\n", n);
        exit(13);
    }

    fill_kms(A, n, rho);
    timers_reset();
    dsyevd_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, IWORK, &liwork, &info);
    if (info != 0) {
        fprintf(stderr, "DSYEVD failed, n=%d, info=%d\n", n, info);
        exit(14);
    }

    *dstedc_s = G_TIMERS.dstedc_s;
    *dormtr_s = G_TIMERS.dormtr_s;

    free(IWORK);
    free(WORK);
    free(W);
    free(A);
    return *dstedc_s + *dormtr_s;
}

static int parse_size(const char *s) {
    char *end = NULL;
    long v = strtol(s, &end, 10);
    if (!s[0] || (end && *end) || v <= 0 || v > 50000) {
        fprintf(stderr, "Invalid matrix size: %s\n", s);
        exit(2);
    }
    return (int)v;
}

int main(int argc, char **argv) {
    const double rho = 0.95;
    const int default_sizes[] = {512, 1024, 2048, 4096, 6144, 8192};
    int threads = 1;

    const char *env_threads = getenv("POST_REDUCTION_THREADS");
    if (env_threads && env_threads[0]) threads = parse_size(env_threads);
    set_threads(threads);

    ensure_dir("output");
    int write_header = 1;
    FILE *existing = fopen("output/post_reduction_threshold.csv", "r");
    if (existing) {
        if (fgetc(existing) != EOF) write_header = 0;
        fclose(existing);
    }

    FILE *csv = fopen("output/post_reduction_threshold.csv", "a");
    if (!csv) {
        perror("output/post_reduction_threshold.csv");
        return 3;
    }

    if (write_header) {
        fprintf(csv,
                "threads,n,syev_dorgtr_s,syev_dsteqr_s,syev_post_s,"
                "syevd_dstedc_s,syevd_dormtr_s,syevd_post_s,post_reduction_speedup\n");
    }

    printf("threads,n,syev_post_s,syevd_post_s,post_reduction_speedup\n");

    int count = argc > 1 ? argc - 1 : (int)(sizeof(default_sizes) / sizeof(default_sizes[0]));
    for (int i = 0; i < count; ++i) {
        int n = argc > 1 ? parse_size(argv[i + 1]) : default_sizes[i];
        double dorgtr_s = 0.0, dsteqr_s = 0.0;
        double dstedc_s = 0.0, dormtr_s = 0.0;
        double syev_post = run_dsyev_post(n, rho, &dorgtr_s, &dsteqr_s);
        double syevd_post = run_dsyevd_post(n, rho, &dstedc_s, &dormtr_s);
        double speedup = syevd_post > 0.0 ? syev_post / syevd_post : NAN;

        printf("%d,%d,%.6f,%.6f,%.3f\n", threads, n, syev_post, syevd_post, speedup);
        fprintf(csv,
                "%d,%d,%.9f,%.9f,%.9f,%.9f,%.9f,%.9f,%.6f\n",
                threads, n, dorgtr_s, dsteqr_s, syev_post,
                dstedc_s, dormtr_s, syevd_post, speedup);
        fflush(csv);
    }

    fclose(csv);
    return 0;
}
