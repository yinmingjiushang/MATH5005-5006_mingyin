#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>  // provides clock() and CLOCKS_PER_SEC

/* Fortran LAPACK routine prototype */
extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA,
                    double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

/* Fill a symmetric matrix (column-major order) with test values */
static void fill_symmetric(double *A, int n) {
    for (int j = 0; j < n; ++j) {
        for (int i = 0; i <= j; ++i) {
            double v = (i == j) ? (10.0 + 0.01 * i) : (0.1 * (i + j));
            A[i + j * n] = v;
            A[j + i * n] = v;
        }
    }
}

int main(void) {
    const int n    = 4000;
    const int lda  = n;
    const char jobz = 'V';  // compute eigenvalues and eigenvectors
    const char uplo = 'U';  // use upper triangle

    double *A = (double*)malloc(sizeof(double) * (size_t)n * (size_t)lda);
    double *W = (double*)malloc(sizeof(double) * (size_t)n);
    if (!A || !W) {
        fprintf(stderr, "Allocation failed.\n");
        return 1;
    }
    fill_symmetric(A, n);

    int info = 0, lwork = -1, liwork = -1;
    double wkopt;
    int iwkopt;

    /* Workspace query */
    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) {
        fprintf(stderr, "DSYEVD workspace query failed, INFO=%d\n", info);
        return 2;
    }

    lwork  = (int)wkopt;
    liwork = iwkopt;

    double *WORK  = (double*)malloc(sizeof(double) * (size_t)lwork);
    int    *IWORK = (int*)   malloc(sizeof(int)    * (size_t)liwork);
    if (!WORK || !IWORK) {
        fprintf(stderr, "Workspace allocation failed.\n");
        return 3;
    }

    /* --------- Timing start --------- */
    clock_t start = clock();

    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            WORK, &lwork, IWORK, &liwork, &info);

    clock_t end = clock();
    /* --------- Timing end --------- */

    if (info != 0) {
        fprintf(stderr, "DSYEVD failed, INFO=%d\n", info);
        return 4;
    }

    double elapsed_sec = (double)(end - start) / CLOCKS_PER_SEC;
    printf("DSYEVD computation took %.3f seconds.\n", elapsed_sec);

    /* --------- Write timing to file --------- */
    FILE *f = fopen("../output/time.txt", "w");
    if (f) {
        fprintf(f, "DSYEVD computation took %.3f seconds.\n", elapsed_sec);
        fclose(f);
    } else {
        fprintf(stderr, "Failed to open ../output/time.txt for writing.\n");
    }

    /* Print eigenvalues */
    printf("Eigenvalues:\n");
    for (int i = 0; i < n; ++i) {
        printf("  W[%d] = %.12e\n", i, W[i]);
    }

    /* Optionally print first eigenvector if JOBZ='V' */
    if (jobz == 'V') {
        printf("\nFirst eigenvector (column 0):\n");
        for (int i = 0; i < n; ++i) {
            printf("  v[%d] = %.6e\n", i, A[i]);
        }
    }

    free(IWORK);
    free(WORK);
    free(W);
    free(A);
    return 0;
}
