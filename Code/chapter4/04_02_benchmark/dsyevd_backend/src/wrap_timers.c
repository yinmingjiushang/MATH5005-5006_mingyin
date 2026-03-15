
// wrap_timers.c — timing registry with scoped attribution
// Naming & printing policy:
//  - Root totals renamed pretty: "sytrd", "stedc", "dormtr"
//  - Scoped children as "scope:child" (e.g., "stedc:gemm"); child name normalized
//  - Print order: [stedc], [dormtr], [sytrd], [others], then TOTAL
#define _POSIX_C_SOURCE 200112L

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

/* ===== Scoped attribution (thread-local stack) ===== */
#ifndef STEDC_SCOPE_MAX
#define STEDC_SCOPE_MAX 32
#endif
static __thread const char *G_SCOPE_STACK[STEDC_SCOPE_MAX];
static __thread int G_SCOPE_TOP = 0;

void __stedc_scope_push(const char *scope){
    if (!scope) return;
    if (G_SCOPE_TOP < STEDC_SCOPE_MAX){
        G_SCOPE_STACK[G_SCOPE_TOP++] = scope;
    }
}

void __stedc_scope_pop(void){
    if (G_SCOPE_TOP > 0) --G_SCOPE_TOP;
}

static inline const char* __stedc_scope_peek(void){
    return (G_SCOPE_TOP>0) ? G_SCOPE_STACK[G_SCOPE_TOP-1] : NULL;
}

/* ---- Normalization helpers ---- */
static const char *rename_total_if_root(const char *name){
    /* remap function symbol totals to pretty root names */
    if (strcmp(name, "dsytrd_") == 0) return "sytrd";
    if (strcmp(name, "dstedc_") == 0) return "stedc";
    if (strcmp(name, "dormtr_") == 0) return "dormtr";
    return name;
}

static void normalize_child(char *buf, size_t bufsz, const char *raw){
    /* child short name: strip "cblas_" prefix and trailing '_' */
    const char *p = raw;
    if (strncmp(p, "cblas_", 6) == 0) p += 6;
    /* copy */
    size_t n = 0;
    while (p[n] && n+1 < bufsz) { buf[n] = p[n]; ++n; }
    buf[n] = '\0';
    /* strip trailing '_' */
    size_t L = strlen(buf);
    if (L>0 && buf[L-1] == '_') buf[L-1] = '\0';
}

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
    G_TIMERS[G_NTIMERS].name = name;        // pointer assumed persistent
    G_TIMERS[G_NTIMERS].calls = 0;
    G_TIMERS[G_NTIMERS].seconds = 0.0;
    return G_NTIMERS++;
}

void __stedc_timer_add(const char *raw_name, double dt){
    /* total (with pretty rename for roots) */
    const char *name = rename_total_if_root(raw_name);
    int idx = find_index(name);
    if (idx < 0) idx = register_name(name);
    G_TIMERS[idx].calls++;
    G_TIMERS[idx].seconds += dt;

    /* scoped "scope:child" */
    const char *scope = __stedc_scope_peek();
    if (scope){
        char child[96]; normalize_child(child, sizeof(child), raw_name);
        if (strcmp(child, scope) != 0){  /* avoid "sytrd:sytrd" etc. */
            char key[192]; key[0] = '\0';
            (void)snprintf(key, sizeof(key), "%s:%s", scope, child);
            int j = find_index(key);
            if (j < 0){
                char *heap = (char*)malloc(strlen(key)+1);
                if (heap){
                    strcpy(heap, key);
                    j = register_name(heap);
                } else {
                    j = register_name("oom");
                }
            }
            G_TIMERS[j].calls++;
            G_TIMERS[j].seconds += dt;
        }
    }
}

/* ===== Grouped printing ===== */
static int cmp_desc_time(const void *a, const void *b){
    const timer_entry_t *pa = (const timer_entry_t*)a;
    const timer_entry_t *pb = (const timer_entry_t*)b;
    if (pa->seconds < pb->seconds) return 1;
    if (pa->seconds > pb->seconds) return -1;
    return 0;
}

