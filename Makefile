# tricycler Makefile
#
# [Tricycler] Five standard targets: build-base, dev, stage, prod, debug.
# These map to the five Dockerfiles and are the same in every tricycler stack.
#
# [TS-Example] App-layer targets (install, dev-run, db-*) are Next.js + Prisma specific.
# Replace them with your stack's equivalents when building a new stack.
#
# Container targets (run on host):
#   make build-base   Build the shared Node.js builder image — run this first
#   make dev          Build the dev container image
#   make stage        Build the stage container image
#   make prod         Build the production container image
#   make debug        Build the debug container image
#
# App targets (run inside the dev container):
#   make install      Install dependencies (pnpm install)
#   make dev-run      Start the Next.js dev server (pnpm dev)
#   make db-migrate   Apply pending Prisma migrations (prisma migrate dev)
#   make db-generate  Regenerate Prisma client after schema changes
#
# Utility:
#   make clean        Remove .next/ and node_modules/
#
# [Tricycler] Private repository support:
#   Set GITHUB_TOKEN in your environment to clone from a private repo.
#   GITHUB_TOKEN=ghp_xxxx make stage
#   See workshop/docs/MAKING-YOUR-REPO-PRIVATE.md for setup instructions.

# [Tricycler] PROJECT_NAME and REPO_URL come from PROJECT.conf.
# VERSIONS provides NODE_VERSION and PNPM_VERSION.
include PROJECT.conf
include VERSIONS

# [Tricycler] Required for --mount=type=secret support in Dockerfiles.
export DOCKER_BUILDKIT := 1

# GNU Make does not allow literal commas inside function calls.
comma := ,

# [Tricycler] Pass --secret only when GITHUB_TOKEN is set. Public repos: leave unset.
GITHUB_TOKEN  ?=
_SECRET_FLAG   = $(if $(GITHUB_TOKEN),--secret id=github_token$(comma)env=GITHUB_TOKEN,)

.PHONY: all build-base dev stage prod debug \
        install dev-run db-migrate db-generate clean

# ── Container image targets (host) ────────────────────────────────────────────

# [Tricycler] build-base must run first — all other targets depend on it.
build-base:
	docker build \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		-f workshop/docker/Dockerfile.builder-base \
		-t $(PROJECT_NAME)-builder-base \
		.

dev:
	docker build \
		-f workshop/docker/Dockerfile.dev \
		-t $(PROJECT_NAME)-dev \
		.

stage: build-base
	docker build \
		$(_SECRET_FLAG) \
		--build-arg BASE_IMAGE=$(PROJECT_NAME)-builder-base \
		--build-arg REPO_URL=$(REPO_URL) \
		--build-arg REPO_BRANCH=$(REPO_BRANCH) \
		-f workshop/docker/Dockerfile.stage \
		-t $(PROJECT_NAME)-stage \
		.

prod: build-base
	docker build \
		$(_SECRET_FLAG) \
		--build-arg BASE_IMAGE=$(PROJECT_NAME)-builder-base \
		--build-arg REPO_URL=$(REPO_URL) \
		--build-arg REPO_BRANCH=$(REPO_BRANCH) \
		-f workshop/docker/Dockerfile.prod \
		-t $(PROJECT_NAME)-prod \
		.

debug: build-base
	docker build \
		$(_SECRET_FLAG) \
		--build-arg BASE_IMAGE=$(PROJECT_NAME)-builder-base \
		--build-arg REPO_URL=$(REPO_URL) \
		--build-arg REPO_BRANCH=$(REPO_BRANCH) \
		-f workshop/docker/Dockerfile.debug \
		-t $(PROJECT_NAME)-debug \
		.

# ── App targets (inside dev container) ───────────────────────────────────────
# [TS-Example] These targets are Next.js + Prisma specific.
# Replace with your stack's install/run/migrate commands.

# Install all dependencies from pnpm-lock.yaml.
# Run this after cloning or after adding/removing a package.
install:
	pnpm install

# Start the Next.js development server with hot reload.
# App is available at http://localhost:3000
dev-run:
	pnpm dev

# Apply pending Prisma migrations and update the database schema.
# Run this after pulling changes that include new migrations.
db-migrate:
	pnpm prisma migrate dev

# Regenerate the Prisma client after editing prisma/schema.prisma.
# Required before TypeScript can see new models or fields.
db-generate:
	pnpm prisma generate

# ── Utility ───────────────────────────────────────────────────────────────────

clean:
	rm -rf .next node_modules
