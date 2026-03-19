// wrap_timers.c — tiny timing registry + helpers (POSIX clock)
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
    const char *name;
    unsigned long long calls;
    double seconds;
} timer_entry_t;

// Register symbols you want to summarize
static timer_entry_t G_TIMERS[] = {
    {"dstedc_",0,0.0},
    {"dlaed0_",0,0.0}, {"dlaed1_",0,0.0}, {"dlaed3_",0,0.0},
    {"dlaed4_",0,0.0}, {"dlaed6_",0,0.0}, {"dlaed7_",0,0.0}, {"dlaed8_",0,0.0},
    {"dlamrg_",0,0.0}, {"dlasrt_",0,0.0}, {"dlacpy_",0,0.0}, {"dsteqr_",0,0.0},
};
static const int G_NTIMERS = sizeof(G_TIMERS)/sizeof(G_TIMERS[0]);

static inline double now_sec(void){
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec*1e-9;
}
void __stedc_timer_add(const char *name, double dt){
    for(int i=0;i<G_NTIMERS;++i){
        if(strcmp(G_TIMERS[i].name, name)==0){
            G_TIMERS[i].calls++;
            G_TIMERS[i].seconds += dt;
            return;
        }
    }
}
static void print_summary(void){
    fprintf(stderr, "\n==== STEDC Subroutine Timing (wall time) ====\n");
    for(int i=0;i<G_NTIMERS;++i){
        if(G_TIMERS[i].calls)
            fprintf(stderr, "%-8s  calls=%6llu  time=%10.6f s  avg=%9.6f s\n",
                    G_TIMERS[i].name,
                    G_TIMERS[i].calls,
                    G_TIMERS[i].seconds,
                    G_TIMERS[i].seconds / (double)G_TIMERS[i].calls);
    }
    fprintf(stderr, "=============================================\n");
}
__attribute__((constructor)) static void on_start(void){ (void)now_sec(); }
__attribute__((destructor))  static void on_exit(void){ print_summary(); }