static void print_group(const char *scope){
    /* root total */
    int root = find_index(scope);
    fprintf(stderr, "\n[%s]\n", scope);
    if (root >= 0 && G_TIMERS[root].calls){
        fprintf(stderr, "%-24s  calls=%6llu  time=%10.6f s  avg=%9.6f s\n",
                G_TIMERS[root].name, G_TIMERS[root].calls, G_TIMERS[root].seconds,
                G_TIMERS[root].seconds / (double)G_TIMERS[root].calls);
    }
    /* collect children "scope:*" */
    int count = 0;
    size_t Ls = strlen(scope);
    for (int i=0;i<G_NTIMERS;++i){
        if (!G_TIMERS[i].calls) continue;
        const char *name = G_TIMERS[i].name;
        if (strncmp(name, scope, Ls)==0 && name[Ls]==':'){
            ++count;
        }
    }
    if (count==0) return;
    timer_entry_t *kids = (timer_entry_t*)malloc(sizeof(timer_entry_t)*count);
    int k=0;
    for (int i=0;i<G_NTIMERS;++i){
        if (!G_TIMERS[i].calls) continue;
        const char *name = G_TIMERS[i].name;
        if (strncmp(name, scope, Ls)==0 && name[Ls]==':'){
            kids[k++] = G_TIMERS[i];
        }
    }
    qsort(kids, count, sizeof(timer_entry_t), cmp_desc_time);
    for (int i=0;i<count;++i){
        fprintf(stderr, "  %-22s  calls=%6llu  time=%10.6f s  avg=%9.6f s\n",
                kids[i].name, kids[i].calls, kids[i].seconds,
                kids[i].seconds / (double)kids[i].calls);
    }
    free(kids);
}

static void print_rest_ungrouped(void){
    /* print all timers that are not part of the three groups (neither root names nor scope:child) */
    int count = 0;
    for (int i=0;i<G_NTIMERS;++i){
        if (!G_TIMERS[i].calls) continue;
        const char *nm = G_TIMERS[i].name;
        if (strcmp(nm,"stedc")==0 || strcmp(nm,"dormtr")==0 || strcmp(nm,"sytrd")==0) continue;
        if (strncmp(nm,"stedc:",6)==0 || strncmp(nm,"dormtr:",7)==0 || strncmp(nm,"sytrd:",6)==0) continue;
        ++count;
    }
    if (!count) return;
    timer_entry_t *rest = (timer_entry_t*)malloc(sizeof(timer_entry_t)*count);
    int k=0;
    for (int i=0;i<G_NTIMERS;++i){
        if (!G_TIMERS[i].calls) continue;
        const char *nm = G_TIMERS[i].name;
        if (strcmp(nm,"stedc")==0 || strcmp(nm,"dormtr")==0 || strcmp(nm,"sytrd")==0) continue;
        if (strncmp(nm,"stedc:",6)==0 || strncmp(nm,"dormtr:",7)==0 || strncmp(nm,"sytrd:",6)==0) continue;
        rest[k++] = G_TIMERS[i];
    }
    qsort(rest, count, sizeof(timer_entry_t), cmp_desc_time);
    fprintf(stderr, "\n[others]\n");
    for (int i=0;i<count;++i){
        fprintf(stderr, "%-24s  calls=%6llu  time=%10.6f s  avg=%9.6f s\n",
                rest[i].name, rest[i].calls, rest[i].seconds,
                rest[i].seconds / (double)rest[i].calls);
    }
    free(rest);
}

static void print_summary(void){
    /* group view */
    fprintf(stderr, "\n==== DSYEVD Pipeline Timing (wall time) ====\n");
    print_group("stedc");
    print_group("dormtr");
    print_group("sytrd");  /* optional last */
    /* other totals */
    print_rest_ungrouped();

    /* grand total */
    double total = 0.0; unsigned long long total_calls = 0;
    for (int i=0;i<G_NTIMERS;++i){
        if (!G_TIMERS[i].calls) continue;
        total += G_TIMERS[i].seconds;
        total_calls += G_TIMERS[i].calls;
    }
    fprintf(stderr, "\n---------------------------------------------\n");
    fprintf(stderr, "TOTAL                     calls=%6llu  time=%10.6f s\n", total_calls, total);
    fprintf(stderr, "=============================================\n");
}

__attribute__((constructor))
static void on_start(void){
    (void)now_sec();
}

__attribute__((destructor))
static void on_exit(void){
    print_summary();
}
