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

# ── Tier 1: Core Runtime ─────────────────────────────────────────────────────
echo "Tier 1 — Core Runtime (goes to production):"

LATEST_LUAJIT=$(curl -sf \
    "https://api.github.com/repos/openresty/luajit2/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)".*/\1/' || echo "unavailable")

LATEST_GAMBIT=$(curl -sf \
    "https://api.github.com/repos/gambit/gambit/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)".*/\1/' || echo "unavailable")

check "LuaJIT (OpenResty)" "$LUAJIT_VERSION" "$LATEST_LUAJIT"
check "Gambit"             "$GAMBIT_VERSION"  "$LATEST_GAMBIT"

echo ""
echo "Tier 2 — Debug/Forensics Tools (never shipped to prod):"

LATEST_GDB=$(curl -sf \
    "https://api.github.com/repos/bminor/binutils-gdb/tags" \
    | grep '"name"' | grep 'gdb-' | head -1 \
    | sed 's/.*"name": "gdb-\(.*\)".*/\1/' || echo "unavailable")

LATEST_VALGRIND=$(curl -sf \
    "https://api.github.com/repos/fredericgermain/valgrind/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)".*/\1/' || echo "unavailable")

LATEST_STRACE=$(curl -sf \
    "https://api.github.com/repos/strace/strace/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "v\(.*\)".*/\1/' || echo "unavailable")

LATEST_TCPDUMP=$(curl -sf \
    "https://api.github.com/repos/the-tcpdump-group/tcpdump/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "tcpdump-\(.*\)".*/\1/' || echo "unavailable")

check "GDB"       "$GDB_VERSION"       "$LATEST_GDB"
check "Valgrind"  "$VALGRIND_VERSION"  "$LATEST_VALGRIND"
check "strace"    "$STRACE_VERSION"    "$LATEST_STRACE"
check "tcpdump"   "$TCPDUMP_VERSION"   "$LATEST_TCPDUMP"

echo ""
echo "Result: ${OK} current, ${OUTDATED} outdated."
if [ "$OUTDATED" -gt 0 ]; then
    echo "Run workshop/scripts/update-versions.sh to update the VERSIONS file."
fi
echo ""
