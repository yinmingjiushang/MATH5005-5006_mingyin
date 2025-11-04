// save as /tmp/check_ob.c
#include <stdio.h>
#include <openblas_config.h>
#include <cblas.h>

int main(void){
    printf("OpenBLAS version : %s\n", OPENBLAS_VERSION);
    printf("OpenBLAS config  : %s\n", openblas_get_config());
#ifdef OPENBLAS_NUM_THREADS
    printf("Compile-time cap : %d\n", OPENBLAS_NUM_THREADS);
#else
    printf("Compile-time cap : (macro not present in header)\n");
#endif
    printf("Runtime threads  : %d\n", openblas_get_num_threads());
    return 0;
}
