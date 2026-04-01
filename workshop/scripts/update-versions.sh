#!/bin/bash
# update-versions.sh — Update VERSIONS file to latest upstream releases.
#
# Run this when check-versions.sh reports outdated packages.
# Shows a diff of what will change and asks for confirmation before writing.
# After updating, rebuild containers: make build-base && make prod (etc.)

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

fetch_github_latest() {
    local repo="$1"
    local strip_prefix="${2:-}"
    curl -sf "https://api.github.com/repos/${repo}/releases/latest" \
        | grep '"tag_name"' | head -1 \
        | sed "s/.*\"tag_name\": \"${strip_prefix}\\(.*\\)\".*/\\1/" \
        || echo "FETCH_FAILED"
}

NEW_LUAJIT=$(fetch_github_latest "openresty/luajit2")
NEW_GAMBIT=$(fetch_github_latest "gambit/gambit")
NEW_GDB=$(fetch_github_latest "bminor/binutils-gdb" "gdb-")
NEW_VALGRIND=$(fetch_github_latest "fredericgermain/valgrind")
NEW_STRACE=$(fetch_github_latest "strace/strace" "v")
NEW_TCPDUMP=$(fetch_github_latest "the-tcpdump-group/tcpdump" "tcpdump-")

# ── Show diff ─────────────────────────────────────────────────────────────────
echo "Proposed changes:"
echo ""

CHANGES=0
show_change() {
    local name="$1" current="$2" new="$3"
    if [ "$current" != "$new" ] && [ "$new" != "FETCH_FAILED" ]; then
        printf "  %-22s %s  →  %s\n" "$name" "$current" "$new"
        CHANGES=$((CHANGES+1))
    elif [ "$new" = "FETCH_FAILED" ]; then
        printf "  %-22s %s  (fetch failed — skipping)\n" "$name" "$current"
    else
        printf "  %-22s %s  (no change)\n" "$name" "$current"
    fi
}

show_change "LUAJIT_VERSION"   "$LUAJIT_VERSION"   "$NEW_LUAJIT"
show_change "GAMBIT_VERSION"   "$GAMBIT_VERSION"   "$NEW_GAMBIT"
show_change "GDB_VERSION"      "$GDB_VERSION"      "$NEW_GDB"
show_change "VALGRIND_VERSION" "$VALGRIND_VERSION" "$NEW_VALGRIND"
show_change "STRACE_VERSION"   "$STRACE_VERSION"   "$NEW_STRACE"
show_change "TCPDUMP_VERSION"  "$TCPDUMP_VERSION"  "$NEW_TCPDUMP"

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

update_version "LUAJIT_VERSION"   "$NEW_LUAJIT"
update_version "GAMBIT_VERSION"   "$NEW_GAMBIT"
update_version "GDB_VERSION"      "$NEW_GDB"
update_version "VALGRIND_VERSION" "$NEW_VALGRIND"
update_version "STRACE_VERSION"   "$NEW_STRACE"
update_version "TCPDUMP_VERSION"  "$NEW_TCPDUMP"

echo ""
echo "VERSIONS updated. Next steps:"
echo "  1. Review the changes:  git diff VERSIONS"
echo "  2. Rebuild base image:  make build-base"
echo "  3. Test all containers: make stage && make debug"
echo "  4. Commit if clean:     git add VERSIONS && git commit -m 'chore: bump dependency versions'"
echo ""
