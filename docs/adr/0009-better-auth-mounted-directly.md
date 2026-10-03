# 0009 — Better Auth mounted directly; account changes go through audited REST routes

- **Status:** accepted
- **Date:** 2026-10-03

## Context
Phase 3 needs sign-in (email link, passkeys, Google, Microsoft), sessions, workspaces with
roles and invites. Better Auth covers all of it (its organization plugin is a workspace with
members and invitations). NestJS integrations for it are community bridges that may lag NestJS
12, and the organization plugin's own HTTP routes would change members and invites without our
audit log, CSRF check or tenant rules.

## Decision
- Better Auth's handler is mounted on the Express instance under `/api/auth/*`, outside Nest;
  one global Nest guard calls `auth.api.getSession()` (session → active workspace and role →
  CSRF → minimum role).
- The organization plugin is renamed Workspace and Membership in the schema; its own HTTP
  routes are closed. The `/api/v1` controllers (workspaces, members, invites) call `auth.api.*`
  on the server, so every change is validated, audited and CSRF-checked in one place.

## Consequences
- No dependency on a bridge package; upgrading Better Auth is a normal dependency bump.
- New account features are added as `/api/v1` routes, not by opening plugin routes.
- `/api/auth/*` keeps Better Auth's own protections (origin checks, Redis rate limits).
