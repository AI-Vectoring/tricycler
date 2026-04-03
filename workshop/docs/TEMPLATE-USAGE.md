# Using SelfCel as a Project Template

SelfCel is a starting point for self-hosted Next.js projects. Fork it, initialize it with your project name, and start building. The stack is already in place — your job is to direct.

---

## Step 1 — Fork the template on GitHub

1. Go to [github.com/AI-Vectoring/tricycler](https://github.com/AI-Vectoring/tricycler)
2. Click **"Use this template"** → **"Create a new repository"**
3. Name it, set visibility, click **"Create repository"**

---

## Step 2 — Open in VS Code Dev Containers

1. On your new GitHub repository page, click the green **"Code"** button and copy the HTTPS URL
2. Open VS Code and press `Ctrl+Shift+P` → **Dev Containers: Clone Repository in Container Volume** — VS Code will ask you for the URL
3. Paste the URL you just copied and press Enter
4. Wait for the container to build (first time takes a few minutes)

On first launch the container runs `workshop/scripts/rename.sh` automatically. It will prompt:

```
Project name (e.g. my-app):         your-project
GitHub username or org (e.g. acme): your-github-user
```

It renames all references throughout the repo, commits, and pushes. Your project is initialized.

---

## Step 3 — Install dependencies and start

Inside the dev container terminal:

```bash
make install
make dev-run
```

Your app is running at **http://localhost:3000**.

---

## Where to build your project

### Start in `src/app/` — always

`src/app/page.tsx` is your home page. `src/app/layout.tsx` is the root layout shared by every page. Add new pages by creating folders under `src/app/` — each folder with a `page.tsx` becomes a route.

API routes live at `src/app/api/` — each folder with a `route.ts` becomes an endpoint.

### Define your data model in `prisma/schema.prisma`

When your app needs a database table, add it to `prisma/schema.prisma` and run:

```bash
make db-migrate    # creates the migration and applies it
make db-generate   # regenerates the TypeScript client
```

Your models are now available as fully typed objects throughout your app.

### Add components to `src/components/`

Reusable React components live here. Import them anywhere in `src/app/`.

### Add utilities to `src/lib/`

Shared logic — database client, helper functions, constants — lives here. The Prisma client typically lives at `src/lib/db.ts`.

---

## What to keep vs. what to replace

### Keep as-is

| File | Why |
|---|---|
| `workshop/docker/Dockerfile.*` | The container model is the point of the template |
| `workshop/scripts/` | Version management and rename tooling |
| `workshop/health/` | Health check contract |
| `Makefile` | Build automation — extend, don't replace |
| `.devcontainer/devcontainer.json` | VS Code integration |
| `PROJECT.conf`, `VERSIONS` | Already updated by rename.sh |
| `next.config.ts` | `output: 'standalone'` is required for containerized prod |
| `tsconfig.json` | Required by Next.js — modify only if you know why |
| `tailwind.config.ts`, `postcss.config.mjs` | Extend the theme, don't replace the structure |

### Replace with your application

| File | What to do |
|---|---|
| `src/app/page.tsx` | Replace the stub with your home page |
| `src/app/layout.tsx` | Update metadata, fonts, and global styles |
| `src/app/globals.css` | Add your global CSS on top of Tailwind's base |
| `prisma/schema.prisma` | Define your data models here |
| `README.md` | Replace with your project's documentation |

---

## Directory structure

```
/
├── src/
│   ├── app/              ← Next.js App Router (pages, layouts, API routes)
│   ├── components/       ← Reusable React components
│   └── lib/              ← Shared utilities and database client
├── prisma/               ← Prisma schema and migrations
├── public/               ← Static assets (images, fonts, favicon)
├── .devcontainer/        ← VS Code Dev Containers configuration
├── workshop/
│   ├── docker/           ← All Dockerfiles
│   ├── scripts/          ← rename.sh, version management
│   ├── health/           ← Health check contract
│   └── docs/             ← This documentation
├── PROJECT.conf          ← Project name and repository URL
├── VERSIONS              ← Pinned Node.js and pnpm versions
├── package.json          ← Dependencies and scripts
├── next.config.ts        ← Next.js configuration
├── tailwind.config.ts    ← Tailwind CSS configuration
├── tsconfig.json         ← TypeScript configuration
├── Makefile              ← Build automation
└── README.md             ← Your project's documentation
```

---

## Updating dependencies

```bash
# Update Node.js or pnpm versions in VERSIONS
# Then rebuild the base image:
make build-base

# Update npm packages:
pnpm update
# Review the diff, then commit pnpm-lock.yaml
```

Commit `VERSIONS` and `pnpm-lock.yaml` after updating so all future container builds use the same versions.
