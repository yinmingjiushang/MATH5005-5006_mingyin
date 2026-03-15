#ifndef EXPERIMENT_4_6_3_HW_COMMON_H
#define EXPERIMENT_4_6_3_HW_COMMON_H

#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
    int n;
    int repeat;
    double rho;
    double delta;
} run_config_t;

extern void dsytrd_(const char *uplo, const int *n, double *a, const int *lda,
                    double *d, double *e, double *tau,
                    double *work, const int *lwork, int *info);

__attribute__((weak)) void openblas_set_num_threads(int);
__attribute__((weak)) void mkl_set_num_threads(int);

static inline void die_usage(const char *prog, const char *desc)
{
    fprintf(stderr,
            "Usage: %s [--n N] [--repeat R] [--rho RHO] [--delta DELTA]\n"
            "  %s\n",
            prog, desc);
    exit(2);
}

static inline run_config_t parse_run_config(int argc, char **argv,
                                            const char *prog, const char *desc)
{
    run_config_t cfg;
    cfg.n = 512;
    cfg.repeat = 1;
    cfg.rho = 0.95;
    cfg.delta = 0.0;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--n") == 0) {
            if (i + 1 >= argc) die_usage(prog, desc);
            cfg.n = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--repeat") == 0) {
            if (i + 1 >= argc) die_usage(prog, desc);
            cfg.repeat = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--rho") == 0) {
            if (i + 1 >= argc) die_usage(prog, desc);
            cfg.rho = atof(argv[++i]);
        } else if (strcmp(argv[i], "--delta") == 0) {
            if (i + 1 >= argc) die_usage(prog, desc);
            cfg.delta = atof(argv[++i]);
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            die_usage(prog, desc);
        } else {
            fprintf(stderr, "Unknown argument: %s\n", argv[i]);
            die_usage(prog, desc);
        }
    }

    if (cfg.n <= 0 || cfg.repeat <= 0) {
        fprintf(stderr, "N and repeat must be positive.\n");
        exit(2);
    }
    if (!(cfg.rho > -1.0 && cfg.rho < 1.0)) {
        fprintf(stderr, "rho must satisfy -1 < rho < 1.\n");
        exit(2);
    }
    if (cfg.delta < 0.0) {
        fprintf(stderr, "delta must be non-negative.\n");
        exit(2);
    }
    return cfg;
}

static inline void *xmalloc(size_t bytes)
{
    void *p = malloc(bytes);
    if (!p) {
        fprintf(stderr, "malloc failed for %zu bytes\n", bytes);
        exit(3);
    }
    return p;
}

static inline void *xcalloc(size_t count, size_t size)
{
    void *p = calloc(count, size);
    if (!p) {
        fprintf(stderr, "calloc failed for %zu x %zu bytes\n", count, size);
        exit(3);
    }
    return p;
}

static inline double wall_now_s(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + 1e-9 * (double)t.tv_nsec;
}

static inline void set_single_thread(void)
{
    setenv("OMP_NUM_THREADS", "1", 1);
    setenv("OPENBLAS_NUM_THREADS", "1", 1);
    setenv("ARMPL_NUM_THREADS", "1", 1);
    if (openblas_set_num_threads) openblas_set_num_threads(1);
    if (mkl_set_num_threads) mkl_set_num_threads(1);
}

static inline void fill_kms(double *a, int n, double rho, double delta)
{
    double arho = fabs(rho);
    double *powers = (double *)xmalloc((size_t)n * sizeof(double));
    powers[0] = 1.0;
    for (int k = 1; k < n; ++k) {
        powers[k] = powers[k - 1] * arho;
    }
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            double v = powers[j - i];
            if (i == j) v += delta;
            a[i + (size_t)j * (size_t)n] = v;
            a[j + (size_t)i * (size_t)n] = v;
        }
    }
    free(powers);
}

static inline void make_identity(double *z, int n)
{
    memset(z, 0, (size_t)n * (size_t)n * sizeof(double));
    for (int i = 0; i < n; ++i) {
        z[i + (size_t)i * (size_t)n] = 1.0;
    }
}

static inline void reduce_kms_to_tridiagonal(int n, double rho, double delta,
                                             double *d, double *e)
{
    const char uplo = 'U';
    int lda = n;
    int info = 0;
    int lwork = -1;
    double wkopt = 0.0;

    double *a = (double *)xmalloc((size_t)n * (size_t)n * sizeof(double));
    double *tau = (double *)xmalloc((size_t)(n > 1 ? (n - 1) : 1) * sizeof(double));

    fill_kms(a, n, rho, delta);
    dsytrd_(&uplo, &n, a, &lda, d, e, tau, &wkopt, &lwork, &info);
    if (info != 0) {
        fprintf(stderr, "dsytrd workspace query failed: info=%d\n", info);
        exit(4);
    }

    lwork = (int)wkopt;
    if (lwork < 1) lwork = 1;
    double *work = (double *)xmalloc((size_t)lwork * sizeof(double));

    fill_kms(a, n, rho, delta);
    dsytrd_(&uplo, &n, a, &lda, d, e, tau, work, &lwork, &info);
    if (info != 0) {
        fprintf(stderr, "dsytrd failed while preparing tri-diagonal input: info=%d\n", info);
        exit(4);
    }

    free(work);
    free(tau);
    free(a);
}

static inline double checksum_vector(const double *x, int n)
{
    double sum = 0.0;
    for (int i = 0; i < n; ++i) {
        sum += x[i];
    }
    return sum;
}

#endif
