#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>  // ⬅ 新增头文件，提供 clock() 和 CLOCKS_PER_SEC

extern void dsyevd_(const char *JOBZ, const char *UPLO, const int *N,
                    double *A, const int *LDA,
                    double *W,
                    double *WORK, const int *LWORK,
                    int *IWORK, const int *LIWORK,
                    int *INFO);

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
    const char jobz = 'V';
    const char uplo = 'U';

    double *A = (double*)malloc(sizeof(double) * (size_t)n * (size_t)lda);
    double *W = (double*)malloc(sizeof(double) * (size_t)n);
    if (!A || !W) { fprintf(stderr, "alloc failed\n"); return 1; }
    fill_symmetric(A, n);

    int info = 0, lwork = -1, liwork = -1;
    double wkopt;
    int iwkopt;

    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            &wkopt, &lwork, &iwkopt, &liwork, &info);
    if (info != 0) { fprintf(stderr, "DSYEVD workspace query failed, INFO=%d\n", info); return 2; }

    lwork  = (int)wkopt;
    liwork = iwkopt;

    double *WORK  = (double*)malloc(sizeof(double) * (size_t)lwork);
    int    *IWORK = (int*)   malloc(sizeof(int)    * (size_t)liwork);
    if (!WORK || !IWORK) { fprintf(stderr, "workspace alloc failed\n"); return 3; }

    /* --------- 计时开始 --------- */
    clock_t start = clock();

    dsyevd_(&jobz, &uplo, &n, A, &lda, W,
            WORK, &lwork, IWORK, &liwork, &info);

    clock_t end = clock();
    /* --------- 计时结束 --------- */
    /* --------- 计时结束 --------- */


    if (info != 0) { fprintf(stderr, "DSYEVD failed, INFO=%d\n", info); return 4; }

    double elapsed_sec = (double)(end - start) / CLOCKS_PER_SEC;
    printf("DSYEVD computation took %.3f seconds.\n", elapsed_sec);
     /* --------- 写入文件 --------- */
    FILE *f = fopen("../output/time.txt", "w");  // 打开 ../output/time.txt，写模式
    if (f) {
        fprintf(f, "DSYEVD computation took %.3f seconds.\n", elapsed_sec);
        fclose(f);  // 关闭文件，确保数据落盘
    } else {
        fprintf(stderr, "Failed to open ../output/time.txt for writing.\n");
    }


    printf("Eigenvalues:\n");
    for (int i = 0; i < n; ++i) {
        printf("  W[%d] = %.12e\n", i, W[i]);
    }

    if (jobz == 'V') {
        printf("\nFirst eigenvector (column 0):\n");
        for (int i = 0; i < n; ++i) {
            printf("  v[%d] = %.6e\n", i, A[i]);
        }
    }

    free(IWORK); free(WORK); free(W); free(A);
    return 0;
}
