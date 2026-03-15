// syevd_benchmark.c
// ------------------------------------------------------------
// Fixed-parameter DSYEVD benchmark with subroutine timings for:
//   DSYTRD (tridiagonalization), DSTEDC (tri eigensolver), DORMTR (back-transform)
// Also prints total DSYEVD time. No other subroutine timing/flamegraph.
// Threads: {1,2,4}  Sizes: {512, 1024, 2048, 4096}  JOBZ='V'.
//
// Build example (OpenBLAS; adjust libs to your env):
//   gcc -O3 -std=c11 -mcpu=native -mtune=native \
//       syevd_benchmark.c -lopenblas -lgfortran -lm -lpthread -ldl \
//       -Wl,--wrap=dsytrd_ -Wl,--wrap=dstedc_ -Wl,--wrap=dormtr_ \
//       -o syevd_benchmark
//
// Run:
//   ./syevd_benchmark
//
// Output:
//   - Console table with Total / DSYTRD / DSTEDC / DORMTR per (threads, N)
//   - ../output/syevd_benchmark.csv
//   - ../output/run_T<threads>_N<N>/{eigenvalues.txt,eigenvectors.txt}
//     (lightweight: first 5 eigenvalues and first 5 eigenvector columns only)
// ------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>

/* -------- LAPACK symbols (Fortran) -------- */
extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA, double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

/* --- We'll wrap only these three --- */
/* Real (library) entry points — declare for the linker */
extern void __real_dsytrd_(char *UPLO, int *N, double *A, int *LDA,
                           double *D, double *E, double *TAU,
                           double *WORK, int *LWORK, int *INFO);

extern void __real_dstedc_(char *COMPZ, int *N, double *D, double *E,
                           double *Z, int *LDZ, double *WORK, int *LWORK,
                           int *IWORK, int *LIWORK, int *INFO);

extern void __real_dormtr_(char *SIDE, char *UPLO, char *TRANS,
                           int *M, int *N, double *A, int *LDA, double *TAU,
                           double *C, int *LDC, double *WORK, int *LWORK, int *INFO);

/* Optional thread APIs */
__attribute__((weak)) void openblas_set_num_threads(int);
__attribute__((weak)) void mkl_set_num_threads(int);

/* ---------- Tiny timing registry (only 3 names) ---------- */
typedef struct {
    double dsytrd_s, dstedc_s, dormtr_s;
    unsigned long long dsytrd_calls, dstedc_calls, dormtr_calls;
} sub_timers_t;

static sub_timers_t G_TIMERS;

#define WARMUP_RUNS 1
#define MAX_MEASURE_RUNS 5

static inline double now_s(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}
static inline void timers_reset(void) {
    memset(&G_TIMERS, 0, sizeof(G_TIMERS));
}

static int cmp_double(const void *a, const void *b) {
    const double da = *(const double *)a;
    const double db = *(const double *)b;
    return (da > db) - (da < db);
}

static int measured_repeats(int n) {
    return (n >= 4096) ? 3 : 5;
}

static double stats_mean(const double *xs, int n) {
    double acc = 0.0;
    for (int i = 0; i < n; ++i) acc += xs[i];
    return acc / (double)n;
}

static double stats_stddev(const double *xs, int n) {
    if (n <= 1) return 0.0;
    double mean = stats_mean(xs, n);
    double acc = 0.0;
    for (int i = 0; i < n; ++i) {
        double d = xs[i] - mean;
        acc += d * d;
    }
    return sqrt(acc / (double)(n - 1));
}

static double stats_min(const double *xs, int n) {
    double v = xs[0];
    for (int i = 1; i < n; ++i) if (xs[i] < v) v = xs[i];
    return v;
}

static double stats_max(const double *xs, int n) {
    double v = xs[0];
    for (int i = 1; i < n; ++i) if (xs[i] > v) v = xs[i];
    return v;
}

static double stats_median(const double *xs, int n) {
    double tmp[MAX_MEASURE_RUNS];
    memcpy(tmp, xs, (size_t)n * sizeof(double));
    qsort(tmp, (size_t)n, sizeof(double), cmp_double);
    if ((n & 1) != 0) return tmp[n / 2];
    return 0.5 * (tmp[n / 2 - 1] + tmp[n / 2]);
}

