/* wrap_timers_2.c  —  Minimal timing aggregator for DSYEV pipeline
 * Groups: [steqr], [dorgtr], [sytrd], then [others], then TOTAL
 * Public API (used by wrappers):
 *   void __stedc_timer_add(const char *name, double dt);
 *   void __stedc_scope_push(const char *scope);
 *   void __stedc_scope_pop(void);
 *
 * Link this object together with your --wrap based wrappers.
 * Prints summary at process exit (atexit hook).
 */

#define _POSIX_C_SOURCE 200112L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(_WIN32) || defined(_WIN64)
#  define STRNCASECMP _strncasecmp
#else
#  include <strings.h>
#  define STRNCASECMP strncasecmp
#endif

/* ========== configuration ========== */
#ifndef G_NTIMERS
#  define G_NTIMERS 4096
#endif
#ifndef G_NAMECAP
#  define G_NAMECAP 128
#endif
#ifndef G_MAX_STACK
#  define G_MAX_STACK 32
#endif

/* ========== timer store ========== */
typedef struct {
    char   name[G_NAMECAP];
    double seconds;
    unsigned long long calls;
} timer_entry_t;

static timer_entry_t G_TIMERS[G_NTIMERS];
static int           G_USED = 0;

/* scope stack */
static char G_SCOPE_STACK[G_MAX_STACK][G_NAMECAP];
static int  G_SCOPE_DEPTH = 0;

/* ========== tiny utils ========== */
static inline void strlcpy0(char *dst, const char *src, size_t cap){
    if (!cap) return;
    size_t n = strlen(src);
    if (n >= cap) n = cap - 1;
    memcpy(dst, src, n);
    dst[n] = '\0';
}

static int find_timer(const char *name){
    for (int i=0;i<G_USED;++i){
        if (strcmp(G_TIMERS[i].name, name)==0) return i;
    }
    return -1;
}

static int ensure_timer(const char *name){
    int idx = find_timer(name);
    if (idx >= 0) return idx;
    if (G_USED >= G_NTIMERS) return -1;
    strlcpy0(G_TIMERS[G_USED].name, name, G_NAMECAP);
    G_TIMERS[G_USED].seconds = 0.0;
    G_TIMERS[G_USED].calls   = 0ULL;
    return G_USED++;
}

static void add_time(const char *name, double dt){
    int idx = ensure_timer(name);
    if (idx < 0) return;
    G_TIMERS[idx].seconds += dt;
    G_TIMERS[idx].calls   += 1ULL;
}

static int cmp_desc_time(const void *a, const void *b){
    const timer_entry_t *x = (const timer_entry_t*)a;
    const timer_entry_t *y = (const timer_entry_t*)b;
    if (x->seconds < y->seconds) return 1;
    if (x->seconds > y->seconds) return -1;
    return strcmp(x->name, y->name);
}

/* map wrapped root symbol → pretty root group */
static const char *rename_total_if_root(const char *name){
    if (strcmp(name, "dsytrd_") == 0) return "sytrd";
    if (strcmp(name, "dsteqr_") == 0) return "steqr";
    if (strcmp(name, "dorgtr_") == 0) return "dorgtr";
    return name;
}

/* turn "dgemm_" -> "gemm", "dlaev2_" -> "laev2", keep others basic */
static void normalize_child(const char *sym, char out[G_NAMECAP]){
    size_t n = strlen(sym);
    /* strip trailing '_' */
    char buf[G_NAMECAP];
    strlcpy0(buf, sym, G_NAMECAP);
    if (n && buf[n-1]=='_') buf[n-1] = '\0';

    /* common LAPACK/BLAS leading 'd' */
    if ((buf[0]=='d' || buf[0]=='s' || buf[0]=='c' || buf[0]=='z') && buf[1]){
        strlcpy0(out, buf+1, G_NAMECAP);
    } else {
        strlcpy0(out, buf, G_NAMECAP);
    }
}

/* ========== public API ========== */
void __stedc_scope_push(const char *scope){
    if (!scope || !*scope) return;
    if (G_SCOPE_DEPTH >= G_MAX_STACK) return;
    strlcpy0(G_SCOPE_STACK[G_SCOPE_DEPTH], scope, G_NAMECAP);
    G_SCOPE_DEPTH++;
}

void __stedc_scope_pop(void){
    if (G_SCOPE_DEPTH > 0) G_SCOPE_DEPTH--;
}

void __stedc_timer_add(const char *name, double dt){
    if (!name || dt < 0) return;

    /* 1) add to (possibly renamed) root total */
    const char *root = rename_total_if_root(name);
    add_time(root, dt);

    /* 2) if in a scope, also add "scope:child" for non-root children */
    if (G_SCOPE_DEPTH > 0){
        const char *scope = G_SCOPE_STACK[G_SCOPE_DEPTH-1];
        /* do not add scoped line if the root itself is the group name */
        if (strcmp(root, "steqr")!=0 && strcmp(root, "dorgtr")!=0 && strcmp(root, "sytrd")!=0){
            char child[G_NAMECAP];
            normalize_child(name, child);
            char scoped[G_NAMECAP];
            snprintf(scoped, sizeof(scoped), "%s:%s", scope, child);
            add_time(scoped, dt);
        }
    }
}

