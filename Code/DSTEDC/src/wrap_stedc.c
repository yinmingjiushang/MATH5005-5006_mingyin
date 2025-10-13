// wrap_stedc.c — wrappers for LAPACK STEDC subtree (OpenBLAS/Netlib).


#include <time.h>

/* ===== timer glue (from wrap_timers.c) ===== */
extern void __stedc_timer_add(const char *name, double dt);
static inline double __t_now(void){
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

/* ===== BLAS (Fortran) real symbols ===== */
#ifndef BLAS_INT
#  define BLAS_INT lapack_int  /* 你的 OpenBLAS 是 ILP64/LP64 都能对齐 */
#endif

/* ===== portable LAPACK integer (LP64/ILP64) ===== */
#ifndef LAPACK_INT
#  if defined(OPENBLAS_USE64BITINT) || defined(LAPACK_ILP64) || defined(MKL_ILP64)
     typedef long long lapack_int;
#  else
     typedef int lapack_int;
#  endif
#endif

/* ================= REAL (library) symbols ================= */

/* top-level */
extern void __real_dstedc_(char *COMPZ, lapack_int *N, double *D, double *E,
                           double *Z, lapack_int *LDZ,
                           double *WORK, lapack_int *LWORK,
                           lapack_int *IWORK, lapack_int *LIWORK, lapack_int *INFO);

/* helpers commonly seen on this path */
extern void __real_dlamrg_(lapack_int *N1, lapack_int *N2, double *A,
                           lapack_int *DTRD1, lapack_int *DTRD2, lapack_int *INDEX);
extern void __real_dlasrt_(char *ID, lapack_int *N, double *D, lapack_int *INFO);
extern void __real_dlacpy_(char *UPLO, lapack_int *M, lapack_int *N,
                           double *A, lapack_int *LDA, double *B, lapack_int *LDB);
extern void __real_dsteqr_(char *COMPZ, lapack_int *N, double *D, double *E,
                           double *Z, lapack_int *LDZ, double *WORK, lapack_int *INFO);

/* divide & conquer core often used by DSTEDC implementations */
extern void __real_dlaed0_(lapack_int *ICOMPQ, lapack_int *QSIZ, lapack_int *N,
                           double *D, double *E, double *Q, lapack_int *LDQ,
                           double *QSTORE, lapack_int *LDQS, double *WORK,
                           lapack_int *IWORK, lapack_int *INFO);

/* ========= DLAED1..6,9,A real symbols (exactly your interfaces) ========= */

/* DLAED1( N, D, Q, LDQ, INDXQ, RHO, CUTPNT, WORK, IWORK, INFO ) */
extern void __real_dlaed1_(lapack_int *N, double *D, double *Q, lapack_int *LDQ,
                           lapack_int *INDXQ, double *RHO, lapack_int *CUTPNT,
                           double *WORK, lapack_int *IWORK, lapack_int *INFO);

/* DLAED2( K, N, N1, D, Q, LDQ, INDXQ, RHO, Z, DLAMBDA, W, Q2, INDX, INDXC, INDXP, COLTYP, INFO ) */
extern void __real_dlaed2_(lapack_int *K, lapack_int *N, lapack_int *N1,
                           double *D, double *Q, lapack_int *LDQ, lapack_int *INDXQ,
                           double *RHO, double *Z, double *DLAMBDA, double *W, double *Q2,
                           lapack_int *INDX, lapack_int *INDXC, lapack_int *INDXP,
                           lapack_int *COLTYP, lapack_int *INFO);

/* DLAED3( K, N, N1, D, Q, LDQ, RHO, DLAMBDA, Q2, INDX, CTOT, W, S, INFO ) */
extern void __real_dlaed3_(lapack_int *K, lapack_int *N, lapack_int *N1,
                           double *D, double *Q, lapack_int *LDQ, double *RHO,
                           double *DLAMBDA, double *Q2, lapack_int *INDX, lapack_int *CTOT,
                           double *W, double *S, lapack_int *INFO);

/* DLAED4( N, I, D, Z, DELTA, RHO, DLAM, INFO ) */
extern void __real_dlaed4_(lapack_int *N, lapack_int *I, double *D, double *Z,
                           double *DELTA, double *RHO, double *DLAM, lapack_int *INFO);

/* DLAED5( I, D, Z, DELTA, RHO, DLAM ) */
extern void __real_dlaed5_(lapack_int *I, double *D, double *Z,
                           double *DELTA, double *RHO, double *DLAM);

/* DLAED6( KNITER, ORGATI, RHO, D, Z, FINIT, TAU, INFO )  (ORGATI is LOGICAL) */
extern void __real_dlaed6_(lapack_int *KNITER, lapack_int *ORGATI, double *RHO,
                           double *D, double *Z, double *FINIT, double *TAU, lapack_int *INFO);

/* DLAED9( K, KSTART, KSTOP, N, D, Q, LDQ, RHO, DLAMBDA, W, S, LDS, INFO ) */
extern void __real_dlaed9_(lapack_int *K, lapack_int *KSTART, lapack_int *KSTOP,
                           lapack_int *N, double *D, double *Q, lapack_int *LDQ,
                           double *RHO, double *DLAMBDA, double *W, double *S,
                           lapack_int *LDS, lapack_int *INFO);

/* DLAEDA( N, TLVLS, CURLVL, CURPBM, PRMPTR, PERM, GIVPTR, GIVCOL, GIVNUM,
          Q, QPTR, Z, ZTEMP, INFO ) */
extern void __real_dlaeda_(lapack_int *N, lapack_int *TLVLS, lapack_int *CURLVL, lapack_int *CURPBM,
                           lapack_int *PRMPTR, lapack_int *PERM, lapack_int *GIVPTR,
                           lapack_int *GIVCOL, double *GIVNUM,
                           double *Q, lapack_int *QPTR, double *Z, double *ZTEMP, lapack_int *INFO);


/* ===== EXACT signatures from your Fortran headers ===== */

/* DLAED7(ICOMPQ, N, QSIZ, TLVLS, CURLVL, CURPBM, D, Q,
 *        LDQ, INDXQ, RHO, CUTPNT, QSTORE, QPTR, PRMPTR,
 *        PERM, GIVPTR, GIVCOL, GIVNUM, WORK, IWORK, INFO)
 */
extern void __real_dlaed7_(lapack_int *ICOMPQ, lapack_int *N, lapack_int *QSIZ,
                           lapack_int *TLVLS,  lapack_int *CURLVL, lapack_int *CURPBM,
                           double *D, double *Q, lapack_int *LDQ, lapack_int *INDXQ,
                           double *RHO, lapack_int *CUTPNT,
                           double *QSTORE, lapack_int *QPTR, lapack_int *PRMPTR, lapack_int *PERM,
                           lapack_int *GIVPTR, lapack_int *GIVCOL, double *GIVNUM,
                           double *WORK, lapack_int *IWORK, lapack_int *INFO);

/* DLAED8(ICOMPQ, K, N, QSIZ, D, Q, LDQ, INDXQ, RHO,
 *        CUTPNT, Z, DLAMBDA, Q2, LDQ2, W, PERM, GIVPTR,
 *        GIVCOL, GIVNUM, INDXP, INDX, INFO)
 */
extern void __real_dlaed8_(lapack_int *ICOMPQ, lapack_int *K, lapack_int *N,
                           lapack_int *QSIZ,
                           double *D, double *Q, lapack_int *LDQ, lapack_int *INDXQ,
                           double *RHO, lapack_int *CUTPNT, double *Z, double *DLAMBDA,
                           double *Q2, lapack_int *LDQ2, double *W, lapack_int *PERM,
                           lapack_int *GIVPTR, lapack_int *GIVCOL, double *GIVNUM,
                           lapack_int *INDXP, lapack_int *INDX, lapack_int *INFO);

/* DGEMM: C := alpha*A*B + beta*C  (TRANSA, TRANSB, M, N, K, ALPHA, A, LDA, B, LDB, BETA, C, LDC) */
extern void __real_dgemm_(char*, char*, BLAS_INT*, BLAS_INT*, BLAS_INT*,
                          double*, double*, BLAS_INT*, double*, BLAS_INT*,
                          double*, double*, BLAS_INT*);

/* DGEMV: y := alpha*A*x + beta*y  (TRANS, M, N, ALPHA, A, LDA, X, INCX, BETA, Y, INCY) */
extern void __real_dgemv_(char*, BLAS_INT*, BLAS_INT*, double*,
                          double*, BLAS_INT*, double*, BLAS_INT*,
                          double*, double*, BLAS_INT*);

/* DCOPY: y := x */
extern void __real_dcopy_(BLAS_INT*, const double*, BLAS_INT*, double*, BLAS_INT*);

/* DSCAL: x := alpha*x */
extern void __real_dscal_(BLAS_INT*, const double*, double*, BLAS_INT*);

/* DROT: plane rotation on (x, y) */
extern void __real_drot_(BLAS_INT*, double*, BLAS_INT*, double*, BLAS_INT*,
                         const double*, const double*);

extern void __real_cblas_dgemm(int Order, int TransA, int TransB,
                               int M, int N, int K,
                               double alpha, const double *A, int lda,
                               const double *B, int ldb,
                               double beta, double *C, int ldc);

extern void __real_cblas_dgemv(int Order, int TransA,
                               int M, int N,
                               double alpha, const double *A, int lda,
                               const double *X, int incX,
                               double beta, double *Y, int incY);

/* ================= WRAPPERS ================= */

void __wrap_dstedc_(char *compz, lapack_int *n, double *d, double *e,
                    double *z, lapack_int *ldz,
                    double *work, lapack_int *lwork,
                    lapack_int *iwork, lapack_int *liwork, lapack_int *info)
{
    int is_query = (lwork && *lwork == -1) || (liwork && *liwork == -1);
    double t0 = is_query ? 0.0 : __t_now();
    __real_dstedc_(compz, n, d, e, z, ldz, work, lwork, iwork, liwork, info);
    if (!is_query) __stedc_timer_add("dstedc_", __t_now() - t0);
}

/* helpers */
void __wrap_dlamrg_(lapack_int *n1, lapack_int *n2, double *a,
                    lapack_int *d1, lapack_int *d2, lapack_int *idx)
{
    double t0 = __t_now();
    __real_dlamrg_(n1, n2, a, d1, d2, idx);
    __stedc_timer_add("dlamrg_", __t_now() - t0);
}
void __wrap_dlasrt_(char *id, lapack_int *n, double *d, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlasrt_(id, n, d, info);
    __stedc_timer_add("dlasrt_", __t_now() - t0);
}
void __wrap_dlacpy_(char *uplo, lapack_int *m, lapack_int *n,
                    double *a, lapack_int *lda, double *b, lapack_int *ldb)
{
    double t0 = __t_now();
    __real_dlacpy_(uplo, m, n, a, lda, b, ldb);
    __stedc_timer_add("dlacpy_", __t_now() - t0);
}
void __wrap_dsteqr_(char *compz, lapack_int *n, double *d, double *e,
                    double *z, lapack_int *ldz, double *work, lapack_int *info)
{
    double t0 = __t_now();
    __real_dsteqr_(compz, n, d, e, z, ldz, work, info);
    __stedc_timer_add("dsteqr_", __t_now() - t0);
}

/* dlaed0 is commonly on DSTEDC path */
void __wrap_dlaed0_(lapack_int *icompq, lapack_int *qsiz, lapack_int *n,
                    double *d, double *e, double *q, lapack_int *ldq,
                    double *qstore, lapack_int *ldqs, double *work,
                    lapack_int *iwork, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed0_(icompq, qsiz, n, d, e, q, ldq, qstore, ldqs, work, iwork, info);
    __stedc_timer_add("dlaed0_", __t_now() - t0);
}

/* ===== exact DLAED7 wrapper ===== */
void __wrap_dlaed7_(lapack_int *icompq, lapack_int *n, lapack_int *qsiz,
                    lapack_int *tlvls,  lapack_int *curlvl, lapack_int *curpbm,
                    double *d, double *q, lapack_int *ldq, lapack_int *indxq,
                    double *rho, lapack_int *cutpnt,
                    double *qstore, lapack_int *qptr, lapack_int *prmptr, lapack_int *perm,
                    lapack_int *givptr, lapack_int *givcol, double *givnum,
                    double *work, lapack_int *iwork, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed7_(icompq, n, qsiz, tlvls, curlvl, curpbm,
                   d, q, ldq, indxq, rho, cutpnt,
                   qstore, qptr, prmptr, perm,
                   givptr, givcol, givnum,
                   work, iwork, info);
    __stedc_timer_add("dlaed7_", __t_now() - t0);
}

/* ===== exact DLAED8 wrapper ===== */
void __wrap_dlaed8_(lapack_int *icompq, lapack_int *k, lapack_int *n,
                    lapack_int *qsiz,
                    double *d, double *q, lapack_int *ldq, lapack_int *indxq,
                    double *rho, lapack_int *cutpnt, double *z, double *dlambda,
                    double *q2, lapack_int *ldq2, double *w, lapack_int *perm,
                    lapack_int *givptr, lapack_int *givcol, double *givnum,
                    lapack_int *indxp, lapack_int *indx, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed8_(icompq, k, n, qsiz,
                   d, q, ldq, indxq,
                   rho, cutpnt, z, dlambda,
                   q2, ldq2, w, perm, givptr, givcol, givnum,
                   indxp, indx, info);
    __stedc_timer_add("dlaed8_", __t_now() - t0);
}

/* ---------------- DLAED1..6,9,A wrappers ---------------- */

void __wrap_dlaed1_(lapack_int *n, double *d, double *q, lapack_int *ldq,
                    lapack_int *indxq, double *rho, lapack_int *cutpnt,
                    double *work, lapack_int *iwork, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed1_(n,d,q,ldq,indxq,rho,cutpnt,work,iwork,info);
    __stedc_timer_add("dlaed1_", __t_now() - t0);
}

void __wrap_dlaed2_(lapack_int *k, lapack_int *n, lapack_int *n1,
                    double *d, double *q, lapack_int *ldq, lapack_int *indxq,
                    double *rho, double *z, double *dlambda, double *w, double *q2,
                    lapack_int *indx, lapack_int *indxc, lapack_int *indxp,
                    lapack_int *coltyp, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed2_(k,n,n1,d,q,ldq,indxq,rho,z,dlambda,w,q2,indx,indxc,indxp,coltyp,info);
    __stedc_timer_add("dlaed2_", __t_now() - t0);
}

void __wrap_dlaed3_(lapack_int *k, lapack_int *n, lapack_int *n1,
                    double *d, double *q, lapack_int *ldq, double *rho,
                    double *dlambda, double *q2, lapack_int *indx, lapack_int *ctot,
                    double *w, double *s, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed3_(k,n,n1,d,q,ldq,rho,dlambda,q2,indx,ctot,w,s,info);
    __stedc_timer_add("dlaed3_", __t_now() - t0);
}

void __wrap_dlaed4_(lapack_int *n, lapack_int *i, double *d, double *z,
                    double *delta, double *rho, double *dlam, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed4_(n,i,d,z,delta,rho,dlam,info);
    __stedc_timer_add("dlaed4_", __t_now() - t0);
}

void __wrap_dlaed5_(lapack_int *i, double *d, double *z,
                    double *delta, double *rho, double *dlam)
{
    double t0 = __t_now();
    __real_dlaed5_(i,d,z,delta,rho,dlam);
    __stedc_timer_add("dlaed5_", __t_now() - t0);
}

void __wrap_dlaed6_(lapack_int *kniter, lapack_int *orgati, double *rho,
                    double *d, double *z, double *finit, double *tau, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed6_(kniter,orgati,rho,d,z,finit,tau,info);
    __stedc_timer_add("dlaed6_", __t_now() - t0);
}

void __wrap_dlaed9_(lapack_int *k, lapack_int *kstart, lapack_int *kstop,
                    lapack_int *n, double *d, double *q, lapack_int *ldq,
                    double *rho, double *dlambda, double *w, double *s,
                    lapack_int *lds, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaed9_(k,kstart,kstop,n,d,q,ldq,rho,dlambda,w,s,lds,info);
    __stedc_timer_add("dlaed9_", __t_now() - t0);
}

void __wrap_dlaeda_(lapack_int *n, lapack_int *tlvls, lapack_int *curlvl, lapack_int *curpbm,
                    lapack_int *prmptr, lapack_int *perm, lapack_int *givptr,
                    lapack_int *givcol, double *givnum,
                    double *q, lapack_int *qptr, double *z, double *ztemp, lapack_int *info)
{
    double t0 = __t_now();
    __real_dlaeda_(n,tlvls,curlvl,curpbm,prmptr,perm,givptr,givcol,givnum,q,qptr,z,ztemp,info);
    __stedc_timer_add("dlaeda_", __t_now() - t0);
}


/* ------ BLAS wrappers (timed) ------ */
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

void __wrap_dgemv_(char *trans, BLAS_INT *m, BLAS_INT *n, double *alpha,
                   double *A, BLAS_INT *lda, double *x, BLAS_INT *incx,
                   double *beta,  double *y, BLAS_INT *incy)
{
    double t0 = __t_now();
    __real_dgemv_(trans, m, n, alpha, A, lda, x, incx, beta, y, incy);
    __stedc_timer_add("dgemv_", __t_now() - t0);
}

void __wrap_dcopy_(BLAS_INT *n, const double *x, BLAS_INT *incx,
                   double *y, BLAS_INT *incy)
{
    double t0 = __t_now();
    __real_dcopy_(n, x, incx, y, incy);
    __stedc_timer_add("dcopy_", __t_now() - t0);
}

void __wrap_dscal_(BLAS_INT *n, const double *alpha, double *x, BLAS_INT *incx)
{
    double t0 = __t_now();
    __real_dscal_(n, alpha, x, incx);
    __stedc_timer_add("dscal_", __t_now() - t0);
}

void __wrap_drot_(BLAS_INT *n, double *x, BLAS_INT *incx, double *y, BLAS_INT *incy,
                  const double *c, const double *s)
{
    double t0 = __t_now();
    __real_drot_(n, x, incx, y, incy, c, s);
    __stedc_timer_add("drot_", __t_now() - t0);
}

void __wrap_cblas_dgemm(int Order, int TransA, int TransB,
                        int M, int N, int K,
                        double alpha, const double *A, int lda,
                        const double *B, int ldb,
                        double beta, double *C, int ldc)
{
    double t0 = __t_now();
    __real_cblas_dgemm(Order, TransA, TransB, M, N, K, alpha, A, lda, B, ldb, beta, C, ldc);
    __stedc_timer_add("cblas_dgemm", __t_now() - t0);
}
void __wrap_cblas_dgemv(int Order, int TransA,
                        int M, int N,
                        double alpha, const double *A, int lda,
                        const double *X, int incX,
                        double beta, double *Y, int incY)
{
    double t0 = __t_now();
    __real_cblas_dgemv(Order, TransA, M, N, alpha, A, lda, X, incX, beta, Y, incY);
    __stedc_timer_add("cblas_dgemv", __t_now() - t0);
}