/* --------------- Our wrappers (timed) ---------------- */
void __wrap_dsytrd_(char *UPLO, int *N, double *A, int *LDA,
                    double *D, double *E, double *TAU,
                    double *WORK, int *LWORK, int *INFO)
{
    double t0 = now_s();
    __real_dsytrd_(UPLO, N, A, LDA, D, E, TAU, WORK, LWORK, INFO);
    G_TIMERS.dsytrd_s += (now_s() - t0);
    G_TIMERS.dsytrd_calls++;
}

void __wrap_dstedc_(char *COMPZ, int *N, double *D, double *E,
                    double *Z, int *LDZ, double *WORK, int *LWORK,
                    int *IWORK, int *LIWORK, int *INFO)
{
    double t0 = now_s();
    __real_dstedc_(COMPZ, N, D, E, Z, LDZ, WORK, LWORK, IWORK, LIWORK, INFO);
    G_TIMERS.dstedc_s += (now_s() - t0);
    G_TIMERS.dstedc_calls++;
}

void __wrap_dormtr_(char *SIDE, char *UPLO, char *TRANS,
                    int *M, int *N, double *A, int *LDA, double *TAU,
                    double *C, int *LDC, double *WORK, int *LWORK, int *INFO)
{
    double t0 = now_s();
    __real_dormtr_(SIDE, UPLO, TRANS, M, N, A, LDA, TAU, C, LDC, WORK, LWORK, INFO);
    G_TIMERS.dormtr_s += (now_s() - t0);
    G_TIMERS.dormtr_calls++;
}

/* ---------- Utilities ---------- */
static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) { perror("mkdir"); exit(5); }
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

/* SPD KMS: A_ij = rho^{|i-j|} + delta*(i==j) */
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

