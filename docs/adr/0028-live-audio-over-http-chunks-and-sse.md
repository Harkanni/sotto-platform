# 0028 — Live audio goes up as numbered HTTP chunks; the transcript comes back over SSE

- **Status:** accepted
- **Date:** 2026-10-12

## Context

PLAN's Live notetaker sketches `WS /live-sessions/:id/stream`: audio in, transcript out, over a
WebSocket. Building Listen mode (Phase 7) showed three problems with that:

- Next's rewrites (local development and the demo's same-origin `/api/*`) don't carry WebSocket
  upgrades, so the browser couldn't reach the api's socket on the paths every other request uses.
- A dropped WebSocket loses whatever was in flight. A phone in a meeting room drops Wi-Fi.
- The api has no WebSocket library, and adding one while CI was being moved wasn't possible.

## Decision

- The browser turns audio into 16 kHz mono PCM16 in an AudioWorklet and sends it as numbered
  chunks of about 4 seconds: `POST /live-sessions/:id/audio?seq=n`
  (`application/octet-stream`). The api stores each chunk, counts them in order (a resend is a
  no-op, a gap is `409 CHUNK_GAP`), and transcribes them one at a time per session through the
  transcriber's direct `POST /v1/transcribe`.
- The transcript, notes and status come back over Server-Sent Events,
  `GET /live-sessions/:id/events`, fanned out through Redis so any api process can serve them.
  Each line's event id is `seq.idx`; a reconnect sends `Last-Event-ID` and gets only what it
  missed.
- On End the chunks are joined into one WAV and the file goes through the normal pipeline, so the
  saved meeting gets the full-quality transcript; the live one is a preview.

## Consequences

- Works through the same rewrites and gateway as every other request; no proxy changes.
- Offline is a delay, not a loss: the browser queues chunks (about 30 minutes) and resends.
- Latency is a few seconds (one chunk), which is what per-window transcription gives anyway.
- The Meet bot (later in Phase 7) uses the same chunk API, so there is one ingest path.
- If true streaming recognition is added later, a WebSocket can sit beside this without changing
  the chunk contract.
