// eig_bench.c
// ------------------------------------------------------------
// Compare total runtime of DGEEV vs DSYEV vs DSYEVD
// Default: N = 8000, threads = {1,2,4,8}. No subroutine timing.
// DSYEV/DSYEVD: JOBZ='V', UPLO='U'; DGEEV: JOBVL='N', JOBVR='V'.
// Matrix: symmetric SPD KMS (rho=0.95, delta=0.0), column-major.
//
// Build (OpenBLAS; adjust include/lib prefixes if needed):
//   gcc -O3 -std=c11 -mcpu=native -mtune=native eig_bench.c \
//       -I/path/to/openblas/include -L/path/to/openblas/lib \
//       -Wl,-rpath,/path/to/openblas/lib \
//       -lopenblas -lgfortran -lm -lpthread -ldl -o eig_bench
//
// Run:
//   ./eig_bench
// Optional overrides:
//   EIG_N=4096 ./eig_bench          # change problem size
//   EIG_THREADS=1,4 ./eig_bench     # comma list of threads (e.g., "1,2,4")
// ------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <math.h>
#include <sys/stat.h>

#ifdef __has_include
#  if __has_include(<openblas_config.h>)
#    include <openblas_config.h>
#  endif
#endif

#ifdef OPENBLAS_USE64BITINT
typedef long long blasint;
#else
typedef int blasint;
#endif

extern void dgeev_(char *JOBVL, char *JOBVR, blasint *N,
                   double *A, blasint *LDA,
                   double *WR, double *WI,
                   double *VL, blasint *LDVL,
                   double *VR, blasint *LDVR,
                   double *WORK, blasint *LWORK,
                   blasint *INFO);

extern void dsyev_(char *JOBZ, char *UPLO, blasint *N,
                   double *A, blasint *LDA, double *W,
                   double *WORK, blasint *LWORK, blasint *INFO);

extern void dsyevd_(char *JOBZ, char *UPLO, blasint *N,
                    double *A, blasint *LDA, double *W,
                    double *WORK, blasint *LWORK,
                    blasint *IWORK, blasint *LIWORK, blasint *INFO);

__attribute__((weak)) void openblas_set_num_threads(int);
__attribute__((weak)) void mkl_set_num_threads(int);

static inline double now_s(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}
static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) { perror("mkdir"); exit(10); }
}
static void set_threads_int(int t) {
    char buf[16]; snprintf(buf, sizeof(buf), "%d", t);
    setenv("OMP_NUM_THREADS", buf, 1);
    setenv("OPENBLAS_NUM_THREADS", buf, 1);
    setenv("ARMPL_NUM_THREADS", buf, 1);
    if (openblas_set_num_threads) openblas_set_num_threads(t);
    if (mkl_set_num_threads)      mkl_set_num_threads(t);
}
static void copy_mat(double *dst, const double *src, size_t n) {
    memcpy(dst, src, n * n * sizeof(double));
}

static void fill_kms(double *A, blasint n, double rho, double delta) {
    if (!(rho > -1.0 && rho < 1.0)) rho = 0.95;
    if (delta < 0.0) delta = 0.0;
    double arho = fabs(rho);
    double *rp = (double*)malloc((size_t)n * sizeof(double));
    if (!rp) { fprintf(stderr, "malloc failed (rp)\n"); exit(11); }
    rp[0] = 1.0;
    for (blasint k = 1; k < n; ++k) rp[k] = rp[k-1] * arho;
    for (blasint j = 0; j < n; ++j) {
        for (blasint i = 0; i <= j; ++i) {
            double v = rp[j - i];
            if (i == j) v += delta;
            A[(size_t)i + (size_t)j * (size_t)n] = v;
            A[(size_t)j + (size_t)i * (size_t)n] = v;
        }
    }
    free(rp);
}

static double run_dsyev(blasint n, const double *Aref) {
    blasint lda = n, info = 0;
    size_t nn = (size_t)n * (size_t)n;

    double *A = (double*)malloc(nn * sizeof(double));
    double *W = (double*)malloc((size_t)n * sizeof(double));
    if (!A || !W) { fprintf(stderr, "alloc fail DSYEV\n"); exit(20); }
    copy_mat(A, Aref, (size_t)n);

    char jobz = 'V', uplo = 'U';
    blasint lwork = -1; double wkopt = 0.0;
    dsyev_(&jobz, &uplo, &n, A, &lda, W, &wkopt, &lwork, &info);
    if (info) { fprintf(stderr, "DSYEV workspace query failed (info=%d)\n", (int)info); exit(21); }
    lwork = (blasint)wkopt; if (lwork < 1) lwork = 1;
    double *WORK = (double*)malloc((size_t)lwork * sizeof(double));
    if (!WORK) { fprintf(stderr, "alloc WORK DSYEV\n"); exit(22); }

    double t0 = now_s();
    dsyev_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, &info);
    double t1 = now_s();
    if (info) { fprintf(stderr, "DSYEV failed (info=%d)\n", (int)info); exit(23); }

    free(WORK); free(W); free(A);
    return t1 - t0;
}

