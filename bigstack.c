// bigstack: force a minimum pthread stack size, for games that alloca() too much.
// Build: clang -arch arm64 -arch x86_64 -dynamiclib -O2 -o libbigstack.dylib bigstack.c
// Use:   DYLD_INSERT_LIBRARIES=/path/libbigstack.dylib <game>
// Env:   BIGSTACK_MB   minimum stack size in MiB (default 64)
//        BIGSTACK_LOG  path to append a line per thread created (optional)
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#define DYLD_INTERPOSE(_new, _old) \
    __attribute__((used)) static struct { const void *n, *o; } _interpose_##_old \
    __attribute__((section("__DATA,__interpose"))) = { (const void *)&_new, (const void *)&_old };

static size_t min_stack(void) {
    static size_t sz;
    if (!sz) {
        const char *e = getenv("BIGSTACK_MB");
        long mb = e ? atol(e) : 64;
        sz = (size_t)(mb > 0 ? mb : 64) << 20;
    }
    return sz;
}

static void note(const char *what, size_t asked, size_t got) {
    const char *path = getenv("BIGSTACK_LOG");
    if (!path) return;
    FILE *f = fopen(path, "a");
    if (!f) return;
    fprintf(f, "%s: asked %zu KiB, using %zu KiB\n", what, asked >> 10, got >> 10);
    fclose(f);
}

static int bs_attr_setstacksize(pthread_attr_t *attr, size_t size) {
    size_t want = size < min_stack() ? min_stack() : size;
    note("setstacksize", size, want);
    return pthread_attr_setstacksize(attr, want);
}

static int bs_create(pthread_t *t, const pthread_attr_t *attr,
                     void *(*fn)(void *), void *arg) {
    pthread_attr_t local;
    size_t size = 0;
    if (!attr) {
        pthread_attr_init(&local);
        pthread_attr_getstacksize(&local, &size);
        pthread_attr_setstacksize(&local, min_stack());
        note("create(default)", size, min_stack());
        int r = pthread_create(t, &local, fn, arg);
        pthread_attr_destroy(&local);
        return r;
    }
    void *addr = NULL;
    pthread_attr_getstackaddr(attr, &addr);
    pthread_attr_getstacksize(attr, &size);
    if (!addr && size < min_stack()) {  // leave caller-provided stacks alone
        pthread_attr_setstacksize((pthread_attr_t *)attr, min_stack());
        note("create(attr)", size, min_stack());
    }
    return pthread_create(t, attr, fn, arg);
}

DYLD_INTERPOSE(bs_attr_setstacksize, pthread_attr_setstacksize)
DYLD_INTERPOSE(bs_create, pthread_create)
