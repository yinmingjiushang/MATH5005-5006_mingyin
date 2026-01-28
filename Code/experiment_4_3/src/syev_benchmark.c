// syev_benchmark.c
// ------------------------------------------------------------
// Fixed-parameter DSYEV benchmark with subroutine timings for:
//   DSYTRD (tridiagonalization), DORGTR (form Q), DSTEQR (tri eigensolver)
// Also prints total DSYEV time. No other subroutine timing/flamegraph.
// Threads: {1,2}  Sizes: {512, 1024, 2048, 4096, 8192}  JOBZ='V'.
//
// Lightweight output: only the first 5 eigenvalues and first 5 eigenvector
// columns are written to files for verification (to prevent dead-code
// elimination without causing large I/O overhead).
// ------------------------------------------------------------

#define _POSIX_C_SOURCE 200112L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>

#ifndef LIB_TAG
#define LIB_TAG "unknown"
#endif
#ifndef ROUTINE_NAME
#define ROUTINE_NAME "syev"
#endif
#ifndef OUTPUT_K
#define OUTPUT_K 20
#endif

/* -------- LAPACK symbols (Fortran) -------- */
extern void dsyev_(const char *JOBZ, const char *UPLO, const int *N,
                   double *A, const int *LDA, double *W,
                   double *WORK, const int *LWORK, int *INFO);

/* --- Real (library) entry points --- */
extern void __real_dsytrd_(char *UPLO, int *N, double *A, int *LDA,
                           double *D, double *E, double *TAU,
                           double *WORK, int *LWORK, int *INFO);

extern void __real_dorgtr_(char *UPLO, int *N, double *A, int *LDA,
                           double *TAU, double *WORK, int *LWORK, int *INFO);

extern void __real_dsteqr_(char *COMPZ, int *N, double *D, double *E,
                           double *Z, int *LDZ, double *WORK, int *INFO);

/* Optional thread APIs */
__attribute__((weak)) void openblas_set_num_threads(int);
__attribute__((weak)) void mkl_set_num_threads(int);

/* ---------- Timing registry for 3 routines ---------- */
typedef struct {
    double dsytrd_s, dorgtr_s, dsteqr_s;
    unsigned long long dsytrd_calls, dorgtr_calls, dsteqr_calls;
} sub_timers_t;

static sub_timers_t G_TIMERS;

static inline double now_s(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}
static inline void timers_reset(void) {
    memset(&G_TIMERS, 0, sizeof(G_TIMERS));
}

/* -------- Timed wrappers -------- */
void __wrap_dsytrd_(char *UPLO, int *N, double *A, int *LDA,
                    double *D, double *E, double *TAU,
                    double *WORK, int *LWORK, int *INFO)
{
    double t0 = now_s();
    __real_dsytrd_(UPLO, N, A, LDA, D, E, TAU, WORK, LWORK, INFO);
    G_TIMERS.dsytrd_s += (now_s() - t0);
    G_TIMERS.dsytrd_calls++;
}

void __wrap_dorgtr_(char *UPLO, int *N, double *A, int *LDA,
                    double *TAU, double *WORK, int *LWORK, int *INFO)
{
    double t0 = now_s();
    __real_dorgtr_(UPLO, N, A, LDA, TAU, WORK, LWORK, INFO);
    G_TIMERS.dorgtr_s += (now_s() - t0);
    G_TIMERS.dorgtr_calls++;
}

void __wrap_dsteqr_(char *COMPZ, int *N, double *D, double *E,
                    double *Z, int *LDZ, double *WORK, int *INFO)
{
    double t0 = now_s();
    __real_dsteqr_(COMPZ, N, D, E, Z, LDZ, WORK, INFO);
    G_TIMERS.dsteqr_s += (now_s() - t0);
    G_TIMERS.dsteqr_calls++;
}

/* -------- Utilities -------- */
static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        perror("mkdir");
        exit(5);
    }
}
static double elapsed_seconds(struct timespec a, struct timespec b) {
    return (b.tv_sec - a.tv_sec) + (b.tv_nsec - a.tv_nsec) / 1e9;
}
static void set_threads(int t) {
    char buf[8]; snprintf(buf, sizeof(buf), "%d", t);
    setenv("OMP_NUM_THREADS", buf, 1);
    setenv("OPENBLAS_NUM_THREADS", buf, 1);
    setenv("ARMPL_NUM_THREADS", buf, 1);
    if (openblas_set_num_threads) openblas_set_num_threads(t);
    if (mkl_set_num_threads)      mkl_set_num_threads(t);
}

/* SPD KMS matrix: A_ij = rho^{|i-j|} + delta*(i==j) */
static void fill_kms(double *A, int n, double rho, double delta) {
    if (!(rho > -1.0 && rho < 1.0)) rho = 0.95;
    if (delta < 0.0) delta = 0.0;
    double arho = fabs(rho);
    double *rp = (double*)malloc((size_t)n * sizeof(double));
    if (!rp) { fprintf(stderr, "malloc failed\n"); exit(6); }
    rp[0] = 1.0;
    for (int k = 1; k < n; ++k) rp[k] = rp[k-1] * arho;
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            double v = rp[j-i]; if (i == j) v += delta;
            A[i + (size_t)j * n] = v;
            A[j + (size_t)i * n] = v;
        }
    }
    free(rp);
}

