#!/bin/bash
# check-versions.sh — Compare pinned versions in VERSIONS against upstream.
#
# Reports what has changed upstream without modifying anything.
# Run this periodically to decide whether to update.
# To actually update: run update-versions.sh

set -e

VERSIONS_FILE="$(git rev-parse --show-toplevel)/VERSIONS"

if [ ! -f "$VERSIONS_FILE" ]; then
    echo "Error: VERSIONS file not found. Run from inside the repo."
    exit 1
fi

source "$VERSIONS_FILE"

echo ""
echo "Checking upstream versions..."
echo ""

OK=0
OUTDATED=0

check() {
    local name="$1"
    local current="$2"
    local latest="$3"

    if [ "$current" = "$latest" ]; then
        printf "  %-20s current (%s)\n" "$name" "$current"
        OK=$((OK+1))
    else
        printf "  %-20s OUTDATED — pinned: %s  →  latest: %s\n" "$name" "$current" "$latest"
        OUTDATED=$((OUTDATED+1))
    fi
}

# ── Node.js LTS ───────────────────────────────────────────────────────────────
# Fetches the latest LTS major version from the Node.js release index.
LATEST_NODE=$(curl -sf "https://nodejs.org/dist/index.json" \
    | grep -o '"version":"v[^"]*"' \
    | grep -v 'nightly\|rc\|test' \
    | head -20 \
    | awk -F'"' '{print $4}' \
    | while read -r v; do
        major="${v#v}"
        major="${major%%.*}"
        # LTS versions are even-numbered majors
        if [ $((major % 2)) -eq 0 ]; then
            echo "$major"
            break
        fi
    done || echo "unavailable")

# ── pnpm ──────────────────────────────────────────────────────────────────────
LATEST_PNPM=$(curl -sf \
    "https://api.github.com/repos/pnpm/pnpm/releases/latest" \
    | grep '"tag_name"' | head -1 \
    | sed 's/.*"tag_name": "v\([0-9]*\)\..*/\1/' || echo "unavailable")

echo "Runtime:"
check "Node.js (LTS major)" "$NODE_VERSION" "$LATEST_NODE"
check "pnpm (major)"        "$PNPM_VERSION" "$LATEST_PNPM"

echo ""
echo "Result: ${OK} current, ${OUTDATED} outdated."
if [ "$OUTDATED" -gt 0 ]; then
    echo "Run workshop/scripts/update-versions.sh to update the VERSIONS file."
fi
echo ""
