# Health Check Contract

## Overview

The Docker `HEALTHCHECK` in `Dockerfile.prod` calls:

```
/app/cluar5 --health
```

This flag is implemented in `c/main.c`. C owns `main()`, so C owns the health check — it is the only layer with visibility into all running subsystems (Gambit runtime, LuaJIT state, and application-specific state).

---

## Contract

| Exit code | stdout      | stderr               | Meaning                      |
|-----------|-------------|----------------------|------------------------------|
| `0`       | `OK`        | (empty)              | All subsystems healthy        |
| non-zero  | (empty)     | `UNHEALTHY: <reason>`| One or more checks failed     |

Docker reads the exit code. The log output is visible via `docker logs`.

---

## Implementation Location

**Do not implement health checks here.** This directory is documentation only.

The real implementation lives in:

```
c/main.c → run_health_check()
```

The stub in `c/main.c` always returns healthy. Extend `run_health_check()` as you add subsystems to your application.

---

## Reference Implementation

`workshop/health/health.c` is a standalone, compilable example showing the pattern. Build and run it to verify you understand the contract before extending it:

```bash
# Inside the dev container
gcc -o /tmp/health-example workshop/health/health.c
/tmp/health-example --health    # → prints OK, exits 0
echo $?                         # → 0
```

---

## Extending the Health Check

Add one function per subsystem in `c/main.c`:

```c
static int check_my_database(void) {
    /* Try a lightweight read. Return 0 on success, 1 on failure. */
    return db_ping(global_db_handle) == 0 ? 0 : 1;
}
```

Then call it from `run_health_check()`:

```c
static int run_health_check(void) {
    if (check_gambit_runtime() != 0) {
        fprintf(stderr, "UNHEALTHY: Gambit runtime failure\n");
        return 1;
    }
    if (check_my_database() != 0) {
        fprintf(stderr, "UNHEALTHY: database unreachable\n");
        return 1;
    }
    fprintf(stdout, "OK\n");
    return 0;
}
```

---

## Timing

The `HEALTHCHECK` in `Dockerfile.prod` is configured as:

```
--interval=300s --timeout=5s --start-period=10s --retries=3
```

- `--health` must complete in **under 5 seconds** or Docker marks it as failed.
- Keep checks lightweight — a simple ping, not a full integration test.
- Use `--start-period=10s` to give the application time to initialize before checks begin.

Adjust these values in `Dockerfile.prod` to match your application's startup time.