static double run_dsyevd(blasint n, const double *Aref) {
    blasint lda = n, info = 0;
    size_t nn = (size_t)n * (size_t)n;

    double *A = (double*)malloc(nn * sizeof(double));
    double *W = (double*)malloc((size_t)n * sizeof(double));
    if (!A || !W) { fprintf(stderr, "alloc fail DSYEVD\n"); exit(30); }
    copy_mat(A, Aref, (size_t)n);

    char jobz = 'V', uplo = 'U';
    blasint lwork = -1, liwork = -1, iwkopt = 0; double wkopt = 0.0;
    dsyevd_(&jobz, &uplo, &n, A, &lda, W, &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info) { fprintf(stderr, "DSYEVD workspace query failed (info=%d)\n", (int)info); exit(31); }
    lwork  = (blasint)wkopt;
    liwork = iwkopt;
    if (lwork  < 1) lwork  = 1;
    if (liwork < 1) liwork = 1;

    double *WORK   = (double*)malloc((size_t)lwork  * sizeof(double));
    blasint *IWORK = (blasint*)malloc((size_t)liwork * sizeof(blasint));
    if (!WORK || !IWORK) { fprintf(stderr, "alloc WORK/IWORK DSYEVD\n"); exit(32); }

    double t0 = now_s();
    dsyevd_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, IWORK, &liwork, &info);
    double t1 = now_s();
    if (info) { fprintf(stderr, "DSYEVD failed (info=%d)\n", (int)info); exit(33); }

    free(IWORK); free(WORK); free(W); free(A);
    return t1 - t0;
}

static double run_dgeev(blasint n, const double *Aref) {
    blasint lda = n, info = 0;
    size_t nn = (size_t)n * (size_t)n;

    double *A  = (double*)malloc(nn * sizeof(double));
    double *WR = (double*)malloc((size_t)n * sizeof(double));
    double *WI = (double*)malloc((size_t)n * sizeof(double));
    double *VR = (double*)malloc(nn * sizeof(double));
    if (!A || !WR || !WI || !VR) { fprintf(stderr, "alloc fail DGEEV\n"); exit(40); }
    copy_mat(A, Aref, (size_t)n);

    char jobvl = 'N', jobvr = 'V';
    blasint ldvr = n, ldvl = 1;

    blasint lwork = -1; double wkopt = 0.0;
    dgeev_(&jobvl, &jobvr, &n, A, &lda, WR, WI, NULL, &ldvl, VR, &ldvr, &wkopt, &lwork, &info);
    if (info) { fprintf(stderr, "DGEEV workspace query failed (info=%d)\n", (int)info); exit(41); }
    lwork = (blasint)wkopt; if (lwork < 1) lwork = 1;
    double *WORK = (double*)malloc((size_t)lwork * sizeof(double));
    if (!WORK) { fprintf(stderr, "alloc WORK DGEEV\n"); exit(42); }

    double t0 = now_s();
    dgeev_(&jobvl, &jobvr, &n, A, &lda, WR, WI, NULL, &ldvl, VR, &ldvr, WORK, &lwork, &info);
    double t1 = now_s();
    if (info) { fprintf(stderr, "DGEEV failed (info=%d)\n", (int)info); exit(43); }

    free(WORK); free(VR); free(WI); free(WR); free(A);
    return t1 - t0;
}

static int parse_threads(int *out, int maxn) {
    const char *env = getenv("EIG_THREADS");
    if (!env || !*env) {
        if (maxn >= 4) { out[0]=1; out[1]=2; out[2]=4; out[3]=8; return 4; }
        return 0;
    }
    int n = 0, v = 0, have = 0;
    for (const char *p = env; ; ++p) {
        if (*p >= '0' && *p <= '9') { v = v*10 + (*p - '0'); have = 1; }
        if (*p == ',' || *p == '\0') {
            if (have && n < maxn) out[n++] = v;
            v = 0; have = 0;
            if (*p == '\0') break;
        }
    }
    return n;
}

int main(void) {
    blasint N = 8192;
//    blasint N = 4096;
    const char *envN = getenv("EIG_N");
    if (envN && *envN) {
        long long tmp = atoll(envN);
        if (tmp > 0 && tmp < (1LL<<30)) N = (blasint)tmp;
    }

    int threads[8]; int nthr = parse_threads(threads, 8);
    if (nthr == 0) { threads[0]=1; threads[1]=2; threads[2]=4; threads[3]=8; nthr=4; }

    const double rho = 0.95, delta = 0.0;

    ensure_dir("../output");
    FILE *csv = fopen("../output/eig_bench.csv", "w");
    if (csv) fprintf(csv, "threads,solver,time_s\n");

    size_t nn = (size_t)N * (size_t)N;
    double *Aref = (double*)malloc(nn * sizeof(double));
    if (!Aref) { fprintf(stderr, "alloc fail Aref (N=%d)\n", (int)N); return 1; }
    fill_kms(Aref, N, rho, delta);

    printf("==============================================================\n");
    printf(" Eigen Bench — DGEEV vs DSYEV vs DSYEVD (N=%d, rho=%.2f, delta=%.2f)\n", (int)N, rho, delta);
    printf(" Threads set = {");
    for (int i=0;i<nthr;i++){ if(i)printf(","); printf("%d", threads[i]); }
    printf("}; Times in seconds (wall time)\n");
    printf("==============================================================\n\n");

    printf("%-8s | %-10s | %-10s | %-10s\n", "Threads", "DGEEV", "DSYEV", "DSYEVD");
    printf("-----------------------------------------------------------\n");

    for (int ti = 0; ti < nthr; ++ti) {
        int t = threads[ti];
        set_threads_int(t);

        double t_syev   = run_dsyev(N, Aref);
        double t_dsyevd = run_dsyevd(N, Aref);
        double t_dgeev  = run_dgeev(N, Aref);

        printf("%-8d | %-10.3f | %-10.3f | %-10.3f\n",
               t, t_dgeev, t_syev, t_dsyevd);

        if (csv) {
            fprintf(csv, "%d,DGEEV,%.6f\n", t, t_dgeev);
            fprintf(csv, "%d,DSYEV,%.6f\n", t, t_syev);
            fprintf(csv, "%d,DSYEVD,%.6f\n", t, t_dsyevd);
        }
    }

    if (csv) fclose(csv);
    free(Aref);
    printf("\nSaved CSV: ../output/eig_bench.csv\n");
    return 0;
}
