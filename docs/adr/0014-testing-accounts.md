# 0014 — Testing accounts: real Postgres for integration, the API image for the web's E2E

- **Status:** accepted
- **Date:** 2026-10-03

## Context
Tenancy and access rules live in SQL, so mocks would test little. The web's done-when flow
(sign up → workspace → invite → accept → role-restricted access) needs a running API, email and
a database. The repos are private: CI in sotto-web can't check out sotto-api without a token.

## Decision
- sotto-api's integration tests run against a real Postgres from `TEST_DATABASE_URL` (a service
  container in CI, `pnpm deps:up` locally), a fresh database per test file, built from the
  migrations. Not Testcontainers.
- sotto-web's `accounts` CI job pulls the API's arm64 image from ECR (the AWS key CI already
  has), migrates and runs it in production mode beside Postgres (pgvector), Redis and Mailpit,
  and runs `e2e/accounts.spec.ts` on iPhone and desktop. It uses `sotto/api:main`, since API
  PRs merge first; a repo variable `ACCOUNTS_API_TAG` can pin another tag.

## Consequences
- No new secret; the job only runs where ECR is configured.
- A web PR that depends on an unmerged API change goes green after the API PR merges and its
  `images` workflow publishes; the job says so in an annotation until then.
