# 0002 — Every AI capability behind a swappable provider

- **Status:** accepted
- **Date:** 2026-10-01

## Context
The owner must be able to move from Ollama to vLLM or a high-end model, and swap the transcriber, without code changes.

## Decision
`packages/ai` defines `ChatProvider`, `EmbeddingProvider`, `TranscriptionProvider`, `DiarizationProvider` and `MeetingBotProvider`, plus a registry. Each adapter declares its capabilities and **where data goes** (`IN_CLUSTER` or `THIRD_PARTY`). Platform defaults come from config; workspace overrides from the database. Embedding changes re-index side by side, one index per model.

## Consequences
- Privacy rules read the adapter's data location, so a new provider can't bypass the Restricted rules.
- No silent fallback from Private to an external model.
- Slightly more indirection on day one; cheaper every upgrade after.
