#define _POSIX_C_SOURCE 200809L

#include "hw_common.h"

extern void dstedc_(const char *compz, const int *n, double *d, double *e,
                    double *z, const int *ldz, double *work, const int *lwork,
                    int *iwork, const int *liwork, int *info);

int main(int argc, char **argv)
{
    const char *desc = "Single-size isolated DSTEDC driver on a DSYTRD-prepared input.";
    run_config_t cfg = parse_run_config(argc, argv, argv[0], desc);
    const char compz = 'I';
    const int n = cfg.n;
    const int ldz = n;

    set_single_thread();

    double *d0 = (double *)xmalloc((size_t)n * sizeof(double));
    double *e0 = (double *)xmalloc((size_t)(n > 1 ? (n - 1) : 1) * sizeof(double));
    double *d = (double *)xmalloc((size_t)n * sizeof(double));
    double *e = (double *)xmalloc((size_t)(n > 1 ? (n - 1) : 1) * sizeof(double));
    double *z = (double *)xmalloc((size_t)n * (size_t)n * sizeof(double));

    reduce_kms_to_tridiagonal(n, cfg.rho, cfg.delta, d0, e0);

    int info = 0;
    int lwork = -1;
    int liwork = -1;
    double wkopt = 0.0;
    int iwkopt = 0;
    memcpy(d, d0, (size_t)n * sizeof(double));
    memcpy(e, e0, (size_t)(n > 1 ? (n - 1) : 1) * sizeof(double));
    make_identity(z, n);
    dstedc_(&compz, &n, d, e, z, &ldz, &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) {
        fprintf(stderr, "dstedc workspace query failed: info=%d\n", info);
        return 4;
    }

    lwork = (int)wkopt;
    if (lwork < 1) lwork = 1;
    liwork = iwkopt;
    if (liwork < 1) liwork = 1;
    double *work = (double *)xmalloc((size_t)lwork * sizeof(double));
    int *iwork = (int *)xmalloc((size_t)liwork * sizeof(int));

    double total_s = 0.0;
    double checksum = 0.0;
    for (int rep = 0; rep < cfg.repeat; ++rep) {
        info = 0;
        memcpy(d, d0, (size_t)n * sizeof(double));
        memcpy(e, e0, (size_t)(n > 1 ? (n - 1) : 1) * sizeof(double));
        make_identity(z, n);
        double t0 = wall_now_s();
        dstedc_(&compz, &n, d, e, z, &ldz, work, &lwork, iwork, &liwork, &info);
        total_s += wall_now_s() - t0;
        if (info != 0) {
            fprintf(stderr, "dstedc failed on repetition %d: info=%d\n", rep, info);
            return 4;
        }
        checksum += checksum_vector(d, n);
    }

    printf("case=dstedc n=%d repeat=%d avg_stage_s=%.6f checksum=%.12e\n",
           n, cfg.repeat, total_s / (double)cfg.repeat, checksum);

    free(iwork);
    free(work);
    free(z);
    free(e);
    free(d);
    free(e0);
    free(d0);
    return 0;
}
