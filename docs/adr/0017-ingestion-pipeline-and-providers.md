# 0017 — The ingestion pipeline, storage and AI providers in Phase 4

- **Status:** accepted
- **Date:** 2026-10-05

## Context
BRIEF §4 asks for direct-to-storage uploads with pause and resume, transcription of every
browser's recording format, and indexing for answers; PLAN and ADR 0002 ask for swappable
providers and no silent fallback; BRIEF §3 says Restricted content never leaves the cluster.

## Decision
- **Uploads** are S3 multipart with presigned part URLs: the browser sends bytes straight to
  storage, the api never carries them. Resume asks storage which parts it has (ListParts).
  Locally the gateway serves storage at `/s3/` on the app's origin; on AWS the bucket's CORS
  rule allows the site.
- **Storage layout:** `files/<workspace>/<file>/` holds `original.<ext>` and what the pipeline
  derives (`pages.json`, `transcript.json`, `peaks.json`); permanent delete is one prefix.
- **Pipeline:** the api publishes `file.uploaded`; the worker extracts (PDF by page, Word,
  text, Markdown), chunks and embeds, or asks the transcriber; the transcriber normalises with
  ffmpeg and transcribes; the worker stores the transcript, chunks it by time and writes notes.
  Handlers are transport-independent; retries are bounded, failures carry codes, unrecoverable
  messages go to `sotto.dead`. Queues keep their Phase 1 declarations (no arguments).
- **Providers** come from `provider:model` settings: embeddings through any OpenAI-compatible
  server (Ollama by default), faster-whisper for transcription, the private chat model for
  notes. Every vector records its model; each model has its own partial HNSW index.
- **Privacy:** embeddings must be in-cluster (a third-party embedder fails the job); an engine
  outside the cluster refuses Restricted recordings; notes from a non-private model never read
  Restricted files.
- **Honest labels:** without a chat model, notes are rule-based "basic notes"; the mock
  transcription engine's lines say `[mock]`; sample meetings say they have no audio.
- **faster-whisper reads sample arrays** in 20-minute windows, never file paths (its PyAV
  dependency broke in CI), so memory stays bounded on long meetings.

## Consequences
- Moving to vLLM, TEI or a hosted model is a settings change; a new embedding model needs a
  re-index (Phase 6) before it serves searches.
- The demo runs labelled mock engines until its capacity is decided (STATUS).
