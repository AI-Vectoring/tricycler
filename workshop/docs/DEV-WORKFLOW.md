# Development Workflow

<!-- [Tricycler] This document covers the three-container development model.
     The container names (dev/stage/prod/debug) and the workflow pattern are universal.
     The specific commands (pnpm, next build, prisma) are [TS-Example]. -->

This document covers day-to-day development, testing, and incident response using the tricycler three-container model.

For initial project setup, see [GETTING-STARTED.md](GETTING-STARTED.md).

---

## The Three Containers

<!-- [Tricycler] This table structure applies to every tricycler stack. The tools column is [TS-Example]. -->

| Container | Build | Tools | User | When to use |
|---|---|---|---|---|
| `dev` | Node.js dev server, hot reload | Full toolchain, editors, psql | appuser | Daily development |
| `stage` | Next.js standalone (same as prod) | curl, wget, jq, bash | appuser (su for root) | Pre-production validation |
| `prod` | Next.js standalone, Alpine runtime | None | appuser | Production runtime |
| `debug` | Next.js standalone, full Debian | clinic.js, 0x, node inspector | root | Post-incident forensics |

---

## 1. Daily Development (dev container)

<!-- [Tricycler] The dev container is managed by VS Code Dev Containers in every stack.
     Source lives in a Docker volume — no local files. -->

The dev container is managed by VS Code Dev Containers. Source code lives in a Docker volume cloned from GitHub — there are no local files involved.

### Starting a session

1. Open VS Code
2. `Ctrl+Shift+P` → **Dev Containers: Clone Repository in Container Volume**
3. Enter your repository URL (from `PROJECT.conf → REPO_URL`)
4. VS Code builds the dev container and opens the workspace

You are now inside the container. The integrated terminal runs inside it.

### The development loop

<!-- [TS-Example] make install = pnpm install. make dev-run = pnpm dev (Next.js hot reload).
     Replace with your stack's install and run commands. -->

```bash
# Install dependencies (first time, or after adding packages)
make install

# Start the dev server with hot reload
make dev-run
# → http://localhost:3000
```

Changes to `src/` are reflected immediately — no restart needed.

### Adding a package

<!-- [TS-Example] pnpm is the package manager for this stack. -->

```bash
# Inside the dev container
pnpm add <package-name>
pnpm add -D <package-name>   # dev dependency
```

<!-- [Think] Commit both package.json and pnpm-lock.yaml — the lockfile is what keeps builds reproducible. -->

Commit both `package.json` and `pnpm-lock.yaml` — the lockfile is what keeps builds reproducible.

### Database changes

<!-- [TS-Example] Prisma is the ORM for this stack. Replace with your stack's migration tool. -->

```bash
# After editing prisma/schema.prisma
make db-migrate    # creates and applies the migration
make db-generate   # regenerates the TypeScript client
```

Migration files are generated in `prisma/migrations/` — commit them alongside the schema change.

### Committing

<!-- [Think] Push before destroying the container — the Docker volume is ephemeral. -->

```bash
git add -A
git commit -m "your message"
git push
```

Push before destroying the container. The Docker volume is ephemeral.

---

## 2. Staging (stage container)

<!-- [Tricycler] Stage = same build as prod, debuggable environment. This applies to every stack. -->

Stage builds the same standalone output as production — identical build command, identical runtime. The only differences: the base image is slightly larger, and test tools are available.

<!-- [TS-Example] node:22-bookworm-slim runtime, Next.js standalone output. -->

```bash
# Build base image (first time, or after VERSIONS changes)
make build-base

# Build and start the stage container
make stage
docker run --rm -it -p 3000:3000 -e DATABASE_URL=postgresql://... my-app-stage

# Inside the stage container — start the server
node server.js
```

### Integration testing

<!-- [TS-Example] curl + jq for testing Next.js API routes. -->

```bash
# Inside stage container — use curl and jq for API testing
curl -s http://localhost:3000/api/health | jq .
curl -s http://localhost:3000/api/your-endpoint | jq .
```

---

## 3. Production (prod container)

<!-- [Tricycler] --cap-drop=ALL and --security-opt no-new-privileges apply to every prod container. -->

```bash
make build-base
make prod
docker run -d \
    --name my-app \
    -p 3000:3000 \
    --cap-drop=ALL \
    --security-opt no-new-privileges:true \
    -e DATABASE_URL=postgresql://... \
    -e NODE_ENV=production \
    my-app-prod
```

<!-- [Tricycler] Prod has no shell — intentional. Use stage to investigate. -->

There is no shell. `docker exec` into a running prod container will fail. This is intentional.

Health status:

```bash
docker inspect --format='{{.State.Health.Status}}' my-app
docker logs my-app   # health check output appears here
```

---

## 4. Forensics Workflow (debug container)

<!-- [Tricycler] Debug = prod build + forensics tools + root. Applies to every stack. -->
<!-- [TS-Example] Port 9229 is the Node.js inspector port. clinic/0x are Node.js profilers. -->

When production behaves unexpectedly, see [DEBUGGING.md](DEBUGGING.md) for the full guide. Quick reference:

```bash
make debug
docker run --rm -it \
    -p 3000:3000 \
    -p 9229:9229 \
    -e DATABASE_URL=postgresql://... \
    my-app-debug

# Inside the debug container — start with inspector enabled
node --inspect=0.0.0.0:9229 server.js

# Or profile with clinic
clinic flame -- node server.js
```

Connect Chrome DevTools to `localhost:9229` for breakpoints, heap snapshots, and call stacks.

---

## 5. Version Management

<!-- [TS-Example] NODE_VERSION and PNPM_VERSION are this stack's runtime versions.
     Replace with your stack's equivalents in VERSIONS. -->

Update Node.js or pnpm versions in `VERSIONS`, then rebuild:

```bash
# Edit VERSIONS — bump NODE_VERSION or PNPM_VERSION
make build-base
make prod
# Test, then commit VERSIONS
```

Update npm packages:

```bash
# Inside dev container
pnpm update
# Review changes, commit pnpm-lock.yaml
```

---

## Makefile Reference

<!-- [Tricycler] The five container targets are universal. -->
<!-- [TS-Example] The app targets (install, dev-run, db-*) are Next.js + Prisma specific. -->

```bash
# Container targets (run on host)
make build-base   # Build the shared Node.js builder image
make dev          # Build dev container image
make stage        # Build stage container image
make prod         # Build production container image
make debug        # Build debug container image

# App targets (run inside dev container)
make install      # Install dependencies (pnpm install)
make dev-run      # Start Next.js dev server
make db-migrate   # Apply pending Prisma migrations
make db-generate  # Regenerate Prisma client after schema changes

# Utility
make clean        # Remove .next/ and node_modules/
```
