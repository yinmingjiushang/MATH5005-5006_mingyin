// wrap_timers2.c — tiny timing registry + helpers (POSIX clock, thread-safe, sortable)
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <stdint.h>

typedef struct {
    char  *name;
    unsigned long long calls;
    double seconds;
} timer_entry_t;

static timer_entry_t *G_TIMERS = NULL;
static size_t         G_NTIMERS = 0;
static size_t         G_CAP = 0;
static pthread_mutex_t G_LOCK = PTHREAD_MUTEX_INITIALIZER;
static int            G_SORTED_AT_EXIT = 1;

static inline double now_sec(void){
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

static timer_entry_t* get_or_insert_timer(const char *name) {
    pthread_mutex_lock(&G_LOCK);
    for (size_t i=0; i<G_NTIMERS; ++i) {
        if (strcmp(G_TIMERS[i].name, name) == 0) {
            pthread_mutex_unlock(&G_LOCK);
            return &G_TIMERS[i];
        }
    }
    if (G_NTIMERS == G_CAP) {
        size_t new_cap = G_CAP ? (G_CAP * 2) : 32;
        timer_entry_t *p = (timer_entry_t*)realloc(G_TIMERS, new_cap * sizeof(timer_entry_t));
        if (!p) { pthread_mutex_unlock(&G_LOCK); return NULL; }
        G_TIMERS = p; G_CAP = new_cap;
    }
    char *dup = strdup(name);
    if (!dup) { pthread_mutex_unlock(&G_LOCK); return NULL; }
    G_TIMERS[G_NTIMERS].name = dup;
    G_TIMERS[G_NTIMERS].calls = 0;
    G_TIMERS[G_NTIMERS].seconds = 0.0;
    timer_entry_t *ret = &G_TIMERS[G_NTIMERS];
    ++G_NTIMERS;
    pthread_mutex_unlock(&G_LOCK);
    return ret;
}

/* Public API */
void __stedc_timer_add(const char *name, double dt){
    if (!name || dt < 0.0) return;
    timer_entry_t *e = get_or_insert_timer(name);
    if (!e) return;
    pthread_mutex_lock(&G_LOCK);
    e->calls++;
    e->seconds += dt;
    pthread_mutex_unlock(&G_LOCK);
}
double __stedc_now_sec(void) { return now_sec(); }

/* sort comparator */
static int cmp_desc_time(const void *a, const void *b){
    const timer_entry_t *x = (const timer_entry_t*)a;
    const timer_entry_t *y = (const timer_entry_t*)b;
    if (x->seconds < y->seconds) return  1;
    if (x->seconds > y->seconds) return -1;
    return (x->calls < y->calls) ? 1 : (x->calls > y->calls ? -1 : 0);
}

static void print_summary_text(FILE *fp){
    if (!fp) fp = stderr;
    double total = 0.0;
    for (size_t i=0;i<G_NTIMERS;++i) total += G_TIMERS[i].seconds;

    fprintf(fp, "\n==== STEDC Subroutine Timing (wall time, CLOCK_MONOTONIC) ====\n");
    fprintf(fp, "%-14s  %-8s  %-12s  %-12s  %-7s\n",
            "symbol", "calls", "time(s)", "avg(s)", "%total");
    fprintf(fp, "--------------------------------------------------------------\n");
    for (size_t i=0;i<G_NTIMERS;++i){
        if (!G_TIMERS[i].calls) continue;
        double avg = G_TIMERS[i].seconds / (double)G_TIMERS[i].calls;
        double pct = (total > 0.0) ? (100.0 * G_TIMERS[i].seconds / total) : 0.0;
        fprintf(fp, "%-14s  %8llu  %12.6f  %12.6f  %6.2f%%\n",
                G_TIMERS[i].name, G_TIMERS[i].calls, G_TIMERS[i].seconds, avg, pct);
    }
    fprintf(fp, "--------------------------------------------------------------\n");
    fprintf(fp, "%-14s  %8s  %12.6f\n", "TOTAL", "", total);
    fprintf(fp, "==============================================================\n");
}

static void maybe_write_csv(const char *path){
    if (!path || !*path) return;
    FILE *fp = fopen(path, "w");
    if (!fp) return;
    fprintf(fp, "symbol,calls,seconds,avg_seconds,percent\n");
    double total = 0.0;
    for (size_t i=0;i<G_NTIMERS;++i) total += G_TIMERS[i].seconds;
    for (size_t i=0;i<G_NTIMERS;++i){
        if (!G_TIMERS[i].calls) continue;
        double avg = G_TIMERS[i].seconds / (double)G_TIMERS[i].calls;
        double pct = (total > 0.0) ? (100.0 * G_TIMERS[i].seconds / total) : 0.0;
        fprintf(fp, "%s,%llu,%.9f,%.9f,%.5f\n",
                G_TIMERS[i].name, G_TIMERS[i].calls, G_TIMERS[i].seconds, avg, pct);
    }
    fclose(fp);
}

static void print_summary(void){
    pthread_mutex_lock(&G_LOCK);
    if (G_SORTED_AT_EXIT && G_NTIMERS > 1) {
        qsort(G_TIMERS, G_NTIMERS, sizeof(timer_entry_t), cmp_desc_time);
    }
    pthread_mutex_unlock(&G_LOCK);

    print_summary_text(stderr);

    const char *csv = getenv("STEDC_TIMER_CSV");
    if (csv && *csv) maybe_write_csv(csv);
}

/* constructor / destructor — 用唯一名字避免与 glibc on_exit 冲突 */
__attribute__((constructor))
static void __stedc_timers_ctor(void){
    (void)now_sec();
    const char *preset[] = {
        "dstedc_", "dsteqr_",
        "dlaed0_", "dlaed1_", "dlaed2_", "dlaed3_", "dlaed4_", "dlaed5_", "dlaed6_", "dlaed7_", "dlaed8_", "dlaed9_", "dlaeda_",
        "dlamrg_", "dlasrt_", "dlacpy_", "dlaset_", "dlascl_", "dlasr_", "dlartg_",
        "dgemm_", "dgemv_", "daxpy_", "idamax_", "dswap_", "dcopy_", "dscal_", "drot_",
        "cblas_dgemm", "cblas_dgemv"
    };
    size_t n = sizeof(preset)/sizeof(preset[0]);
    for (size_t i=0;i<n;++i) (void)get_or_insert_timer(preset[i]);
}

__attribute__((destructor))
static void __stedc_timers_dtor(void){
    print_summary();
    for (size_t i=0;i<G_NTIMERS;++i) free(G_TIMERS[i].name);
    free(G_TIMERS); G_TIMERS = NULL; G_NTIMERS = G_CAP = 0;
}
