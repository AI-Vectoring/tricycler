#!/bin/bash
# rename.sh — First-run template initialization script.
#
# [Tricycler] Fired automatically by .devcontainer/devcontainer.json onCreateCommand.
# Detects whether this is a fresh template clone and, if so, prompts for
# project details then renames all references throughout the repo.
#
# Safe to run multiple times — exits immediately if already initialized.

set -e

# [TS-Example] These three values identify this specific template.
# [Think] rename.sh uses these to detect "is this still an uninitialized clone?"
# and to replace all occurrences in source files. If you fork tricycler under
# a different user/name, update these three values to match.
TEMPLATE_USER="AI-Vectoring"
TEMPLATE_NAME="tricycler"
TEMPLATE_REPO="https://github.com/AI-Vectoring/tricycler.git"

# ── Check if already initialized ────────────────────────────────────────────
# [Tricycler] Safe to re-run: exits immediately if PROJECT.conf no longer matches the template.
if ! grep -q "GITHUB_USER=${TEMPLATE_USER}" PROJECT.conf 2>/dev/null; then
    echo "Project already initialized. Nothing to rename."
    exit 0
fi

# ── Prompt ───────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║       SelfCel — First Run Setup              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "This is a fresh clone of the SelfCel template."
echo "Enter your project details to initialize the repo."
echo ""

read -rp "Project name (e.g. my-app):        " PROJECT_NAME
read -rp "GitHub username or org (e.g. acme): " GITHUB_USER
echo ""

# ── Validate ─────────────────────────────────────────────────────────────────
if [ -z "$PROJECT_NAME" ] || [ -z "$GITHUB_USER" ]; then
    echo "Error: both fields are required. Run this script again to retry."
    exit 1
fi

# Basic name validation — alphanumeric and hyphens only
if ! echo "$PROJECT_NAME" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9-]*$'; then
    echo "Error: project name must be alphanumeric (hyphens allowed, no spaces)."
    exit 1
fi

REPO_URL="https://github.com/${GITHUB_USER}/${PROJECT_NAME}.git"

echo "Initializing: ${TEMPLATE_NAME} → ${PROJECT_NAME}"
echo "Repository:   ${REPO_URL}"
echo ""

# ── Update PROJECT.conf ───────────────────────────────────────────────────────
# [Tricycler] PROJECT.conf is the source of truth for PROJECT_NAME, GITHUB_USER, REPO_URL.
# The Makefile reads it; the Dockerfiles receive it as build args.
sed -i \
    -e "s|^PROJECT_NAME=.*|PROJECT_NAME=${PROJECT_NAME}|" \
    -e "s|^GITHUB_USER=.*|GITHUB_USER=${GITHUB_USER}|" \
    -e "s|^REPO_URL=.*|REPO_URL=${REPO_URL}|" \
    PROJECT.conf

# ── Rename all references in known text files ─────────────────────────────────
# [Tricycler] Targets only committed file types — avoids binary files and .git directory.
# [TS-Example] The file extensions list covers this stack's file types.
# [Think] If your stack has additional file types (e.g. *.py, *.go, *.ex),
# add them to this list so references get renamed everywhere.
find . -not -path './.git/*' -type f \( \
    -name "*.ts"       -o \
    -name "*.tsx"      -o \
    -name "*.mjs"      -o \
    -name "*.prisma"   -o \
    -name "*.md"       -o \
    -name "*.sh"       -o \
    -name "*.json"     -o \
    -name "*.yaml"     -o \
    -name "*.yml"      -o \
    -name "*.conf"     -o \
    -name "Dockerfile*" -o \
    -name "Makefile"   -o \
    -name "VERSIONS"   \
\) | while read -r file; do
    sed -i \
        -e "s|${TEMPLATE_USER}|${GITHUB_USER}|g" \
        -e "s|${TEMPLATE_NAME}|${PROJECT_NAME}|g" \
        -e "s|${TEMPLATE_REPO}|${REPO_URL}|g" \
        "$file"
done

# ── Commit and push ───────────────────────────────────────────────────────────
# [Tricycler] Commits the initialization so repo history shows the starting point.
echo "Committing initialization..."
git add -A
git commit -m "chore: initialize project as ${PROJECT_NAME}"

if git push; then
    PUSH_STATUS="pushed to GitHub"
else
    PUSH_STATUS="PUSH FAILED — run 'git push' manually before continuing"
fi

echo ""
echo "Done. Your project is ready:"
echo "  Name:       ${PROJECT_NAME}"
echo "  Repository: ${REPO_URL}"
echo "  Git:        ${PUSH_STATUS}"
echo "  Next step:  make install && make dev-run"
echo ""
