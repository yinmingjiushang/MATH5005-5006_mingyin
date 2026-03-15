/* wrap_syev.c — DSYEV full-path timing wrappers (STEQR + ORGTR path)
 * Root scopes used here: "sytrd", "steqr", "dorgtr"
 *
 * Build: link with --wrap for every symbol you want timed (see your build script).
 * Notes:
 *  - We reuse the same timer glue API as your syevd wrapper:
 *      __stedc_timer_add, __stedc_scope_push, __stedc_scope_pop
 *  - LWORK=-1 / workspace query calls are *not* timed.
 */

#define _POSIX_C_SOURCE 200112L
#include <time.h>

/* ===== timer glue (provided by wrap_timers.c) ===== */
extern void __stedc_timer_add(const char *name, double dt);
extern void __stedc_scope_push(const char *scope);
extern void __stedc_scope_pop(void);
static inline double __t_now(void){
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

/* ===== portable integer types (LP64 / ILP64) ===== */
#ifndef LAPACK_INT
#  if defined(OPENBLAS_USE64BITINT) || defined(LAPACK_ILP64) || defined(MKL_ILP64)
     typedef long long lapack_int;
#  else
     typedef int lapack_int;
#  endif
#endif

#ifndef BLAS_INT
#  define BLAS_INT lapack_int
#endif

/* ================= Real (library) symbols ================= */
/* ---- DSYEV + siblings ---- */
extern void __real_dsyev_(char *JOBZ, char *UPLO, lapack_int *N,
                          double *A, lapack_int *LDA, double *W,
                          double *WORK, lapack_int *LWORK, lapack_int *INFO);

extern void __real_dsytrd_(char *UPLO, lapack_int *N, double *A, lapack_int *LDA,
                           double *D, double *E, double *TAU,
                           double *WORK, lapack_int *LWORK, lapack_int *INFO);

/* ---- Tridiagonal eigensolvers (QR) ---- */
extern void __real_dsteqr_(char *COMPZ, lapack_int *N, double *D, double *E,
                           double *Z, lapack_int *LDZ, double *WORK, lapack_int *INFO);

extern void __real_dsterf_(lapack_int *N, double *D, double *E, lapack_int *INFO);

/* ---- STEQR helpers ---- */
extern void __real_dlae2_(double *A, double *B, double *C, double *RT1, double *RT2);
extern void __real_dlaev2_(double *A, double *B, double *C, double *RT1, double *RT2, double *CS1, double *SN1);
extern void __real_dlartg_(double *F, double *G, double *CS, double *SN, double *R);
extern void __real_dlasr_(char *SIDE, char *PIVOT, char *DIRECT,
                          lapack_int *M, lapack_int *N,
                          double *C, double *S, double *A, lapack_int *LDA);
extern void __real_dlasrt_(char *ID, lapack_int *N, double *D, lapack_int *INFO);
extern void __real_dswap_(lapack_int *N, double *DX, lapack_int *INCX, double *DY, lapack_int *INCY);
extern void __real_dlaset_(char *UPLO, lapack_int *M, lapack_int *N, double *ALPHA, double *BETA,
                           double *A, lapack_int *LDA);

/* ---- Q formation (ORGTR path) ---- */
extern void __real_dorgtr_(char *UPLO, lapack_int *N, double *A, lapack_int *LDA,
                           double *TAU, double *WORK, lapack_int *LWORK, lapack_int *INFO);

extern void __real_dorgqr_(lapack_int *M, lapack_int *N, lapack_int *K,
                           double *A, lapack_int *LDA, double *TAU,
                           double *WORK, lapack_int *LWORK, lapack_int *INFO);

extern void __real_dorg2r_(lapack_int *M, lapack_int *N, lapack_int *K,
                           double *A, lapack_int *LDA, double *TAU, double *WORK, lapack_int *INFO);

extern void __real_dorgql_(lapack_int *M, lapack_int *N, lapack_int *K,
                           double *A, lapack_int *LDA, double *TAU,
                           double *WORK, lapack_int *LWORK, lapack_int *INFO);

extern void __real_dorg2l_(lapack_int *M, lapack_int *N, lapack_int *K,
                           double *A, lapack_int *LDA, double *TAU, double *WORK, lapack_int *INFO);

/* ---- Blocked reflectors used by ORGTR ---- */
extern void __real_dlarft_(char *DIRECT, char *STOREV,
                           lapack_int *N, lapack_int *K,
                           double *V, lapack_int *LDV, double *TAU,
                           double *T, lapack_int *LDT);

extern void __real_dlarfb_(char *SIDE, char *TRANS, char *DIRECT, char *STOREV,
                           lapack_int *M, lapack_int *N, lapack_int *K,
                           double *V, lapack_int *LDV, double *T, lapack_int *LDT,
                           double *C, lapack_int *LDC, double *WORK, lapack_int *LDWORK);

/* ---- BLAS kernels (ORGTR may use) ---- */
extern void __real_dgemm_(char*, char*, BLAS_INT*, BLAS_INT*, BLAS_INT*,
                          double*, double*, BLAS_INT*, double*, BLAS_INT*,
                          double*, double*, BLAS_INT*);

extern void __real_dtrmm_(char*, char*, char*, char*,
                          BLAS_INT*, BLAS_INT*, double*,
                          double*, BLAS_INT*, double*, BLAS_INT*);

/* ================= WRAPPERS (timed) ================= */

/* ---- DSYEV top ---- */
void __wrap_dsyev_(char *jobz, char *uplo, lapack_int *n,
                   double *A, lapack_int *lda, double *W,
                   double *work, lapack_int *lwork, lapack_int *info)
{
    int is_query = (lwork && *lwork == -1);
    double t0 = is_query ? 0.0 : __t_now();
    __real_dsyev_(jobz, uplo, n, A, lda, W, work, lwork, info);
    if (!is_query) __stedc_timer_add("dsyev_", __t_now() - t0);
}

/* ---- Tridiagonalization (ROOT SCOPE: sytrd) ---- */
void __wrap_dsytrd_(char *uplo, lapack_int *n, double *A, lapack_int *lda,
                    double *D, double *E, double *TAU,
                    double *WORK, lapack_int *LWORK, lapack_int *INFO)
{
    __stedc_scope_push("sytrd");
    double t0 = __t_now();
    __real_dsytrd_(uplo, n, A, lda, D, E, TAU, WORK, LWORK, INFO);
    __stedc_timer_add("dsytrd_", __t_now() - t0);
    __stedc_scope_pop();
}

/* ---- Tri eigen (values only) ---- */
void __wrap_dsterf_(lapack_int *n, double *D, double *E, lapack_int *info)
{
    double t0 = __t_now();
    __real_dsterf_(n, D, E, info);
    __stedc_timer_add("dsterf_", __t_now() - t0);
}

/* ---- STEQR (ROOT SCOPE: steqr) + helpers ---- */
void __wrap_dsteqr_(char *compz, lapack_int *n, double *d, double *e,
                    double *z, lapack_int *ldz, double *work, lapack_int *info)
{
    int is_query = 0; /* dsteqr has no workspace query contract */
    if (!is_query) __stedc_scope_push("steqr");
    double t0 = __t_now();
    __real_dsteqr_(compz, n, d, e, z, ldz, work, info);
    __stedc_timer_add("dsteqr_", __t_now() - t0);
    __stedc_scope_pop();
}

void __wrap_dlae2_(double *A, double *B, double *C, double *RT1, double *RT2)
{
    double t0 = __t_now();
    __real_dlae2_(A, B, C, RT1, RT2);
    __stedc_timer_add("dlae2_", __t_now() - t0);
}

void __wrap_dlaev2_(double *A, double *B, double *C, double *RT1, double *RT2, double *CS1, double *SN1)
{
    double t0 = __t_now();
    __real_dlaev2_(A, B, C, RT1, RT2, CS1, SN1);
    __stedc_timer_add("dlaev2_", __t_now() - t0);
}

void __wrap_dlartg_(double *F, double *G, double *CS, double *SN, double *R)
{
    double t0 = __t_now();
    __real_dlartg_(F, G, CS, SN, R);
    __stedc_timer_add("dlartg_", __t_now() - t0);
}

void __wrap_dlasr_(char *SIDE, char *PIVOT, char *DIRECT,
                   lapack_int *M, lapack_int *N,
                   double *C, double *S, double *A, lapack_int *LDA)
{
    double t0 = __t_now();
    __real_dlasr_(SIDE, PIVOT, DIRECT, M, N, C, S, A, LDA);
    __stedc_timer_add("dlasr_", __t_now() - t0);
}

void __wrap_dlasrt_(char *ID, lapack_int *N, double *D, lapack_int *INFO)
{
    double t0 = __t_now();
    __real_dlasrt_(ID, N, D, INFO);
    __stedc_timer_add("dlasrt_", __t_now() - t0);
}

void __wrap_dswap_(lapack_int *N, double *DX, lapack_int *INCX, double *DY, lapack_int *INCY)
{
    double t0 = __t_now();
    __real_dswap_(N, DX, INCX, DY, INCY);
    __stedc_timer_add("dswap_", __t_now() - t0);
}

void __wrap_dlaset_(char *UPLO, lapack_int *M, lapack_int *N, double *ALPHA, double *BETA,
                    double *A, lapack_int *LDA)
{
    double t0 = __t_now();
    __real_dlaset_(UPLO, M, N, ALPHA, BETA, A, LDA);
    __stedc_timer_add("dlaset_", __t_now() - t0);
}

/* ---- ORGTR (ROOT SCOPE: dorgtr) + its chain ---- */
void __wrap_dorgtr_(char *UPLO, lapack_int *N, double *A, lapack_int *LDA,
                    double *TAU, double *WORK, lapack_int *LWORK, lapack_int *INFO)
{
    int is_query = (LWORK && *LWORK == -1);
    if (!is_query) __stedc_scope_push("dorgtr");
    double t0 = is_query ? 0.0 : __t_now();
    __real_dorgtr_(UPLO, N, A, LDA, TAU, WORK, LWORK, INFO);
    if (!is_query) {
        __stedc_timer_add("dorgtr_", __t_now() - t0);
        __stedc_scope_pop();
    }
}

/* Depending on UPLO ('U' → QR, 'L' → QL) DSYEV/ORGTR will internally use these */
void __wrap_dorgqr_(lapack_int *M, lapack_int *N, lapack_int *K,
                    double *A, lapack_int *LDA, double *TAU,
                    double *WORK, lapack_int *LWORK, lapack_int *INFO)
{
    double t0 = __t_now();
    __real_dorgqr_(M, N, K, A, LDA, TAU, WORK, LWORK, INFO);
    __stedc_timer_add("dorgqr_", __t_now() - t0);
}

void __wrap_dorg2r_(lapack_int *M, lapack_int *N, lapack_int *K,
                    double *A, lapack_int *LDA, double *TAU, double *WORK, lapack_int *INFO)
{
    double t0 = __t_now();
    __real_dorg2r_(M, N, K, A, LDA, TAU, WORK, INFO);
    __stedc_timer_add("dorg2r_", __t_now() - t0);
}

void __wrap_dorgql_(lapack_int *M, lapack_int *N, lapack_int *K,
                    double *A, lapack_int *LDA, double *TAU,
                    double *WORK, lapack_int *LWORK, lapack_int *INFO)
{
    double t0 = __t_now();
    __real_dorgql_(M, N, K, A, LDA, TAU, WORK, LWORK, INFO);
    __stedc_timer_add("dorgql_", __t_now() - t0);
}

void __wrap_dorg2l_(lapack_int *M, lapack_int *N, lapack_int *K,
                    double *A, lapack_int *LDA, double *TAU, double *WORK, lapack_int *INFO)
{
    double t0 = __t_now();
    __real_dorg2l_(M, N, K, A, LDA, TAU, WORK, INFO);
    __stedc_timer_add("dorg2l_", __t_now() - t0);
}

/* ---- Block reflectors used by ORGTR ---- */
void __wrap_dlarft_(char *DIRECT, char *STOREV,
                    lapack_int *N, lapack_int *K,
                    double *V, lapack_int *LDV, double *TAU,
                    double *T, lapack_int *LDT)
{
    double t0 = __t_now();
    __real_dlarft_(DIRECT, STOREV, N, K, V, LDV, TAU, T, LDT);
    __stedc_timer_add("dlarft_", __t_now() - t0);
}

void __wrap_dlarfb_(char *SIDE, char *TRANS, char *DIRECT, char *STOREV,
                    lapack_int *M, lapack_int *N, lapack_int *K,
                    double *V, lapack_int *LDV, double *T, lapack_int *LDT,
                    double *C, lapack_int *LDC, double *WORK, lapack_int *LDWORK)
{
    double t0 = __t_now();
    __real_dlarfb_(SIDE, TRANS, DIRECT, STOREV, M, N, K, V, LDV, T, LDT, C, LDC, WORK, LDWORK);
    __stedc_timer_add("dlarfb_", __t_now() - t0);
}

/* ---- (optional) BLAS kernels often hit by ORGTR path ---- */
void __wrap_dgemm_(char *transa, char *transb,
                   BLAS_INT *m, BLAS_INT *n, BLAS_INT *k,
                   double *alpha, double *A, BLAS_INT *lda,
                   double *B, BLAS_INT *ldb,
                   double *beta,  double *C, BLAS_INT *ldc)
{
    double t0 = __t_now();
    __real_dgemm_(transa, transb, m, n, k, alpha, A, lda, B, ldb, beta, C, ldc);
    __stedc_timer_add("dgemm_", __t_now() - t0);
}

void __wrap_dtrmm_(char* SIDE, char* UPLO, char* TRANS, char* DIAG,
                   BLAS_INT* M, BLAS_INT* N, double* ALPHA,
                   double* A, BLAS_INT* LDA, double* B, BLAS_INT* LDB)
{
    double t0 = __t_now();
    __real_dtrmm_(SIDE, UPLO, TRANS, DIAG, M, N, ALPHA, A, LDA, B, LDB);
    __stedc_timer_add("dtrmm_", __t_now() - t0);
}
/* ===== BLAS Level-1/2 passthrough wrappers (timed) ===== */
/* NOTE: uses BLAS_INT typedef and __t_now/__stedc_timer_add from earlier in this file. */

extern void __real_dgemv_(char *TRANS, BLAS_INT *M, BLAS_INT *N,
                          double *ALPHA, double *A, BLAS_INT *LDA,
                          double *X, BLAS_INT *INCX,
                          double *BETA,  double *Y, BLAS_INT *INCY);
void __wrap_dgemv_(char *TRANS, BLAS_INT *M, BLAS_INT *N,
                   double *ALPHA, double *A, BLAS_INT *LDA,
                   double *X, BLAS_INT *INCX,
                   double *BETA,  double *Y, BLAS_INT *INCY)
{
    double t0 = __t_now();
    __real_dgemv_(TRANS, M, N, ALPHA, A, LDA, X, INCX, BETA, Y, INCY);
    __stedc_timer_add("dgemv_", __t_now() - t0);
}

extern void __real_dtrmv_(char *UPLO, char *TRANS, char *DIAG,
                          BLAS_INT *N, double *A, BLAS_INT *LDA,
                          double *X, BLAS_INT *INCX);
void __wrap_dtrmv_(char *UPLO, char *TRANS, char *DIAG,
                   BLAS_INT *N, double *A, BLAS_INT *LDA,
                   double *X, BLAS_INT *INCX)
{
    double t0 = __t_now();
    __real_dtrmv_(UPLO, TRANS, DIAG, N, A, LDA, X, INCX);
    __stedc_timer_add("dtrmv_", __t_now() - t0);
}

extern void __real_dger_(BLAS_INT *M, BLAS_INT *N, double *ALPHA,
                         double *X, BLAS_INT *INCX, double *Y, BLAS_INT *INCY,
                         double *A, BLAS_INT *LDA);
void __wrap_dger_(BLAS_INT *M, BLAS_INT *N, double *ALPHA,
                  double *X, BLAS_INT *INCX, double *Y, BLAS_INT *INCY,
                  double *A, BLAS_INT *LDA)
{
    double t0 = __t_now();
    __real_dger_(M, N, ALPHA, X, INCX, Y, INCY, A, LDA);
    __stedc_timer_add("dger_", __t_now() - t0);
}

extern void __real_dcopy_(BLAS_INT *N, double *X, BLAS_INT *INCX,
                          double *Y, BLAS_INT *INCY);
void __wrap_dcopy_(BLAS_INT *N, double *X, BLAS_INT *INCX,
                   double *Y, BLAS_INT *INCY)
{
    double t0 = __t_now();
    __real_dcopy_(N, X, INCX, Y, INCY);
    __stedc_timer_add("dcopy_", __t_now() - t0);
}

extern void __real_dscal_(BLAS_INT *N, double *ALPHA, double *X, BLAS_INT *INCX);
void __wrap_dscal_(BLAS_INT *N, double *ALPHA, double *X, BLAS_INT *INCX)
{
    double t0 = __t_now();
    __real_dscal_(N, ALPHA, X, INCX);
    __stedc_timer_add("dscal_", __t_now() - t0);
}

extern void __real_drot_(BLAS_INT *N, double *X, BLAS_INT *INCX,
                         double *Y, BLAS_INT *INCY, double *C, double *S);
void __wrap_drot_(BLAS_INT *N, double *X, BLAS_INT *INCX,
                  double *Y, BLAS_INT *INCY, double *C, double *S)
{
    double t0 = __t_now();
    __real_drot_(N, X, INCX, Y, INCY, C, S);
    __stedc_timer_add("drot_", __t_now() - t0);
}
