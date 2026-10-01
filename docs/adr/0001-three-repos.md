# 0001 — Three repos: web, api monorepo, platform

- **Status:** accepted
- **Date:** 2026-10-01

## Context
The owner wants the backend decoupled from the Next.js app, and wants real platform-engineering practice (separate pipelines, images, GitOps).

## Decision
`sotto-web` (Next.js, no database access), `sotto-api` (pnpm monorepo: Nest api, worker, Python transcriber, Prisma), `sotto-platform` (infra, deploy, docs hub).

## Consequences
- Cross-repo changes need paired PRs; the API PR merges first.
- The web app consumes the API only through the committed OpenAPI spec and a generated client.
- `sotto-platform/docs` is the single place for status, plan and decisions.
