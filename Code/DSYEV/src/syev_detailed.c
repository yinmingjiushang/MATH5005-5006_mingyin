// syev_detailed.c — Build a KMS SPD matrix A, then call DSYEV('V','U')
// while wrappers time subroutines down the call path.
// Uses your wrap_timers_1.c to print a sorted summary at process exit.

#define _POSIX_C_SOURCE 200112L

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>

/* --------- Fortran LAPACK symbol (vendor-agnostic) --------- */
extern void dsyev_(const char *JOBZ, const char *UPLO, const int *N,
                   double *A, const int *LDA, double *W,
                   double *WORK, const int *LWORK, int *INFO);

/* (Optional, harmless if not present) */
__attribute__((weak)) extern char* openblas_get_config(void);
__attribute__((weak)) extern char* openblas_get_corename(void);

/* --------- Utilities --------- */
static void ensure_dir(const char *path){
    if (mkdir(path, 0777) != 0 && errno != EEXIST) { perror("mkdir"); exit(5); }
}

static double elapsed_seconds(struct timespec a, struct timespec b){
    return (b.tv_sec - a.tv_sec) + (b.tv_nsec - a.tv_nsec) / 1e9;
}

/* SPD KMS: A_ij = rho^{|i-j|} + delta*(i==j) */
static void fill_kms(double *A, int n, double rho, double delta){
    if (!(rho > -1.0 && rho < 1.0)) rho = 0.95;
    if (delta < 0.0) delta = 0.0;
    double arho = fabs(rho);
    double *rp = (double*)malloc((size_t)n * sizeof(double));
    if (!rp) { fprintf(stderr, "malloc failed\n"); exit(6); }
    rp[0] = 1.0;
    for (int k = 1; k < n; ++k) rp[k] = rp[k-1] * arho;
    for (int j = 0; j < n; ++j){
        for (int i = 0; i <= j; ++i){
            double v = rp[j-i]; if (i==j) v += delta;
            A[i + (size_t)j * n] = v;   // upper
            A[j + (size_t)i * n] = v;   // mirror
        }
    }
    free(rp);
}

int main(void)
{
    /* ---- Config (single run; use separate benchmark for sweeps) ---- */
    const int   n     = 4096;
    const int   lda   = n;
    const char  uplo  = 'U';   // keep 'U' consistently
    const char  jobz  = 'V';   // 'V' for eigenvectors, 'N' for values only
    const double rho   = 0.95; // KMS difficulty
    const double delta = 0.0;  // small positive shift if desired

    if (openblas_get_config && openblas_get_corename){
        printf("OpenBLAS config: %s\n", openblas_get_config());
        printf("OpenBLAS core  : %s\n", openblas_get_corename());
    }

    ensure_dir("../output");

    /* ---- Allocate ---- */
    double *A = (double*)malloc((size_t)n * (size_t)n * sizeof(double));
    double *W = (double*)malloc((size_t)n * sizeof(double));
    if (!A || !W){
        fprintf(stderr, "Allocation failed.\n");
        free(W); free(A);
        return 1;
    }

    /* ---- Build dense SPD KMS A ---- */
    fill_kms(A, n, rho, delta);

    /* ---- Workspace query ---- */
    int info = 0;
    int lwork = -1;
    double wkopt = 0.0;

    dsyev_(&jobz, &uplo, &n, A, &lda, W, &wkopt, &lwork, &info);
    if (info != 0) { fprintf(stderr, "DSYEV workspace query failed, info=%d\n", info); goto CLEANUP_ERR; }

    lwork  = (int)wkopt; if (lwork < 1) lwork = 1;
    double *WORK = (double*)malloc((size_t)lwork * sizeof(double));
    if (!WORK){ fprintf(stderr, "Allocation failed (WORK)\n"); free(WORK); goto CLEANUP_ERR; }

    /* ---- Call DSYEV & top-level time ---- */
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    dsyev_(&jobz, &uplo, &n, A, &lda, W, WORK, &lwork, &info);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    if (info != 0) { fprintf(stderr, "DSYEV failed, info=%d\n", info); free(WORK); goto CLEANUP_ERR; }
    double time_syev = elapsed_seconds(t0, t1);

    printf("\n[TOP] DSYEV total wall time: %.3f s (n=%d, jobz=%c, uplo=%c)\n",
           time_syev, n, jobz, uplo);

    /* ---- Save outputs (lightweight) ---- */
    {
        char dir[128]; snprintf(dir, sizeof(dir), "../output/run_syev_detailed_N%d", n);
        ensure_dir(dir);
        char path_w[160], path_v[160];
        snprintf(path_w, sizeof(path_w), "%s/eigenvalues.txt", dir);
        snprintf(path_v, sizeof(path_v), "%s/eigenvectors.txt", dir);

        /* First up to 5 eigenvalues (ascending) */
        FILE *fw = fopen(path_w, "w");
        if (fw){
            int k = n < 5 ? n : 5;
            for (int i = 0; i < k; ++i) fprintf(fw, "%.12e\n", W[i]);
            fprintf(fw, "# truncated: total %d eigenvalues\n", n);
            fclose(fw);
        }

        /* First up to 5 eigenvector columns (full length) */
        if (jobz == 'V'){
            FILE *fv = fopen(path_v, "w");
            if (fv){
                int k = n < 5 ? n : 5;
                fprintf(fv, "# columns 0..%d, each of length n=%d\n", k-1, n);
                for (int j = 0; j < k; ++j){
                    fprintf(fv, "# column %d (eigenvalue index %d)\n", j, j);
                    for (int i = 0; i < n; ++i){
                        fprintf(fv, "%.6e\n", A[i + (size_t)j * n]);
                    }
                }
                fprintf(fv, "# truncated: total matrix %d x %d\n", n, n);
                fclose(fv);
            }
        }
    }

    free(WORK); free(W); free(A);
    return 0;

CLEANUP_ERR:
    free(W); free(A);
    return 2;
}