/* ========== printing ========== */
static void print_group(const char *group){
    /* gather children with prefix "group:" */
    int child_count = 0;
    for (int i=0;i<G_USED;++i){
        if (!G_TIMERS[i].calls) continue;
        const char *nm = G_TIMERS[i].name;
        size_t gl = strlen(group);
        if (strncmp(nm, group, gl)==0 && nm[gl]==':') child_count++;
    }
    timer_entry_t *children = NULL;
    if (child_count) children = (timer_entry_t*)malloc(sizeof(timer_entry_t)*child_count);

    int k=0;
    double root_sec = 0.0;
    unsigned long long root_calls = 0ULL;

    /* root line (exact name match) */
    int ridx = find_timer(group);
    if (ridx >= 0){
        root_sec   = G_TIMERS[ridx].seconds;
        root_calls = G_TIMERS[ridx].calls;
    }

    for (int i=0;i<G_USED;++i){
        if (!G_TIMERS[i].calls) continue;
        const char *nm = G_TIMERS[i].name;
        size_t gl = strlen(group);
        if (strncmp(nm, group, gl)==0 && nm[gl]==':'){
            children[k++] = G_TIMERS[i];
        }
    }
    if (child_count) qsort(children, child_count, sizeof(timer_entry_t), cmp_desc_time);

    fprintf(stderr, "\n[%s]\n", group);
    fprintf(stderr, "  total                      calls=%6llu  time=%10.6f s\n", root_calls, root_sec);
    for (int i=0;i<child_count;++i){
        /* strip "group:" when printing */
        const char *p = strchr(children[i].name, ':');
        const char *pretty = p ? (p+1) : children[i].name;
        fprintf(stderr, "  %-24s  calls=%6llu  time=%10.6f s  avg=%9.6f s\n",
                pretty, children[i].calls, children[i].seconds,
                children[i].seconds / (double)children[i].calls);
    }
    if (children) free(children);
}

static void print_rest_ungrouped(void){
    int count = 0;
    for (int i=0;i<G_USED;++i){
        if (!G_TIMERS[i].calls) continue;
        const char *nm = G_TIMERS[i].name;
        if (strcmp(nm,"steqr")==0 || strcmp(nm,"dorgtr")==0 || strcmp(nm,"sytrd")==0) continue;
        if (strncmp(nm,"steqr:",6)==0 || strncmp(nm,"dorgtr:",7)==0 || strncmp(nm,"sytrd:",6)==0) continue;
        count++;
    }
    if (!count) return;

    timer_entry_t *rest = (timer_entry_t*)malloc(sizeof(timer_entry_t)*count);
    int k=0;
    for (int i=0;i<G_USED;++i){
        if (!G_TIMERS[i].calls) continue;
        const char *nm = G_TIMERS[i].name;
        if (strcmp(nm,"steqr")==0 || strcmp(nm,"dorgtr")==0 || strcmp(nm,"sytrd")==0) continue;
        if (strncmp(nm,"steqr:",6)==0 || strncmp(nm,"dorgtr:",7)==0 || strncmp(nm,"sytrd:",6)==0) continue;
        rest[k++] = G_TIMERS[i];
    }
    qsort(rest, count, sizeof(timer_entry_t), cmp_desc_time);

    fprintf(stderr, "\n[others]\n");
    for (int i=0;i<count;++i){
        fprintf(stderr, "%-26s  calls=%6llu  time=%10.6f s  avg=%9.6f s\n",
                rest[i].name, rest[i].calls, rest[i].seconds,
                rest[i].seconds / (double)rest[i].calls);
    }
    free(rest);
}

static void print_summary(void){
    fprintf(stderr, "\n==== DSYEV Pipeline Timing (wall time) ====\n");
    print_group("steqr");
    print_group("dorgtr");
    print_group("sytrd");

    print_rest_ungrouped();

    double total = 0.0;
    unsigned long long total_calls = 0ULL;
    for (int i=0;i<G_USED;++i){
        if (!G_TIMERS[i].calls) continue;
        total       += G_TIMERS[i].seconds;
        total_calls += G_TIMERS[i].calls;
    }
    fprintf(stderr, "\n---------------------------------------------\n");
    fprintf(stderr, "TOTAL                     calls=%6llu  time=%10.6f s\n", total_calls, total);
    fprintf(stderr, "=============================================\n");
}

/* print once at exit */
static void at_exit_dump(void){
    print_summary();
}

/* register atexit once */
static int ensure_init(void){
    static int inited = 0;
    if (!inited){
        atexit(at_exit_dump);
        inited = 1;
    }
    return 1;
}

/* force constructor to install atexit early (gcc/clang) */
#if defined(__GNUC__) || defined(__clang__)
__attribute__((constructor))
#endif
static void _install_atexit_ctor(void){
    ensure_init();
}
