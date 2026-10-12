# 0027 — Embedding re-index runs beside the live index, as an operator command

- **Status:** accepted
- **Date:** 2026-10-10

## Context
PLAN → Swappable AI providers: changing the embedding model needs a background re-index, with
no downtime (a new index beside the live one, then a swap). PLAN's API table lists `POST
/ai/embeddings/reindex` and `GET /ai/embeddings/indexes` for owners and admins. But the
embedding index is shared by every workspace: one workspace's admin starting a re-index would
spend every tenant's compute and change every tenant's search.

## Decision
- A model that isn't the first starts **BUILDING** (only the very first serves at once). New
  files are embedded with the configured model as they arrive; searches keep using the serving
  index.
- **Re-index** is a worker command (`node dist/reindex-cli.js`, `pnpm reindex`, `task reindex`):
  it embeds every chunk lacking the configured model, keyset by id in small batches, writing
  each workspace's vectors with that workspace, embedders in the cluster only. It can be
  stopped and run again; it carries on where it left off.
- **Swap** (`--swap`) only when the new index covers every chunk, in one statement so there is
  never zero or two serving indexes; the old one is RETIRED, its vectors kept until dropped on
  purpose. The api picks up the new serving index within 30 seconds.
- Workspace admins get the read-only `GET /ai/embeddings/indexes`: which index serves and how
  much of their workspace each covers. `POST /ai/embeddings/reindex` is not exposed.
- Measure first: run the eval set (ADR 0021) against the new model before swapping.

## Consequences
- Moving to a better embedding model is a config change plus one command, with search working
  throughout. Dropping retired vectors is a separate, deliberate step (not built yet).