/* ---------- Main benchmark ---------- */
int main(void) {
    const char jobz = 'V', uplo = 'U';
    const double rho = 0.95, delta = 0.0;
    const int sizes[]   = {512, 1024, 2048, 4096};
    const int nsizes    = sizeof(sizes) / sizeof(sizes[0]);
    const int threads[] = {1, 2, 4};
    const int nthr      = sizeof(threads) / sizeof(threads[0]);

    ensure_dir("../output");
    FILE *csv = fopen("../output/syevd_benchmark.csv", "w");
    if (csv) {
        fprintf(csv,
                "threads,N,reported_stat,repeats,warmup_runs,"
                "total_s,dsytrd_s,dstedc_s,dormtr_s,"
                "total_mean_s,total_std_s,total_min_s,total_max_s,"
                "dsytrd_mean_s,dsytrd_std_s,dstedc_mean_s,dstedc_std_s,dormtr_mean_s,dormtr_std_s\n");
    }

    printf("==============================================================\n");
    printf(" DSYEVD Benchmark (JOBZ='V') — Total & 3 subroutines\n");
    printf(" rho=%.2f, delta=%.2f\n", rho, delta);
    printf("==============================================================\n\n");

    for (int ti = 0; ti < nthr; ++ti) {
        int t = threads[ti];
        set_threads(t);
        printf("Threads = %d\n", t);
        printf("%-8s | %-6s | %-10s | %-10s | %-10s | %-10s\n",
               "N", "Calls", "Total(s)", "DSYTRD(s)", "DSTEDC(s)", "DORMTR(s)");
        printf("-----------------------------------------------------------------------\n");

        for (int si = 0; si < nsizes; ++si) {
            int n = sizes[si], lda = n;
            size_t nn = (size_t)n * (size_t)n;
            int reps = measured_repeats(n);
            double total_runs[MAX_MEASURE_RUNS];
            double dsytrd_runs[MAX_MEASURE_RUNS];
            double dstedc_runs[MAX_MEASURE_RUNS];
            double dormtr_runs[MAX_MEASURE_RUNS];

            double *A = (double*)malloc(nn * sizeof(double));
            double *W = (double*)malloc(n * sizeof(double));
            if (!A || !W) { fprintf(stderr, "Alloc fail N=%d\n", n); exit(1); }

            /* Workspace query */
            int info=0, lwork=-1, liwork=-1, iwkopt=0; double wkopt=0.0;
            fill_kms(A, n, rho, delta);
            dsyevd_(&jobz, &uplo, &n, A, &lda, W, &wkopt, &lwork, &iwkopt, &liwork, &info);
            if (info) { fprintf(stderr,"Query failed N=%d info=%d\n", n, info); exit(2); }
            lwork = (int)wkopt; if (lwork<1) lwork=1;
            liwork = iwkopt;    if (liwork<1) liwork=1;
            double *WORK=(double*)malloc((size_t)lwork*sizeof(double));
            int *IWORK=(int*)malloc((size_t)liwork*sizeof(int));
            if(!WORK||!IWORK){ fprintf(stderr,"WORK alloc fail\n"); exit(3); }

            for (int warm = 0; warm < WARMUP_RUNS; ++warm) {
                fill_kms(A, n, rho, delta);
                timers_reset();
                dsyevd_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, IWORK, &liwork, &info);
                if (info) { fprintf(stderr,"DSYEVD warm-up failed N=%d info=%d\n", n, info); exit(4); }
            }

            for (int rep = 0; rep < reps; ++rep) {
                struct timespec t0, t1;
                fill_kms(A, n, rho, delta);
                timers_reset();
                clock_gettime(CLOCK_MONOTONIC, &t0);
                dsyevd_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, IWORK, &liwork, &info);
                clock_gettime(CLOCK_MONOTONIC, &t1);
                if (info) { fprintf(stderr,"DSYEVD failed N=%d info=%d\n", n, info); exit(4); }
                total_runs[rep] = elapsed_seconds(t0, t1);
                dsytrd_runs[rep] = G_TIMERS.dsytrd_s;
                dstedc_runs[rep] = G_TIMERS.dstedc_s;
                dormtr_runs[rep] = G_TIMERS.dormtr_s;
            }

            {
                double total_s = stats_median(total_runs, reps);
                double dsytrd_s = stats_median(dsytrd_runs, reps);
                double dstedc_s = stats_median(dstedc_runs, reps);
                double dormtr_s = stats_median(dormtr_runs, reps);

                printf("%-8d | med[%d] | %-10.3f | %-10.3f | %-10.3f | %-10.3f\n",
                       n, reps, total_s, dsytrd_s, dstedc_s, dormtr_s);

                if (csv) {
                    fprintf(csv,
                            "%d,%d,median,%d,%d,"
                            "%.6f,%.6f,%.6f,%.6f,"
                            "%.6f,%.6f,%.6f,%.6f,"
                            "%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n",
                            t, n, reps, WARMUP_RUNS,
                            total_s, dsytrd_s, dstedc_s, dormtr_s,
                            stats_mean(total_runs, reps), stats_stddev(total_runs, reps),
                            stats_min(total_runs, reps), stats_max(total_runs, reps),
                            stats_mean(dsytrd_runs, reps), stats_stddev(dsytrd_runs, reps),
                            stats_mean(dstedc_runs, reps), stats_stddev(dstedc_runs, reps),
                            stats_mean(dormtr_runs, reps), stats_stddev(dormtr_runs, reps));
                }
            }

            /* -------- Lightweight file output: first 5 eigenvalues and first 5 full columns -------- */
            {
                char dir[128];
                snprintf(dir, sizeof(dir), "../output/run_T%d_N%d", t, n);
                ensure_dir(dir);

                char path_w[128], path_v[128];
                snprintf(path_w, sizeof(path_w), "%s/eigenvalues.txt", dir);
                snprintf(path_v, sizeof(path_v), "%s/eigenvectors.txt", dir);

                /* Write first up to 5 eigenvalues (ascending order) */
                FILE *fw = fopen(path_w, "w");
                if (fw) {
                    int k = n < 5 ? n : 5;
                    for (int i = 0; i < k; ++i)
                        fprintf(fw, "%.12e\n", W[i]);
                    fprintf(fw, "# truncated: total %d eigenvalues\n", n);
                    fclose(fw);
                }

                /* Write first up to 5 eigenvector columns (each is length n) */
                FILE *fv = fopen(path_v, "w");
                if (fv) {
                    int k = n < 5 ? n : 5;
                    fprintf(fv, "# columns 0..%d, each of length n=%d\n", k-1, n);
                    for (int j = 0; j < k; ++j) {
                        fprintf(fv, "# column %d (eigenvalue index %d)\n", j, j);
                        for (int i = 0; i < n; ++i)
                            fprintf(fv, "%.6e\n", A[i + (size_t)j * n]);
                    }
                    fprintf(fv, "# truncated: total matrix %d x %d\n", n, n);
                    fclose(fv);
                }
            }

            free(IWORK); free(WORK); free(W); free(A);
        }
        printf("\n");
    }

    if (csv) fclose(csv);
    printf("Saved CSV: ../output/syevd_benchmark.csv\n");
    return 0;
}
