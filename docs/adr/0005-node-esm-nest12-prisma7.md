# 0005 — Node 24, ESM, NestJS 12, Prisma 7

- **Status:** accepted
- **Date:** 2026-10-01

## Context
The brief asks for current stable versions. NestJS 12 (Aug 2026) ships ESM packages and Standard Schema validation; Prisma 7 needs a driver adapter and `prisma.config.ts`.

## Decision
- Node 24 LTS, pnpm 10, TypeScript strict, `"type": "module"` with `module: nodenext`.
- NestJS 12 compiled with `tsc`; Zod schemas via Standard Schema validation.
- Prisma 7 with `@prisma/adapter-pg`; vectors via raw SQL.
- Vitest (with SWC so decorator metadata works) for unit tests.

## Consequences
- Relative imports need `.js` extensions.
- If Better Auth's Nest integration lags NestJS 12 in Phase 3, we pin NestJS 11 and supersede this ADR.
