# tricycler

**Your app. Your server. Your rules.**

A production-ready Next.js + TypeScript + Tailwind + Prisma + PostgreSQL template. Clone it, rename it, ship it — on any VPS, without platform dependencies.

---

## What you get

- **One clone** — VS Code builds your full dev environment before you write a line
- **Three containers** — Dev (hot reload), Stage (production build + test tools), Prod (minimal Alpine runtime)
- **Full Next.js stack** — App Router, TypeScript, Tailwind CSS, Prisma ORM, PostgreSQL
- **Standalone build** — `next build` produces a self-contained server, no platform required
- **Health check** — `/api/health` wired up and ready to extend

---

## Quick start

1. Click **"Use this template"** → **"Create a new repository"**
2. Open in VS Code → `Ctrl+Shift+P` → **Dev Containers: Clone Repository in Container Volume**
3. The rename wizard runs automatically — enter your project name and GitHub username
4. Inside the container:

```bash
make install
make dev-run
# → http://localhost:3000
```

See [workshop/docs/GETTING-STARTED.md](workshop/docs/GETTING-STARTED.md) for the full guide.

---

## The three containers

| Container | Purpose | Runtime | Shell |
|---|---|---|---|
| `dev` | Daily development, hot reload | Node.js 22, full toolchain | yes |
| `stage` | Pre-production validation, same build as prod | node:22-bookworm-slim + test tools | yes |
| `prod` | Production runtime | node:22-alpine, nothing extra | no |
| `debug` | Post-incident forensics | node:22-bookworm + clinic.js, 0x | yes (root) |

---

## Directory structure

```
/
├── src/
│   ├── app/              ← Next.js App Router (pages, layouts, API routes)
│   ├── components/       ← React components
│   └── lib/              ← Shared utilities and database client
├── prisma/
│   └── schema.prisma     ← Data model — start here when adding database tables
├── public/               ← Static assets
├── .devcontainer/        ← VS Code Dev Containers configuration
├── workshop/
│   ├── docker/           ← All Dockerfiles
│   ├── scripts/          ← templateInit.sh, version management
│   ├── health/           ← Health check contract
│   └── docs/             ← Full documentation
├── PROJECT.conf          ← Project name and repository URL
├── VERSIONS              ← Pinned Node.js and pnpm versions
├── package.json          ← Dependencies and scripts
└── Makefile              ← Build automation
```

---

## Shipping to production

```bash
make prod
docker run -d \
    --name your-project \
    -p 3000:3000 \
    --cap-drop=ALL \
    --security-opt no-new-privileges:true \
    -e DATABASE_URL=postgresql://... \
    your-project-prod
```

---

## Further reading

- [GETTING-STARTED.md](workshop/docs/GETTING-STARTED.md) — From zero to running in four steps
- [TEMPLATE-USAGE.md](workshop/docs/TEMPLATE-USAGE.md) — What to keep, what to replace
- [DEV-WORKFLOW.md](workshop/docs/DEV-WORKFLOW.md) — Day-to-day development and staging
- [DEBUGGING.md](workshop/docs/DEBUGGING.md) — Node.js profiling and the debug container
- [Philosophy-and-amazingness.md](workshop/docs/Philosophy-and-amazingness.md) — Why tricycler exists
- [CONTRIBUTING.md](workshop/docs/CONTRIBUTING.md) — How to contribute to the template

---

## Get listed!

join tricycler-stack to give your stack some extra visibility. Simply add the `tricycler-stack` topic to your repo, takes <7 seconds...
Step-by-step guide: [workshop/docs/REGISTRY.md](workshop/docs/REGISTRY.md)

[github.com/topics/tricycler-stack](https://github.com/topics/tricycler-stack)

---

## License

MIT
