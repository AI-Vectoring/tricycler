#!/bin/bash
# test-builder.sh — Smoke tests for the builder-base image.
#
# Verifies the Node.js build environment: pnpm install, next build,
# and the presence of the standalone output.
#
# Run from repo root:
#   bash workshop/tests/test-builder.sh
#
# Skip image rebuild:
#   SKIP_BUILD=1 bash workshop/tests/test-builder.sh

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
source workshop/tests/lib.sh

# ── Build ──────────────────────────────────────────────────────────────────────
section "Build"

if [ "${SKIP_BUILD:-0}" = "1" ]; then
  warn "Skipping image build (SKIP_BUILD=1) — using existing ${BUILDER_IMAGE}"
else
  info "Building ${BUILDER_IMAGE}..."
  if make build-base > /tmp/builder-build.log 2>&1; then
    pass "docker build ${BUILDER_IMAGE}"
  else
    fail "docker build ${BUILDER_IMAGE} — see /tmp/builder-build.log"
    summary "Builder base"
    exit 1
  fi
fi

# Helper: run inside builder-base
builder_run() {
  docker run --rm "${BUILDER_IMAGE}" bash -c "$1" 2>/dev/null
}

# ── Node.js and pnpm ──────────────────────────────────────────────────────────
section "Node.js and pnpm"

source VERSIONS

check_contains "node present and matches NODE_VERSION" \
  "v${NODE_VERSION}" \
  "$(builder_run 'node --version')"

check_contains "pnpm present and matches PNPM_VERSION" \
  "${PNPM_VERSION}" \
  "$(builder_run 'pnpm --version')"

# ── pnpm install ──────────────────────────────────────────────────────────────
section "pnpm install"

# Mount the repo into the builder and run pnpm install.
# --frozen-lockfile ensures the lockfile is honoured — same as in Dockerfiles.
BUILD_TMP=$(make_tmpdir)

if docker run --rm \
    -v "$(pwd):/build/app" \
    -w /build/app \
    "${BUILDER_IMAGE}" bash -c \
    'pnpm install --frozen-lockfile' \
    > /tmp/pnpm-install.log 2>&1; then
  pass "pnpm install --frozen-lockfile succeeded"
else
  fail "pnpm install failed — see /tmp/pnpm-install.log"
  summary "Builder base"
  exit 1
fi

# ── next build ────────────────────────────────────────────────────────────────
section "next build"

# Run next build inside the builder with the repo mounted.
# This validates that next.config.ts, tsconfig.json, and all source files
# compile cleanly and produce the standalone output.
if docker run --rm \
    -v "$(pwd):/build/app" \
    -w /build/app \
    -e NODE_ENV=production \
    "${BUILDER_IMAGE}" bash -c \
    'pnpm install --frozen-lockfile --silent && pnpm build' \
    > /tmp/next-build.log 2>&1; then
  pass "next build succeeded"
else
  fail "next build failed — see /tmp/next-build.log"
  summary "Builder base"
  exit 1
fi

# ── Standalone output ─────────────────────────────────────────────────────────
section "Standalone output"

check "server.js exists in .next/standalone/" \
  "0" \
  "$(test -f .next/standalone/server.js && echo 0 || echo 1)"

check ".next/static/ directory exists" \
  "0" \
  "$(test -d .next/static && echo 0 || echo 1)"

# ── Health endpoint ───────────────────────────────────────────────────────────
section "Health endpoint"

# Start the standalone server and hit /api/health.
# The server needs a moment to initialize — poll with retries.
HEALTH_RESULT=$(docker run --rm -d \
    -v "$(pwd)/.next/standalone:/app" \
    -v "$(pwd)/.next/static:/app/.next/static" \
    -v "$(pwd)/public:/app/public" \
    -p 13000:3000 \
    -e NODE_ENV=production \
    -e PORT=3000 \
    -e HOSTNAME=0.0.0.0 \
    node:22-alpine node /app/server.js 2>/dev/null)

SERVER_CID="$HEALTH_RESULT"
HEALTH_OK=0

for i in $(seq 1 10); do
  sleep 1
  RESP=$(curl -sf http://localhost:13000/api/health 2>/dev/null || true)
  if echo "$RESP" | grep -q '"ok":true'; then
    HEALTH_OK=1
    break
  fi
done

docker stop "$SERVER_CID" > /dev/null 2>&1 || true

if [ "$HEALTH_OK" = "1" ]; then
  pass "GET /api/health → {\"ok\":true}"
else
  fail "GET /api/health did not return {\"ok\":true} within 10 seconds"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
summary "Builder base"
