/*
 * main.c — The binding agent.
 *
 * C holds this stack together. It owns the main loop, memory, I/O, signals,
 * and the initialization of both the Gambit and LuaJIT runtimes. It is also
 * the escape hatch: when Lua hits a rough edge, when Scheme needs I/O (it has
 * none by design), when maximum performance is required — C is the answer.
 *
 * All three layers run in the same process. There is no serialization, no IPC,
 * no protocol overhead. Communication between layers happens at RAM speed.
 *
 * C owns:
 *   - main() and the full process lifecycle
 *   - Memory management and signal handling
 *   - All I/O (Gambit delegates this entirely to C by design)
 *   - Initialization and teardown of the Gambit runtime
 *   - Initialization and teardown of the LuaJIT state
 *   - The --health flag (Docker HEALTHCHECK contract)
 *
 * See workshop/health/README.md for the health check contract.
 * See workshop/health/health.c for the reference implementation and comments.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>

/*
 * Uncomment these when integrating Gambit and LuaJIT:
 *
 * #include "gambit.h"
 * #include <luajit-2.1/lua.h>
 * #include <luajit-2.1/lualib.h>
 * #include <luajit-2.1/lauxlib.h>
 */

/* ── Globals ─────────────────────────────────────────────────────────────────
 * Replace these with your actual runtime state once integrating.
 */
static volatile int g_running = 1;

/* ── Signal handling ─────────────────────────────────────────────────────────*/
static void handle_signal(int sig) {
    (void)sig;
    g_running = 0;
}

/* ── Health check ────────────────────────────────────────────────────────────
 * Called when the binary is invoked with --health.
 * Add one check function per subsystem as you build your application.
 * Contract: return 0 (healthy) or non-zero (unhealthy). See workshop/health/
 */
static int check_gambit_runtime(void) {
    /* TODO: verify Gambit GC state is valid */
    return 0;
}

static int check_lua_state(void) {
    /* TODO: verify LuaJIT lua_State* is valid */
    return 0;
}

static int check_application_invariants(void) {
    /* TODO: add your application-specific health checks here */
    return 0;
}

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

/* ── Entry point ─────────────────────────────────────────────────────────────*/
int main(int argc, char *argv[]) {
    /* Health check — must be first, before any initialization */
    if (argc == 2 && strcmp(argv[1], "--health") == 0) {
        return run_health_check();
    }

    /* Signal handling */
    signal(SIGINT,  handle_signal);
    signal(SIGTERM, handle_signal);

    /* TODO: Initialize Gambit runtime
     *   ___setup_params_struct setup_params;
     *   ___setup_params_reset(&setup_params);
     *   ___setup(&setup_params);
     */

    /* TODO: Initialize LuaJIT
     *   lua_State *L = luaL_newstate();
     *   luaL_openlibs(L);
     *   luaL_dofile(L, "lua/main.lua");
     */

    /* TODO: Load Scheme logic
     *   ___load_module(main_bundle);
     */

    fprintf(stdout, "cluar5: starting\n");

    /* Main loop */
    while (g_running) {
        /* TODO: implement your main loop here */
    }

    /* TODO: Cleanup Gambit runtime
     *   ___cleanup();
     */

    /* TODO: Cleanup LuaJIT
     *   lua_close(L);
     */

    fprintf(stdout, "cluar5: stopped\n");
    return 0;
}
