// syevd_omp_dormtr.c — Build a KMS SPD matrix A, then compute eigenpairs by
// SYTRD → (top-level parallel STEDC) → DORMTR (apply Q on Z).
// Column-major, vendor-agnostic. Requires LAPACK + (optionally) OpenMP.
//
// Compile example:
//   gcc -O3 -fopenmp syevd_omp_dormtr.c -lopenblas -lm -o syevd_omp_dormtr
//
// Runtime tips:
//   export OMP_NUM_THREADS=2
//   export OPENBLAS_NUM_THREADS=1

#define _POSIX_C_SOURCE 200112L

#ifdef __has_include
#  if __has_include(<openblas_config.h>)
#    include <openblas_config.h>
#  endif
#endif
#ifdef OPENBLAS_USE64BITINT
  typedef long long lapack_int;
#else
  typedef int        lapack_int;
#endif

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <math.h>
#include <string.h>

#ifdef _OPENMP
  #include <omp.h>
#endif

extern void dsytrd_(const char *UPLO, const lapack_int *N, double *A, const lapack_int *LDA,
                    double *D, double *E, double *TAU,
                    double *WORK, const lapack_int *LWORK, lapack_int *INFO);

extern void dstedc_(const char *COMPZ, const lapack_int *N, double *D, double *E,
                    double *Z, const lapack_int *LDZ, double *WORK, const lapack_int *LWORK,
                    lapack_int *IWORK, const lapack_int *LIWORK, lapack_int *INFO);

extern void dlaed1_(const lapack_int *N, double *D, double *Q, const lapack_int *LDQ,
                    lapack_int *INDXQ, double *RHO, lapack_int *CUTPNT,
                    double *WORK, lapack_int *IWORK, lapack_int *INFO);

extern void dlaset_(const char *UPLO, const lapack_int *M, const lapack_int *N,
                    const double *ALPHA, const double *BETA, double *A, const lapack_int *LDA);

extern void dormtr_(const char *SIDE, const char *UPLO, const char *TRANS,
                    const lapack_int *M, const lapack_int *N,
                    const double *A, const lapack_int *LDA, const double *TAU,
                    double *C, const lapack_int *LDC,
                    double *WORK, const lapack_int *LWORK, lapack_int *INFO);

__attribute__((weak)) extern char* openblas_get_config(void);
__attribute__((weak)) extern char* openblas_get_corename(void);
__attribute__((weak)) extern int   openblas_get_num_threads(void);
__attribute__((weak)) extern void  openblas_set_num_threads(int);

static void ensure_dir(const char *path) {
    if (mkdir(path, 0777) != 0 && errno != EEXIST) {
        perror("mkdir");
        exit(5);
    }
}
static double elapsed_seconds(struct timespec a, struct timespec b) {
    return (b.tv_sec - a.tv_sec) + (b.tv_nsec - a.tv_nsec) / 1e9;
}

static void fill_kms(double *A, lapack_int n, double rho, double delta)
{
    if (!(rho > -1.0 && rho < 1.0)) rho = 0.95;
    if (delta < 0.0) delta = 0.0;
    double arho = fabs(rho);
    double *rp = malloc((size_t)n * sizeof(double));
    if (!rp) { fprintf(stderr, "Allocation failed (rp)\n"); exit(6); }
    rp[0] = 1.0;
    for (lapack_int k = 1; k < n; ++k) rp[k] = rp[k-1] * arho;
    for (lapack_int j = 0; j < n; ++j) {
        for (lapack_int i = 0; i <= j; ++i) {
            lapack_int d = j - i;
            double v = rp[d];
            if (i == j) v += delta;
            A[i + (size_t)j * n] = v;
            A[j + (size_t)i * n] = v;
        }
    }
    free(rp);
}

