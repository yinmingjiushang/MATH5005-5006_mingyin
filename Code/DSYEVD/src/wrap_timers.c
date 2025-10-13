// wrap_timers.c — tiny timing registry + helpers (POSIX clock)
// Features:
//  - auto-register any timer name first seen
//  - summary sorted by total time (desc) + totals
//  - works with your __stedc_timer_add(name, dt)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
    const char *name;
    unsigned long long calls;
    double seconds;
} timer_entry_t;

static timer_entry_t *G_TIMERS = NULL;
static int G_NTIMERS = 0;
static int G_CAP = 0;

/* ---- optional: preseed commonly used names to keep order stable ---- */
static const char *PRESEED[] = {
    /* DSYEVD top + tridiag + tri eigensolvers */
    "dsyevd_","dsytrd_","dorgtr_","dsterf_",
    /* STEDC + helpers */
    "dstedc_","dsteqr_","dlamrg_","dlasrt_","dlacpy_",
    /* D&C subtree */
    "dlaed0_","dlaed1_","dlaed2_","dlaed3_","dlaed4_",
    "dlaed5_","dlaed6_","dlaed7_","dlaed8_","dlaed9_","dlaeda_",
    /* Back-transform chain */
    "dormtr_","dormql_","dormqr_","dlarft_","dlarfb_","dlarf_",
    /* BLAS kernels often on this path */
    "dgemm_","dgemv_","dtrmm_","dtrmv_","dger_","dcopy_","dscal_","drot_",
    /* if your code calls CBLAS directly */
    "cblas_dgemm","cblas_dgemv"
};
static const int N_PRESEED = (int)(sizeof(PRESEED)/sizeof(PRESEED[0]));

static inline double now_sec(void){
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec*1e-9;
}

static void ensure_capacity(int want){
    if (G_CAP >= want) return;
    int ncap = G_CAP ? G_CAP*2 : 32;
    if (ncap < want) ncap = want;
    timer_entry_t *p = (timer_entry_t*)realloc(G_TIMERS, ncap*sizeof(timer_entry_t));
    if (!p){ fprintf(stderr,"[timers] OOM\n"); abort(); }
    G_TIMERS = p; G_CAP = ncap;
}

static int find_index(const char *name){
    for (int i=0;i<G_NTIMERS;++i){
        if (strcmp(G_TIMERS[i].name, name)==0) return i;
    }
    return -1;
}

static int register_name(const char *name){
    ensure_capacity(G_NTIMERS+1);
    G_TIMERS[G_NTIMERS].name = name;        // pointer assumed static literal
    G_TIMERS[G_NTIMERS].calls = 0;
    G_TIMERS[G_NTIMERS].seconds = 0.0;
    return G_NTIMERS++;
}

void __stedc_timer_add(const char *name, double dt){
    int idx = find_index(name);
    if (idx < 0) idx = register_name(name);
    G_TIMERS[idx].calls++;
    G_TIMERS[idx].seconds += dt;
}

/* sort by time desc (simple insertion sort; N is small) */
static void sort_by_time_desc(void){
    for (int i=1;i<G_NTIMERS;++i){
        timer_entry_t key = G_TIMERS[i];
        int j = i-1;
        while (j>=0 && G_TIMERS[j].seconds < key.seconds){
            G_TIMERS[j+1] = G_TIMERS[j];
            --j;
        }
        G_TIMERS[j+1] = key;
    }
}

static void print_summary(void){
    sort_by_time_desc();
    double total = 0.0; unsigned long long total_calls = 0;
    fprintf(stderr, "\n==== DSYEVD Pipeline Timing (wall time) ====\n");
    for (int i=0;i<G_NTIMERS;++i){
        if (!G_TIMERS[i].calls) continue;
        total += G_TIMERS[i].seconds;
        total_calls += G_TIMERS[i].calls;
        fprintf(stderr, "%-10s  calls=%6llu  time=%10.6f s  avg=%9.6f s\n",
                G_TIMERS[i].name,
                G_TIMERS[i].calls,
                G_TIMERS[i].seconds,
                G_TIMERS[i].seconds / (double)G_TIMERS[i].calls);
    }
    fprintf(stderr, "---------------------------------------------\n");
    fprintf(stderr, "TOTAL         calls=%6llu  time=%10.6f s\n", total_calls, total);
    fprintf(stderr, "=============================================\n");
}

__attribute__((constructor))
static void on_start(void){
    (void)now_sec();
    /* preseed (optional) */
    ensure_capacity(N_PRESEED);
    for (int i=0;i<N_PRESEED;++i){
        register_name(PRESEED[i]);
    }
}

__attribute__((destructor))
static void on_exit(void){
    print_summary();
    /* keep memory until process exit */
}
