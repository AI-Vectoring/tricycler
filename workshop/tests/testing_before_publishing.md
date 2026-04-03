# Testing Before Publishing

This document describes the testing strategy for SelfCel container images before they are merged to main, pushed to GitHub, or published to a registry.

---

## Why We Test

The containers are the product. A broken image is a broken product. These tests exist to catch:

- Packages that failed to install or were removed from upstream
- Build steps (`pnpm install`, `next build`) that completed but don't actually work
- Config changes that broke the compose setup
- Regressions from Dockerfile edits

**Rule:** All tests must pass before any of the following:
- Merging a feature branch into `main`
- Pushing `main` to GitHub
- Publishing images to a registry

---

## Test Suites

Each suite is an independent script. They can be run individually or all at once via `run-all.sh`.

| Script | What it tests |
|---|---|
| `test-dev.sh` | Dev container image — Node.js, pnpm, psql client, hot reload |
| `test-builder.sh` | Builder-base image — pnpm install, next build, standalone output |
| `test-compose.sh` | docker-compose — PostgreSQL sidecar, data persistence |

---

## Running Tests

**All suites at once (recommended before publishing):**
```bash
bash workshop/tests/run-all.sh
```

**Individual suites:**
```bash
bash workshop/tests/test-dev.sh
bash workshop/tests/test-builder.sh
bash workshop/tests/test-compose.sh
```

All scripts must be run from the **repository root**.

Images are built automatically before testing. **Do not skip the build before publishing** — `SKIP_BUILD=1` tests whatever image is currently in Docker's cache, which may be stale if a Dockerfile was changed. Only use it when you are certain the image is up to date:
```bash
# Safe: images were just built, no Dockerfile changes since
SKIP_BUILD=1 bash workshop/tests/test-dev.sh

# NOT safe before publishing — always rebuild first:
bash workshop/tests/run-all.sh
```

---

## Output Format

All scripts use consistent colour-coded output:

- **Blue** — section headers and informational output
- **Green** — test passed
- **Yellow** — warning (test passed with caveats, or skipped)
- **Red** — test failed

A summary at the end shows total passed/warned/failed counts and exits with code `0` (all passed) or `1` (any failures).

---

## What Each Suite Covers

### test-dev.sh

Tests the dev container image by running commands inside it:

1. Node.js is present and reports the expected version
2. `pnpm` is present and reports version
3. `psql` client is present and reports version
4. `git` is present
5. TypeScript compiler (`tsc`) is accessible via pnpm
6. `next` CLI is accessible via pnpm

### test-builder.sh

Tests the builder-base image — the shared Node.js build environment:

1. Node.js is present and reports the expected version
2. `pnpm` is present and reports version
3. `pnpm install` completes successfully against `package.json`
4. `next build` completes successfully
5. `.next/standalone/server.js` exists in the build output
6. `.next/static/` exists in the build output
7. Standalone server starts and responds to `GET /api/health`

### test-compose.sh

Tests the docker-compose setup:

1. `docker compose config` validates without errors
2. PostgreSQL sidecar starts successfully
3. `pg_isready` confirms the server accepts connections
4. Data written to the database persists across container recreation (`docker compose down` + `up`)
5. Cleanup (volumes removed after test)

---

## What Is NOT Tested Here

These are out of scope for this test suite and require manual verification or a running application:

- **Full end-to-end user flows** — requires a browser and a running application
- **VS Code Dev Containers integration** — requires VS Code; cannot be automated here
- **Production/stage/debug containers** — separate test suite needed when those containers change
- **Registry publishing** — not automated; manual push after all tests pass
- **Database migrations** — `prisma migrate deploy` in production requires a live database
