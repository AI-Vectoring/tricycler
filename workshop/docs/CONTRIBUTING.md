# Contributing to tricycler

<!-- [Tricycler] This document covers contributions to the template itself, not to projects derived from it. -->

tricycler is a project template. Contributions should improve the template itself — the container model, build pipeline, tooling, and documentation — not implement application logic (that belongs in projects derived from the template).

---

## What belongs here

<!-- [Tricycler] These first items apply to any tricycler stack. -->
- Improvements to the Dockerfiles (security, size, correctness)
- Makefile targets and build improvements
- `workshop/scripts/` tooling (rename, version management)
- Health check contract and reference implementation
- Documentation fixes and improvements
- `.devcontainer/` configuration improvements
<!-- [TS-Example] These items are specific to the Next.js/TypeScript stack. -->
- Next.js, Prisma, or Tailwind configuration improvements that benefit all derived projects

## What does not belong here

- Application-specific pages, components, or API routes
- Prisma models for a specific application's domain
- Features that only make sense for one derived project

---

## Development process

<!-- [Tricycler] This process applies to any tricycler stack. -->
1. Use the **"Use this template"** button to create your own copy (do not fork directly — that preserves history)
2. Make your changes in your copy
3. Test all containers build cleanly:
   ```bash
   make build-base
   make dev
   make stage
   make prod
   make debug
   ```
4. Verify the rename script works on a clean clone
5. Open a pull request against `AI-Vectoring/tricycler`

---

## Conventions

<!-- [Tricycler] These conventions apply to every stack. -->
- Dockerfiles: keep security rationale in comments. Removing a security measure without explanation will be rejected.
- Makefile: targets that run inside a container must be documented with a comment indicating where they run.
- Scripts: `set -e` at the top, quote all variables, validate inputs before acting.
- Documentation: one topic per file, no mixing of template setup with application architecture.

---

## Reporting issues

Open an issue on [github.com/AI-Vectoring/tricycler](https://github.com/AI-Vectoring/tricycler/issues) with:
- Which container is affected (dev / stage / prod / debug / builder-base)
- Docker version if relevant
- Steps to reproduce
