# 0016 — File access, unfiled files and the trash

- **Status:** accepted
- **Date:** 2026-10-05

## Context
Phase 4 adds files. PLAN gives a file an optional collection, and ADR 0012 already decides who
can open a collection. Files also need rules where no collection applies (unfiled), and for
the 30-day trash, without ever widening who can see something.

## Decision
- A file in a collection follows the collection (ADR 0012), inside SQL (`fileVisibleTo` reuses
  `visibleTo`); a file you can't open answers 404.
- Unfiled files are like an open collection: everyone in the workspace views them; their owner
  and admins change them. New uploads land in the collection on screen, otherwise unfiled.
- A file still uploading belongs to its uploader alone.
- Trash is `deletedAt`; files are purged with their storage 30 days later. A trashed unfiled
  file is visible only to its owner and admins.
- Deleting a collection moves its files to the trash, unfiled, so a restricted collection's
  files never become visible to everyone.
- Anyone who edits a file may raise its label; lowering it from Restricted is admin-only.
  Deleting for good needs Manage, or ownership with Edit.
- Chunks copy the file's collection and label, rewritten on every move and relabel, so search
  (Phase 5) filters inside SQL too.
- Live events (`GET /events`) are filtered per viewer with the same rules and carry no titles.

## Consequences
- Search and answers (Phase 5) must filter chunks by `collectionId` and `sensitivity` with the
  same rules; the columns are already there.
- Restoring a file from a deleted collection brings it back unfiled; moving it is one action.
