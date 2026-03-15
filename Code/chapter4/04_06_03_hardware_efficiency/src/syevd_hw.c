#define _POSIX_C_SOURCE 200809L

#include "hw_common.h"

extern void dsyevd_(const char *jobz, const char *uplo, const int *n,
                    double *a, const int *lda, double *w,
                    double *work, const int *lwork,
                    int *iwork, const int *liwork, int *info);

int main(int argc, char **argv)
{
    const char *desc = "Single-size end-to-end DSYEVD driver for perf/memory measurements.";
    run_config_t cfg = parse_run_config(argc, argv, argv[0], desc);
    const char jobz = 'V';
    const char uplo = 'U';
    const int n = cfg.n;
    const int lda = n;

    set_single_thread();

    size_t nn = (size_t)n * (size_t)n;
    double *a0 = (double *)xmalloc(nn * sizeof(double));
    double *a = (double *)xmalloc(nn * sizeof(double));
    double *w = (double *)xmalloc((size_t)n * sizeof(double));

    fill_kms(a0, n, cfg.rho, cfg.delta);

    int info = 0;
    int lwork = -1;
    int liwork = -1;
    double wkopt = 0.0;
    int iwkopt = 0;
    memcpy(a, a0, nn * sizeof(double));
    dsyevd_(&jobz, &uplo, &n, a, &lda, w, &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) {
        fprintf(stderr, "dsyevd workspace query failed: info=%d\n", info);
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
        memcpy(a, a0, nn * sizeof(double));
        double t0 = wall_now_s();
        dsyevd_(&jobz, &uplo, &n, a, &lda, w, work, &lwork, iwork, &liwork, &info);
        total_s += wall_now_s() - t0;
        if (info != 0) {
            fprintf(stderr, "dsyevd failed on repetition %d: info=%d\n", rep, info);
            return 4;
        }
        checksum += checksum_vector(w, n);
    }

    printf("case=dsyevd n=%d repeat=%d avg_total_s=%.6f checksum=%.12e\n",
           n, cfg.repeat, total_s / (double)cfg.repeat, checksum);

    free(iwork);
    free(work);
    free(w);
    free(a);
    free(a0);
    return 0;
}
