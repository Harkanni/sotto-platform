# 0019 — Hybrid retrieval, with access and sensitivity inside the query

- **Status:** accepted
- **Date:** 2026-10-09

## Context
Ask and search must find passages by meaning and by exact words (names, codes, numbers), and
must never let a person, or a model, see a passage they can't open. BRIEF §3 says Restricted
content never leaves the cluster and Confidential only goes to approved routes. PLAN says
permissions are applied inside retrieval, never filtered afterwards.

## Decision
- **One SQL statement** ranks passages two ways inside the set the person may read: Postgres
  full-text search (a generated `tsv` column, the `simple` configuration, the question's
  light-stemmed keywords OR-ed as prefixes; ties in cover density fall to `ts_rank`, then the id,
  so results are repeatable) and pgvector distance with the question embedded by
  the same model that indexed the files. The two rankings are fused with Reciprocal Rank
  Fusion (k = 60), 40 candidates each.
- **The eligible set is part of the query:** the workspace, files that are Ready and not in the
  trash, collections the person can open (unfiled files included), the chat's scope
  (collection, picked files, documents or meetings), and the sensitivities the answering route
  may read. A second count-only pass reports how many passages were held back as Restricted or
  Confidential, without reading their text.
- **Relevance floor:** a passage needs a keyword hit, or a cosine similarity from a real
  embedding model at or above that model's floor. Floors are measured per model by the eval set
  (nomic-embed-text: 0.65, since unrelated questions reach 0.63 with it; 0.5 for models not yet
  measured; `ASK_MIN_SIMILARITY` overrides). Below that, Ask says it couldn't find it and calls
  no model.
- **Mock embeddings mean keyword mode:** with the labelled hash embedder (tests, the demo),
  vectors aren't used for ranking, and search reports `mode: "keyword"`.
- **Citations are re-checked on read:** a saved answer whose source was trashed, moved or
  restricted shows that citation as no longer available.

## Consequences
- Exact distances within the eligible set are fine at our sizes; a large workspace may need
  the HNSW index with iterative scans (pgvector 0.8) or a filtered candidate pass.
- Changing the embedding model needs a re-index before semantic ranking returns (Phase 6);
  until then retrieval runs in keyword mode rather than mixing models.
- No later code may filter retrieval results after the query to enforce access.