/* -------- Main benchmark -------- */
int main(void) {
    const char jobz = 'V', uplo = 'U';
    const double rho = 0.95, delta = 0.0;
    // const int sizes[]   = {512, 1024, 2048, 4096, 8192};
    const int sizes[]   = {512, 1024, 2048};
    const int nsizes    = (int)(sizeof(sizes) / sizeof(sizes[0]));
    const int threads[] = {1};
    const int nthr      = (int)(sizeof(threads) / sizeof(threads[0]));

    const char *lib_tag = LIB_TAG;
    const char *routine = ROUTINE_NAME;
    char out_root[256];
    char out_lib[256];
    char out_routine[256];
    snprintf(out_root, sizeof(out_root), "../output");
    snprintf(out_lib, sizeof(out_lib), "%s/%s", out_root, lib_tag);
    snprintf(out_routine, sizeof(out_routine), "%s/%s", out_lib, routine);
    ensure_dir(out_root);
    ensure_dir(out_lib);
    ensure_dir(out_routine);

    char csv_path[256];
    snprintf(csv_path, sizeof(csv_path), "%s/%s_benchmark.csv", out_lib, routine);
    FILE *csv = fopen(csv_path, "w");
    if (csv)
        fprintf(csv, "lib,routine,threads,N,total_s,dsytrd_s,dorgtr_s,dsteqr_s\n");

    printf("==============================================================\n");
    printf(" DSYEV Benchmark (JOBZ='V') — Total & 3 subroutines\n");
    printf(" rho=%.2f, delta=%.2f\n", rho, delta);
    printf("==============================================================\n\n");

    for (int ti = 0; ti < nthr; ++ti) {
        int t = threads[ti];
        set_threads(t);
        printf("Threads = %d\n", t);
        printf("%-8s | %-6s | %-10s | %-10s | %-10s | %-10s\n",
               "N", "Calls", "Total(s)", "DSYTRD(s)", "DORGTR(s)", "DSTEQR(s)");
        printf("-----------------------------------------------------------------------\n");

        for (int si = 0; si < nsizes; ++si) {
            int n = sizes[si], lda = n;
            size_t nn = (size_t)n * (size_t)n;

            double *A = (double*)malloc(nn * sizeof(double));
            double *W = (double*)malloc(n * sizeof(double));
            if (!A || !W) { fprintf(stderr, "Alloc fail N=%d\n", n); exit(1); }
            fill_kms(A, n, rho, delta);

            /* Workspace query */
            int info = 0, lwork = -1; double wkopt = 0.0;
            dsyev_(&jobz, &uplo, &n, A, &lda, W, &wkopt, &lwork, &info);
            if (info) { fprintf(stderr, "Query failed N=%d info=%d\n", n, info); exit(2); }
            lwork = (int)wkopt; if (lwork < 1) lwork = 1;
            double *WORK = (double*)malloc((size_t)lwork * sizeof(double));
            if (!WORK) { fprintf(stderr, "WORK alloc fail\n"); exit(3); }

            timers_reset();

            /* Top-level timing */
            struct timespec t0, t1;
            clock_gettime(CLOCK_MONOTONIC, &t0);
            dsyev_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, &info);
            clock_gettime(CLOCK_MONOTONIC, &t1);
            if (info) { fprintf(stderr, "DSYEV failed N=%d info=%d\n", n, info); exit(4); }
            double total_s = elapsed_seconds(t0, t1);

            printf("%-8d | %-6s | %-10.3f | %-10.3f | %-10.3f | %-10.3f\n",
                   n, "-", total_s,
                   G_TIMERS.dsytrd_s, G_TIMERS.dorgtr_s, G_TIMERS.dsteqr_s);

            if (csv)
                fprintf(csv, "%s,%s,%d,%d,%.6f,%.6f,%.6f,%.6f\n",
                        lib_tag, routine, t, n, total_s,
                        G_TIMERS.dsytrd_s, G_TIMERS.dorgtr_s, G_TIMERS.dsteqr_s);

            /* -------- Lightweight file output -------- */
            {
                char dir[128];
                snprintf(dir, sizeof(dir), "%s/run_T%d_N%d", out_routine, t, n);
                ensure_dir(dir);

                char path_w[128], path_v[128];
                snprintf(path_w, sizeof(path_w), "%s/eigenvalues.txt", dir);
                snprintf(path_v, sizeof(path_v), "%s/eigenvectors.txt", dir);

                /* Write first up to OUTPUT_K eigenvalues */
                FILE *fw = fopen(path_w, "w");
                if (fw) {
                    int k = n < OUTPUT_K ? n : OUTPUT_K;
                    for (int i = 0; i < k; ++i)
                        fprintf(fw, "%.12e\n", W[i]);
                    fprintf(fw, "# truncated: total %d eigenvalues\n", n);
                    fclose(fw);
                }

                /* Write first up to OUTPUT_K eigenvector columns and rows (block) */
                FILE *fv = fopen(path_v, "w");
                if (fv) {
                    int k = n < OUTPUT_K ? n : OUTPUT_K;
                    fprintf(fv, "# columns 0..%d, rows 0..%d, full_n=%d\n", k-1, k-1, n);
                    for (int j = 0; j < k; ++j) {
                        fprintf(fv, "# column %d (eigenvalue index %d)\n", j, j);
                        for (int i = 0; i < k; ++i)
                            fprintf(fv, "%.6e\n", A[i + (size_t)j * n]);
                    }
                    fprintf(fv, "# truncated: total matrix %d x %d\n", n, n);
                    fclose(fv);
                }
            }

            free(WORK);
            free(W);
            free(A);
        }
        printf("\n");
    }

    if (csv) fclose(csv);
    printf("Saved CSV: %s\n", csv_path);
    return 0;
}
