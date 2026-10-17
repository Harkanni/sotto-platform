# 0029 — A live capture belongs to the person listening until it's saved

- **Status:** accepted
- **Date:** 2026-10-12

## Context

A Listen session creates its meeting file at once (source `LIVE`, status `UPLOADING`), so the
call is a real file while it happens. ADR 0016 already says a file still arriving is visible only
to its uploader (admins included). The question was whether a live call should be an exception,
visible to the collection while it's recorded.

## Decision

No exception. While a call is captured, only the person listening sees it: the live screen, its
transcript stream, its notes, `GET /live-sessions`, and Ask scoped to it (`scope.liveSessionId`)
all go through the same file visibility, and everyone else gets 404. They can watch from any of
their own screens. Once it ends it is an ordinary meeting with its collection's access.

## Consequences

- Someone recording a call controls when anyone else can read it; nothing leaks half-finished.
- Shared live viewing ("follow this call with me") would need its own explicit sharing, not a
  loosened rule. It isn't planned.
- Only the starter can send audio, pause, update notes or stop.
