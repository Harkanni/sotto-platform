# 0013 — Sample content: real collections, a labelled sample layer scoped to the workspace

- **Status:** accepted
- **Date:** 2026-10-03

## Context
PLAN puts `POST /onboarding/sample-content` (fictional files) in Phase 3, but files only arrive
in Phase 4. Phase 2's screens show a labelled sample layer (memos, meetings, chats) on the web.

## Decision
- Loading sample content creates the four sample collections as real rows ("Board and finance"
  restricted), records their ids on the workspace and in the audit log.
- The fictional documents, meetings and chats stay in the web's labelled sample layer, which
  now follows the workspace: nothing without sample content, and only the documents whose
  collection the API lets you see (`src/lib/sample/scope.ts`, from `/me` and `/collections`).

## Consequences
- Roles and grants can be tried on sample content now, with real enforcement.
- Phase 4 replaces the sample documents with real files in the same collections and deletes
  the sample layer piece by piece; the query hooks keep their names.