/* ===== parallel 2-way STEDC ===== */
static lapack_int omp_top_stedc_2way(lapack_int n, double *D, double *E, double *Z, lapack_int ldz)
{
    if (n <= 1) { if (n == 1) Z[0] = 1.0; return 0; }

    lapack_int info = 0;
    lapack_int m = n / 2;
    double rho = E[m-1];
    E[m-1] = 0.0;
    lapack_int n1 = m, n2 = n - m;

    double zero = 0.0, one = 1.0;
    dlaset_("A", &n, &n, &zero, &one, Z, &ldz);

    lapack_int lwork1  = 1 + 3*n1 + 2*n1*n1;
    lapack_int liwork1 = 6 + 6*n1;
    lapack_int lwork2  = 1 + 3*n2 + 2*n2*n2;
    lapack_int liwork2 = 6 + 6*n2;

    double     *work1  = malloc((size_t)lwork1  * sizeof(double));
    lapack_int *iwork1 = malloc((size_t)liwork1 * sizeof(lapack_int));
    double     *work2  = malloc((size_t)lwork2  * sizeof(double));
    lapack_int *iwork2 = malloc((size_t)liwork2 * sizeof(lapack_int));
    if (!work1 || !iwork1 || !work2 || !iwork2) { info = -100; goto CLEAN; }

#pragma omp parallel sections num_threads(2)
    {
#pragma omp section
        {
            lapack_int infoL = 0;
            char compz = 'I';
            dstedc_(&compz, &n1, D, E, Z, &ldz, work1, &lwork1, iwork1, &liwork1, &infoL);
            if (infoL != 0) {
#pragma omp critical
                { info = infoL; }
            }
        }
#pragma omp section
        {
            lapack_int infoR = 0;
            char compz = 'I';
            dstedc_(&compz, &n2, D + n1, E + n1,
                    Z + (size_t)n1 + (size_t)n1 * (size_t)ldz, &ldz,
                    work2, &lwork2, iwork2, &liwork2, &infoR);
            if (infoR != 0) {
#pragma omp critical
                { info = infoR; }
            }
        }
    }
    if (info) goto CLEAN;

    lapack_int cutpnt = n1;
    lapack_int *indxq = malloc((size_t)n * sizeof(lapack_int));
    if (!indxq) { info = -101; goto CLEAN; }
    for (lapack_int i = 0; i < n1; ++i) indxq[i] = i + 1;
    for (lapack_int i = 0; i < n2; ++i) indxq[n1+i] = i + 1;
    lapack_int lw  = 3*n + 3*cutpnt*(n-cutpnt) + n + 100;
    lapack_int liw = 4*n + 100;
    double     *w  = malloc((size_t)lw  * sizeof(double));
    lapack_int *iw = malloc((size_t)liw * sizeof(lapack_int));
    if (!w || !iw) { info = -102; free(indxq); goto CLEAN; }
    dlaed1_(&n, D, Z, &ldz, indxq, &rho, &cutpnt, w, iw, &info);
    free(indxq); free(w); free(iw);

CLEAN:
    free(work1); free(iwork1); free(work2); free(iwork2);
    return info;
}

/* ===== main ===== */
int main(void)
{
//    if (openblas_get_config) printf("OpenBLAS config: %s\n", openblas_get_config());
//    printf("sizeof(lapack_int) = %zu\n", sizeof(lapack_int));
    #ifdef _OPENMP
        printf("omp_get_num_procs()   = %d\n", omp_get_num_procs());
        printf("omp_get_max_threads() = %d\n", omp_get_max_threads());
    #endif

    const lapack_int n = 8192, lda = n;
    const char uplo='U', jobz='V';
    const double rho=0.95, delta=0.0;

    if (openblas_get_corename)
        printf("OpenBLAS core: %s\n", openblas_get_corename());
    printf("Mode: SYTRD + OMP-STEDC(2-way) + DORMTR\n");

    double *A = malloc((size_t)n * lda * sizeof(double));
    double *W = malloc((size_t)n * sizeof(double));
    if (!A || !W) { fprintf(stderr,"Alloc fail.\n"); return 1; }

    fill_kms(A,n,rho,delta);

    double *D=malloc((size_t)n*sizeof(double));
    double *E=malloc((size_t)(n-1)*sizeof(double));
    double *TAU=malloc((size_t)(n-1)*sizeof(double));
    if(!D||!E||!TAU){fprintf(stderr,"Alloc fail DE.\n");return 2;}

    lapack_int info=0,lwork=-1; double wkopt=0.0;
    dsytrd_(&uplo,&n,A,&lda,D,E,TAU,&wkopt,&lwork,&info);
    lwork=(lapack_int)wkopt; double *WORK=malloc((size_t)lwork*sizeof(double));
    struct timespec t0,t1; clock_gettime(CLOCK_MONOTONIC,&t0);
    dsytrd_(&uplo,&n,A,&lda,D,E,TAU,WORK,&lwork,&info);

    int prev=openblas_get_num_threads?openblas_get_num_threads():1;
    if(openblas_set_num_threads) openblas_set_num_threads(1);
    double *Z=malloc((size_t)n*(size_t)n*sizeof(double));
    omp_top_stedc_2way(n,D,E,Z,n);

    char side='L',trans='N';
    lwork=-1; wkopt=0.0;
    dormtr_(&side,&uplo,&trans,&n,&n,A,&lda,TAU,Z,&n,&wkopt,&lwork,&info);
    lwork=(lapack_int)wkopt;
    free(WORK); WORK=malloc((size_t)lwork*sizeof(double));
#ifdef _OPENMP
    int want=omp_get_max_threads();
#else
    int want=(prev>0?prev:1);
#endif
    if(openblas_set_num_threads) openblas_set_num_threads(want);
    dormtr_(&side,&uplo,&trans,&n,&n,A,&lda,TAU,Z,&n,WORK,&lwork,&info);

    clock_gettime(CLOCK_MONOTONIC,&t1);
    double total=elapsed_seconds(t0,t1);
    printf("TOTAL (SYTRD + OMP-STEDC(2) + DORMTR) took %.3f s\n", total);

    memcpy(W,D,(size_t)n*sizeof(double));
    ensure_dir("../output");
    FILE*f=fopen("../output/syevd_time.txt","w");
    if(f){fprintf(f,"TOTAL %.6f s\n",total);fclose(f);}
    free(Z);free(WORK);free(TAU);free(E);free(D);free(W);free(A);
    return 0;
}
