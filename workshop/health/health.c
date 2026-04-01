/*
 * health.c — Reference implementation of the cluar5 health check contract.
 *
 * This file is a STANDALONE EXAMPLE. The actual health check is implemented
 * in c/main.c as part of the application entry point.
 *
 * Purpose: show exactly what --health must do so developers understand the
 * contract when extending it for their specific application.
 *
 * See README.md in this directory for the full contract specification.
 *
 * To compile and test this example:
 *   gcc -o /tmp/health-example workshop/health/health.c
 *   /tmp/health-example --health   # should print OK and exit 0
 *   /tmp/health-example            # should print usage and exit 1
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ── Subsystem check functions ───────────────────────────────────────────────
 *
 * Each function returns 0 on success, non-zero on failure.
 * Add one function per subsystem your application manages.
 *
 * In the real application (c/main.c), these functions have access to
 * the actual runtime state: Gambit GC state, LuaJIT lua_State*, file handles,
 * socket descriptors, etc.
 */

static int check_gambit_runtime(void) {
    /*
     * Real implementation: verify the Gambit GC is not in a broken state.
     * Example: call a trivial Scheme function and verify it returns correctly.
     *   ___ON_THROW(___FIX(0), return 1);
     *   return ___INT(___call(0, scheme_ping_fn));
     */
    return 0; /* stub: always healthy */
}

static int check_lua_state(void) {
    /*
     * Real implementation: verify the LuaJIT lua_State is still valid.
     * Example: push a value and pop it to confirm the stack is functional.
     *   lua_pushboolean(L, 1);
     *   lua_pop(L, 1);
     *   return 0;
     */
    return 0; /* stub: always healthy */
}

static int check_application_invariants(void) {
    /*
     * Application-specific checks go here.
     * Examples:
     *   - Can we write to the database?
     *   - Is the message queue reachable?
     *   - Is a required config value present?
     *
     * Keep this fast (< 1 second). Docker times out health checks.
     */
    return 0; /* stub: always healthy */
}

/* ── Health check entry point ────────────────────────────────────────────────
 *
 * Returns 0 if all subsystems pass, 1 if any fail.
 * Prints "OK" to stdout on success, "UNHEALTHY: <reason>" to stderr on failure.
 */
static int run_health_check(void) {
    if (check_gambit_runtime() != 0) {
        fprintf(stderr, "UNHEALTHY: Gambit runtime failure\n");
        return 1;
    }
    if (check_lua_state() != 0) {
        fprintf(stderr, "UNHEALTHY: LuaJIT state failure\n");
        return 1;
    }
    if (check_application_invariants() != 0) {
        fprintf(stderr, "UNHEALTHY: application invariant failure\n");
        return 1;
    }

    fprintf(stdout, "OK\n");
    return 0;
}

/* ── Main ────────────────────────────────────────────────────────────────────
 * This is how main() in c/main.c handles the --health flag.
 * Everything else (initialization, main loop) follows this block.
 */
int main(int argc, char *argv[]) {
    if (argc == 2 && strcmp(argv[1], "--health") == 0) {
        return run_health_check();
    }

    fprintf(stderr, "Usage: %s --health\n", argv[0]);
    fprintf(stderr, "This is the health check example binary.\n");
    return 1;
}
