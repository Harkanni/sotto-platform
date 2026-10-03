# 0012 — Roles and collection access, enforced in SQL

- **Status:** accepted
- **Date:** 2026-10-03

## Context
Brief §4: roles Owner, Admin, Member, Viewer, and collections that can be restricted to people
or roles with View, Edit or Manage. Access must hold for every query, including search and
answers in later phases.

## Decision
- Owners and admins manage every collection, members, invites and access, and read the audit
  log; only owners manage other owners.
- Members create collections (they manage the ones they create) and edit open ones. Viewers
  only ever view, whatever a grant says.
- An open collection is visible to everyone in the workspace; a restricted one only through a
  grant to the person or their role. A grant can raise access, never lower it below the role's.
- Visibility is part of the query (`visibleTo` in sotto-api), never a filter on results; a
  restricted collection you can't open answers 404, so its existence isn't revealed.
- Invite states follow Better Auth's stored values; the API reports `revoked` for canceled and
  `expired` past `expiresAt`. Removing someone drops their personal grants.

## Consequences
- The web mirrors these rules only to hide controls the API would refuse (`src/lib/roles.ts`,
  the access sheet's `effectiveFor`); the API stays the authority.
- Phases 4–5 must reuse `visibleTo` for files, chunks and search, so answers never cite what
  someone can't open.
