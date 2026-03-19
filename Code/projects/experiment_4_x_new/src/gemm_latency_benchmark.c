#define _POSIX_C_SOURCE 200112L

#include <cblas.h>
#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>

#ifndef LIB_TAG
#define LIB_TAG "unknown"
#endif

#ifndef OUTPUT_ROOT
#define OUTPUT_ROOT "../output"
#endif

#ifndef GEMM_LAYOUT
#define GEMM_LAYOUT CblasColMajor
#endif

__attribute__((weak)) void openblas_set_num_threads(int);

static double now_s(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec * 1e-9;
}

static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        perror("mkdir");
        exit(2);
    }
}

static int parse_int_list(const char *s, int *out, int max_n) {
    char *copy = NULL;
    char *tok = NULL;
    char *save = NULL;
    int n = 0;

    if (!s || !*s) {
        return 0;
    }

    size_t len = strlen(s);
    copy = (char *)malloc(len + 1);
    if (!copy) {
        return 0;
    }
    memcpy(copy, s, len + 1);

    tok = strtok_r(copy, ",", &save);
    while (tok && n < max_n) {
        while (*tok == ' ' || *tok == '\t') {
            tok++;
        }
        int v = atoi(tok);
        if (v > 0) {
            out[n++] = v;
        }
        tok = strtok_r(NULL, ",", &save);
    }

    free(copy);
    return n;
}

static int get_env_int(const char *name, int default_v) {
    const char *s = getenv(name);
    if (!s || !*s) {
        return default_v;
    }
    int v = atoi(s);
    return (v > 0) ? v : default_v;
}

static void set_threads(int t) {
    char buf[32];
    snprintf(buf, sizeof(buf), "%d", t);
    setenv("OMP_NUM_THREADS", buf, 1);
    setenv("OPENBLAS_NUM_THREADS", buf, 1);
    if (openblas_set_num_threads) {
        openblas_set_num_threads(t);
    }
}

static void fill_matrix(double *x, int n, double seed) {
    size_t nn = (size_t)n * (size_t)n;
    for (size_t i = 0; i < nn; ++i) {
        double v = seed + (double)((i % 97) - 48) * 1e-3;
        x[i] = v;
    }
}

static double checksum_head(const double *x, int n) {
    int k = n < 16 ? n : 16;
    double s = 0.0;
    for (int j = 0; j < k; ++j) {
        for (int i = 0; i < k; ++i) {
            s += x[i + (size_t)j * n] * (1.0 + 1e-3 * (double)(i + j));
        }
    }
    return s;
}

int main(void) {
    const char *sizes_env = getenv("GEMM_SIZES");
    const char *thr_env = getenv("GEMM_THREADS");

    int sizes[64];
    int threads[16];
    int ns = parse_int_list(sizes_env, sizes, (int)(sizeof(sizes) / sizeof(sizes[0])));
    int nt = parse_int_list(thr_env, threads, (int)(sizeof(threads) / sizeof(threads[0])));

    if (ns == 0) {
        int defaults[] = {256, 512, 1024, 1536, 2048};
        ns = (int)(sizeof(defaults) / sizeof(defaults[0]));
        for (int i = 0; i < ns; ++i) {
            sizes[i] = defaults[i];
        }
    }
    if (nt == 0) {
        threads[0] = 1;
        nt = 1;
    }

    int warmup = get_env_int("GEMM_WARMUP", 2);
    int repeats = get_env_int("GEMM_REPEATS", 8);

    const double alpha = 1.0;
    const double beta = 0.0;

    char out_root[256];
    char out_lib[256];
    char out_gemm[256];
    char csv_path[256];

    snprintf(out_root, sizeof(out_root), "%s", OUTPUT_ROOT);
    snprintf(out_lib, sizeof(out_lib), "%s/%s", out_root, LIB_TAG);
    snprintf(out_gemm, sizeof(out_gemm), "%s/gemm", out_lib);
    ensure_dir(out_root);
    ensure_dir(out_lib);
    ensure_dir(out_gemm);

    snprintf(csv_path, sizeof(csv_path), "%s/gemm_latency.csv", out_gemm);
    FILE *csv = fopen(csv_path, "w");
    if (!csv) {
        perror("fopen csv");
        return 3;
    }

    fprintf(csv, "lib,threads,n,warmup,repeats,avg_s,min_s,max_s,gflops_avg,checksum\n");

    printf("===============================================================\n");
    printf("GEMM latency benchmark (%s)\n", LIB_TAG);
    printf("layout=ColMajor, op(A)=N, op(B)=N, C=A*B\n");
    printf("warmup=%d repeats=%d\n", warmup, repeats);
    printf("===============================================================\n");

    for (int ti = 0; ti < nt; ++ti) {
        int t = threads[ti];
        set_threads(t);
        printf("\nThreads=%d\n", t);
        printf("%-8s %-10s %-10s %-10s %-12s\n", "N", "avg(s)", "min(s)", "max(s)", "GFLOPS(avg)");

        for (int si = 0; si < ns; ++si) {
            int n = sizes[si];
            size_t nn = (size_t)n * (size_t)n;
            size_t bytes = nn * sizeof(double);

            double *A = (double *)malloc(bytes);
            double *B = (double *)malloc(bytes);
            double *C = (double *)malloc(bytes);
            if (!A || !B || !C) {
                fprintf(stderr, "allocation failed for N=%d\n", n);
                free(A);
                free(B);
                free(C);
                fclose(csv);
                return 4;
            }

            fill_matrix(A, n, 0.5);
            fill_matrix(B, n, -0.25);
            memset(C, 0, bytes);

            for (int w = 0; w < warmup; ++w) {
                cblas_dgemm(GEMM_LAYOUT, CblasNoTrans, CblasNoTrans,
                            n, n, n, alpha, A, n, B, n, beta, C, n);
            }

            double sum_s = 0.0;
            double min_s = 1e100;
            double max_s = 0.0;

            for (int r = 0; r < repeats; ++r) {
                double t0 = now_s();
                cblas_dgemm(GEMM_LAYOUT, CblasNoTrans, CblasNoTrans,
                            n, n, n, alpha, A, n, B, n, beta, C, n);
                double dt = now_s() - t0;

                sum_s += dt;
                if (dt < min_s) min_s = dt;
                if (dt > max_s) max_s = dt;
            }

            double avg_s = sum_s / (double)repeats;
            double gflops = (2.0 * (double)n * (double)n * (double)n) / (avg_s * 1e9);
            double chk = checksum_head(C, n);

            printf("%-8d %-10.6f %-10.6f %-10.6f %-12.2f\n", n, avg_s, min_s, max_s, gflops);
            fprintf(csv, "%s,%d,%d,%d,%d,%.9f,%.9f,%.9f,%.6f,%.10e\n",
                    LIB_TAG, t, n, warmup, repeats, avg_s, min_s, max_s, gflops, chk);

            free(A);
            free(B);
            free(C);
        }
    }

    fclose(csv);
    printf("\nSaved CSV: %s\n", csv_path);
    return 0;
}
