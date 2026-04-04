#!/bin/bash
# templateInit.sh — First-run template initialization script.
#
# [Tricycler] Fired automatically by .devcontainer/devcontainer.json onCreateCommand.
# Detects whether this is a fresh template clone and, if so, prompts for
# project details then renames all references throughout the repo.
#
# Safe to run multiple times — exits immediately if already initialized.

set -e

# [TS-Example] These three values identify this specific template.
# [Think] templateInit.sh uses these to detect "is this still an uninitialized clone?"
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
echo "║       tricycler — First Run Setup              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "This is a fresh clone of the tricycler template."
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

# ── Local volume preference ───────────────────────────────────────────────────
cat <<EOF

Containerized-only vs Local volume storage

Because tricycler requires several environments, we like to enclose it
completely in a container. This keeps your system clean and secure.
When you are done working, it all goes away with the container. This
means no local copy of any files, which live inside the container ONLY.
If you stop the container, the files are there for you next time. If you
remove the container, the files are gone forever. Because we use a
Github-heavy process, even if you lost the container, your files should
be in GitHub, provided you commit after every session.

- Stop the container   → files are still there next time
- Remove the container → files are gone forever
- Commit frequently, commit after every session.

All that said, this is a purist way of thinking and might not be practical for every
user, hence we can now enable the use of a local volume instead, providing
you a local copy that can be restored even if the container was eliminated.
This means triple redundancy: GitHub, container, local.

EOF
read -rp "Do you want to enable a local volume? (y/N) " LOCAL_VOLUME
echo ""

if [[ "${LOCAL_VOLUME}" =~ ^[Yy]$ ]]; then
    LOCAL_VOLUME_ENABLED=true
else
    LOCAL_VOLUME_ENABLED=false
fi

# ── Update PROJECT.conf with volume preference ────────────────────────────────
if grep -q "^LOCAL_VOLUME=" PROJECT.conf; then
    sed -i "s|^LOCAL_VOLUME=.*|LOCAL_VOLUME=${LOCAL_VOLUME_ENABLED}|" PROJECT.conf
else
    echo "LOCAL_VOLUME=${LOCAL_VOLUME_ENABLED}" >> PROJECT.conf
fi

# ── Configure devcontainer based on volume preference ────────────────────────
if [ "${LOCAL_VOLUME_ENABLED}" = "true" ]; then
    # Add workspaceMount so VS Code binds the local folder into the container
    sed -i '/"workspaceFolder"/a\    "workspaceMount": "source=${localWorkspaceFolder},target=/app,type=bind,consistency=cached",' \
        .devcontainer/devcontainer.json
fi

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
