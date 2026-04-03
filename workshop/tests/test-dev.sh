#!/bin/bash
# test-dev.sh — Smoke tests for the dev container image.
#
# Verifies that all runtimes and tools installed in Dockerfile.dev
# actually work inside the container.
#
# Run from repo root:
#   bash workshop/tests/test-dev.sh
#
# Skip image rebuild (if already up to date):
#   SKIP_BUILD=1 bash workshop/tests/test-dev.sh

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
source workshop/tests/lib.sh

# ── Build ──────────────────────────────────────────────────────────────────────
section "Build"

if [ "${SKIP_BUILD:-0}" = "1" ]; then
  warn "Skipping image build (SKIP_BUILD=1) — using existing ${DEV_IMAGE}"
else
  info "Building ${DEV_IMAGE}..."
  if make dev > /tmp/dev-build.log 2>&1; then
    pass "docker build ${DEV_IMAGE}"
  else
    fail "docker build ${DEV_IMAGE} — see /tmp/dev-build.log"
    summary "Dev container"
    exit 1
  fi
fi

# Helper: run a command inside the dev container and return stdout.
dev_run() {
  docker run --rm "${DEV_IMAGE}" bash -c "$1" 2>/dev/null
}

# ── Node.js ───────────────────────────────────────────────────────────────────
section "Node.js"

source VERSIONS

check_contains "node is present and matches NODE_VERSION" \
  "v${NODE_VERSION}" \
  "$(dev_run 'node --version')"

# ── pnpm ──────────────────────────────────────────────────────────────────────
section "pnpm"

check_contains "pnpm is present and matches PNPM_VERSION" \
  "${PNPM_VERSION}" \
  "$(dev_run 'pnpm --version')"

# ── TypeScript ────────────────────────────────────────────────────────────────
section "TypeScript"

# tsc is a dev dependency — must be accessible via pnpm exec after install.
# We mount the repo into the container to test against the actual package.json.
check_contains "tsc is accessible via pnpm exec" \
  "Version" \
  "$(docker run --rm \
      -v "$(pwd):/app" \
      -w /app \
      "${DEV_IMAGE}" bash -c \
      'pnpm install --frozen-lockfile --silent 2>/dev/null && pnpm exec tsc --version' 2>/dev/null)"

# ── Git ───────────────────────────────────────────────────────────────────────
section "Git"

check_contains "git is present" \
  "git version" \
  "$(dev_run 'git --version')"

# ── PostgreSQL client ─────────────────────────────────────────────────────────
section "PostgreSQL client"

check_contains "psql client present" \
  "PostgreSQL" \
  "$(dev_run 'psql --version')"

# ── Summary ───────────────────────────────────────────────────────────────────
summary "Dev container"
