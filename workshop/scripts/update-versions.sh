#!/bin/bash
# update-versions.sh — Update VERSIONS file to latest upstream releases.
#
# Run this when check-versions.sh reports outdated packages.
# Shows a diff of what will change and asks for confirmation before writing.
# After updating, rebuild containers: make build-base

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
VERSIONS_FILE="${REPO_ROOT}/VERSIONS"

if [ ! -f "$VERSIONS_FILE" ]; then
    echo "Error: VERSIONS file not found."
    exit 1
fi

source "$VERSIONS_FILE"

echo ""
echo "Fetching latest upstream versions..."
echo ""

# ── Node.js LTS ───────────────────────────────────────────────────────────────
NEW_NODE=$(curl -sf "https://nodejs.org/dist/index.json" \
    | grep -o '"version":"v[^"]*"' \
    | grep -v 'nightly\|rc\|test' \
    | head -20 \
    | awk -F'"' '{print $4}' \
    | while read -r v; do
        major="${v#v}"
        major="${major%%.*}"
        if [ $((major % 2)) -eq 0 ]; then
            echo "$major"
            break
        fi
    done || echo "FETCH_FAILED")

# ── pnpm ──────────────────────────────────────────────────────────────────────
NEW_PNPM=$(curl -sf \
    "https://api.github.com/repos/pnpm/pnpm/releases/latest" \
    | grep '"tag_name"' | head -1 \
    | sed 's/.*"tag_name": "v\([0-9]*\)\..*/\1/' || echo "FETCH_FAILED")

# ── Show diff ─────────────────────────────────────────────────────────────────
echo "Proposed changes:"
echo ""

CHANGES=0
show_change() {
    local name="$1" current="$2" new="$3"
    if [ "$current" != "$new" ] && [ "$new" != "FETCH_FAILED" ]; then
        printf "  %-20s %s  →  %s\n" "$name" "$current" "$new"
        CHANGES=$((CHANGES+1))
    elif [ "$new" = "FETCH_FAILED" ]; then
        printf "  %-20s %s  (fetch failed — skipping)\n" "$name" "$current"
    else
        printf "  %-20s %s  (no change)\n" "$name" "$current"
    fi
}

show_change "NODE_VERSION" "$NODE_VERSION" "$NEW_NODE"
show_change "PNPM_VERSION" "$PNPM_VERSION" "$NEW_PNPM"

echo ""

if [ "$CHANGES" -eq 0 ]; then
    echo "Everything is already up to date."
    exit 0
fi

read -rp "Apply these changes to VERSIONS? [y/N] " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted. No changes made."
    exit 0
fi

# ── Update VERSIONS file ──────────────────────────────────────────────────────
update_version() {
    local key="$1" new_val="$2"
    if [ "$new_val" != "FETCH_FAILED" ]; then
        sed -i "s|^${key}=.*|${key}=${new_val}|" "$VERSIONS_FILE"
    fi
}

update_version "NODE_VERSION" "$NEW_NODE"
update_version "PNPM_VERSION" "$NEW_PNPM"

echo ""
echo "VERSIONS updated. Next steps:"
echo "  1. Review the changes:  git diff VERSIONS"
echo "  2. Rebuild base image:  make build-base"
echo "  3. Test containers:     make stage"
echo "  4. Commit if clean:     git add VERSIONS && git commit -m 'chore: bump dependency versions'"
echo ""
