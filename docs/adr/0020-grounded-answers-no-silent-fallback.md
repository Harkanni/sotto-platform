# 0020 — Grounded, streamed answers; no model means passages, a failure means a failure

- **Status:** accepted
- **Date:** 2026-10-09

## Context
BRIEF §4 asks for answers with numbered citations that open the exact spot, streamed as they
are written, with follow-ups. ADR 0002 and PLAN say providers are swappable and never fall back
silently. The demo has no chat model (STATUS → Open decisions).

## Decision
- **Streaming over POST:** `POST /conversations/:id/messages` answers with Server-Sent Events
  (`start`, `cite`, `token`, `done`, `error`). The answer is saved as it streams, so a closed
  tab finds it later; Stop works from any api instance because it is a saved status the
  stream checks every second.
- **Grounded prompt:** numbered sources inside inert `<source>` tags, rules to answer only from
  them and cite as `[n]`, the last three turns. Citations are renumbered by first use as tokens
  arrive; numbers that aren't sources are dropped. Follow-ups come after a sentinel line and
  never reach the visible text.
- **Which model answers:** `AI_ASK_CHAT`, else `AI_PRIVATE_CHAT`. Its data location decides the
  route badge and which sensitivities it may read (ADR 0019). Workspace modes and keys stay in
  Phase 6.
- **No model, no pretending:** without a chat model the answer is the best passages, labelled
  "Passages only"; nothing is generated. With nothing relevant, Ask says so without a model
  call.
- **No fallback:** a model error is saved with a code and shown with Try again; the question
  is never sent to another model.
- **Chats are private** to the person who asked; rate-limited per person
  (`ASK_RATE_PER_MINUTE`); `ask.asked` is audited without the question's text.

## Consequences
- The demo answers with labelled passages until a hosted model is decided.
- A model that ignores the citation format still produces a readable answer, just with fewer
  sources; the eval set (ADR 0021) watches how often answers cite.
