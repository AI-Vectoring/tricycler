# Getting Started with tricycler

<!-- [Tricycler] This guide applies to any tricycler stack.
     The four steps (template → open in VS Code → initialize → run) are universal. -->
<!-- [TS-Example] The specific commands (make install, make dev-run, pnpm, /api/health)
     are Next.js + TypeScript specific. Replace them when building a different stack. -->

This guide takes you from zero to a running tricycler project in four steps.

---

## What you need

<!-- [Tricycler] These three prerequisites apply to every tricycler stack. -->

- [Docker](https://docs.docker.com/get-docker/) installed and running
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- A GitHub account

That's it. No Node.js. No databases. No local toolchain. Everything runs inside the container.

---

## Step 1 — Create your project from the template

<!-- [Tricycler] "Use this template" on GitHub is how every tricycler stack is cloned. -->

1. Go to **[github.com/AI-Vectoring/tricycler](https://github.com/AI-Vectoring/tricycler)**
2. Click **"Use this template"** → **"Create a new repository"**
3. Give it a name, leave visibility as **Public**, click **"Create repository"**
   *(To make it private later: [MAKING-YOUR-REPO-PRIVATE.md](MAKING-YOUR-REPO-PRIVATE.md))*

You now have your own copy of tricycler on GitHub, ready to become your project.

---

## Step 2 — Open it in VS Code

<!-- [Tricycler] "Clone Repository in Container Volume" is the standard VS Code Dev Containers
     workflow. This approach clones into a Docker volume — no local files needed. -->

1. On your new GitHub repository page, click the green **"Code"** button and copy the HTTPS URL
2. Open **VS Code** and press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
3. Type and select: **Dev Containers: Clone Repository in Container Volume** — VS Code will ask you for the URL
4. Paste the URL you just copied and press Enter
5. VS Code builds the dev container and opens your workspace inside it

First build takes a few minutes — Docker is pulling the base image and installing the development toolchain. Every subsequent open is instant.

---

## Step 3 — Initialize your project

<!-- [Tricycler] The rename wizard (rename.sh) runs automatically on first container start.
     It replaces all "tricycler" references with your project name throughout the repo. -->

The moment the container is ready, a setup wizard runs automatically in the terminal:

```
╔══════════════════════════════════════════════╗
║       tricycler — First Run Setup            ║
╚══════════════════════════════════════════════╝

This is a fresh clone of the tricycler template.
Enter your project details to initialize the repo.

Project name (e.g. my-app):         your-project
GitHub username or org (e.g. acme): your-github-user
```

Type your project name and GitHub username. The wizard:
- Renames all `tricycler` references throughout the repo to your project name
- Updates `PROJECT.conf` with your repository URL
- Commits and pushes the initialization to GitHub

Your repo is now yours. The template is gone. What remains is your project.

---

## Step 4 — Install dependencies and start the dev server

<!-- [TS-Example] make install = pnpm install. make dev-run = Next.js hot reload server.
     Replace these with your stack's equivalents. -->

In the VS Code integrated terminal (which is running *inside* the container):

```bash
make install
make dev-run
```

`make install` runs `pnpm install` — pulls all dependencies from `package.json`.
`make dev-run` starts the Next.js development server with hot reload.

Open your browser at **http://localhost:3000** — your project is running.

```bash
# Verify the health check works:
curl http://localhost:3000/api/health
# → {"ok":true}
```

---

## You're ready. Here's what you have.

<!-- [TS-Example] This directory structure is specific to the Next.js + Prisma stack.
     A different stack would have different source directories. -->

```
your-project/
├── src/
│   ├── app/              ← Next.js App Router — pages, layouts, API routes
│   ├── components/       ← React components
│   └── lib/              ← Shared utilities and database client
├── prisma/
│   └── schema.prisma     ← Your data model — start here when adding database tables
├── public/               ← Static assets (images, fonts, favicon)
└── workshop/             ← Tooling, docs, Dockerfiles. Touch when needed.
```

---

## Where to go next

### Build something

<!-- [TS-Example] Next.js App Router structure. Replace with your stack's equivalent. -->

Open `src/app/page.tsx`. This is your home page — replace the stub with your content. Add pages by creating new folders under `src/app/`. Add API routes at `src/app/api/`.

When you need a database table, define it in `prisma/schema.prisma` and run:

```bash
make db-migrate
```

### Test in staging

<!-- [Tricycler] Testing in stage before prod applies to every stack. -->

When you're ready to validate against the production build:

```bash
make build-base
make stage
docker run --rm -it your-project-stage
# Inside the container:
node server.js
```

The stage container runs the same build as production, with test tools available.

### Ship to production

<!-- [Tricycler] --cap-drop=ALL and --security-opt apply to every prod container. -->
<!-- [TS-Example] your-project-prod, DATABASE_URL, node server.js are this stack specific. -->

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

## Something went wrong?

<!-- [TS-Example] Most of these troubleshooting items are Next.js + pnpm specific. -->

| Problem | Fix |
|---|---|
| `make install` fails | Check internet connectivity inside the container |
| `make dev-run` fails with port conflict | Another process is using port 3000 — stop it or change the port |
| `http://localhost:3000` not reachable | Ensure `forwardPorts` includes `3000` in `.devcontainer/devcontainer.json` |
| Database connection error | Check `DATABASE_URL` is set in your `.env` file |
| Push failed during initialization | Run `git push` manually from the terminal |
| Container won't start | Run `docker system prune` and rebuild |

---

## Further reading

- [TEMPLATE-USAGE.md](TEMPLATE-USAGE.md) — What to keep, what to replace, the full development arc
- [DEV-WORKFLOW.md](DEV-WORKFLOW.md) — Day-to-day development, staging, and forensics
- [DEBUGGING.md](DEBUGGING.md) — Profiling and the debug container
- [MAKING-YOUR-REPO-PRIVATE.md](MAKING-YOUR-REPO-PRIVATE.md) — How to make your repo private
