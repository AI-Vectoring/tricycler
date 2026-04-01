# Development Workflow

This document covers day-to-day development, testing, and incident response using the cluar5 four-container model.

For initial project setup, see [TEMPLATE-USAGE.md](TEMPLATE-USAGE.md).

---

## The Four Containers

| Container | Binary | Tools | User | When to use |
|---|---|---|---|---|
| `dev` | gcc debug build (glibc) | Compilers, interpreters, editors | appuser | Daily development |
| `stage` | musl static (same as prod) | Test tools + full toolchain | appuser (su for root) | Pre-production validation |
| `prod` | musl static, stripped | None — scratch image | appuser | Production runtime |
| `debug` | musl static, unstripped + -g | gdb, valgrind, strace, tcpdump | root | Post-incident forensics |

---

## 1. Daily Development (dev container)

The dev container is managed by VS Code Dev Containers. Source code lives in a Docker volume cloned from GitHub — there are no local files involved.

### Starting a session

1. Open VS Code
2. `Ctrl+Shift+P` → **Dev Containers: Clone Repository in Container Volume**
3. Enter your repository URL (from `PROJECT.conf → REPO_URL`)
4. VS Code builds the dev container and opens the workspace

You are now inside the container. The integrated terminal runs inside it.

### The development loop

```bash
# C changes — recompile
make dev-build

# Run the dev binary
make dev-run

# Scheme files (.scm) — run directly with interpreter (no compile step)
gsc r5/main.scm

# Lua files (.lua) — run directly with interpreter (no compile step)
luajit lua/main.lua
```

### Committing

```bash
git add -A
git commit -m "your message"
git push
```

Push before destroying the container. The Docker volume is ephemeral.

---

## 2. Staging (stage container)

Stage builds the same static binary as production — identical musl environment, identical flags. The only differences are: binary is not stripped (stack traces readable), and test tools are available.

```bash
# Build base image (first time, or after VERSIONS changes)
make build-base

# Build and start the stage container
make stage
docker run --rm -it my-app-stage
```

### Recompiling inside stage

The full toolchain is available inside the stage container (copied from builder-base):

```bash
# Inside the stage container
cd /app
make stage-static   # recompile with stage flags
./cluar5            # test the new binary
```

### Integration testing

```bash
# Inside stage container — use curl, netcat, jq for API/network testing
curl -s http://localhost:8080/api | jq .
echo "ping" | nc localhost 9000
```

---

## 3. Production (prod container)

```bash
make build-base
make prod
docker run -d \
    --name my-app \
    --read-only \
    --tmpfs /tmp \
    -p 8080:8080 \
    --cap-drop=ALL \
    --security-opt no-new-privileges:true \
    my-app-prod
```

There is no shell. `docker exec` will fail. This is intentional.

Health status:

```bash
docker inspect --format='{{.State.Health.Status}}' my-app
docker logs my-app   # health check output appears here
```

---

## 4. Forensics Workflow (debug container)

When production crashes:

### Step 1 — Extract artifacts from prod

```bash
mkdir -p ./forensics

# The binary (exact match to what was running)
docker cp my-app:/app/cluar5 ./forensics/cluar5

# Core dump (requires ulimit -c unlimited in the container)
docker cp my-app:/tmp/core ./forensics/core.dump

# Logs
docker logs my-app > ./forensics/app.log 2>&1
```

### Step 2 — Analyze in debug container

```bash
make debug
docker run --rm -it \
    -v $(pwd)/forensics:/forensics \
    my-app-debug

# Inside the debug container:
cd /forensics
gdb ./cluar5 core.dump

# Valgrind (run the unstripped debug binary, not the prod binary)
valgrind --leak-check=full /debug/cluar5

# Trace syscalls
strace -f /debug/cluar5
```

### Key distinction

The debug container ships with `/debug/cluar5` — the **unstripped debug build** (compiled with `-g -O0`). This is what you use with gdb and valgrind. The `./forensics/cluar5` you extracted from prod is stripped and harder to read, but it's the exact binary that crashed. Both are useful.

---

## 5. Version Management

Check whether dependencies have newer upstream releases:

```bash
workshop/scripts/check-versions.sh
```

Update to latest:

```bash
workshop/scripts/update-versions.sh
# Review the diff, then:
make build-base
# Test, then commit VERSIONS
```

---

## Makefile Reference

```bash
make build-base   # Build the shared musl builder image (required first)
make dev          # Build dev container image
make stage        # Build stage container image
make prod         # Build production container image
make debug        # Build debug container image
make dev-build    # Compile debug binary (run inside dev container)
make dev-run      # Compile and run (inside dev container)
make prod-static  # Compile production binary (run inside builder)
make stage-static # Compile stage binary (run inside builder or stage)
make debug-static # Compile debug binary with symbols (run inside builder)
make clean        # Remove build/ output
```
