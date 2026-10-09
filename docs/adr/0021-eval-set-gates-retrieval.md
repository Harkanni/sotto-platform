# 0021 — A fictional eval set gates retrieval changes

- **Status:** accepted
- **Date:** 2026-10-09

## Context
Retrieval quality and access rules regress silently: a tweak to keywords, fusion or chunking
can drop the right passage without any test failing. PLAN asks for an evaluation set before
Ask ships.

## Decision
- `evals/kestrel.ts` (sotto-api) holds questions about the fictional Kestrel Labs sample
  content, worded as people ask them, with the files (and meeting moments) that answer them,
  key answer words, questions only the restricted Board and finance collection answers, and
  unanswerable questions.
- `evals/score.ts` computes recall@1/3/5, MRR, moments found, unanswerable declined, answers
  cited, and checks that a viewer without Board and finance never gets those passages. Gates
  differ by mode (keyword vs hybrid).
- It runs twice: in-process on every test run (mock embeddings, keyword mode), and in the CI
  `evals` job against the built images with real `nomic-embed-text` embeddings from Ollama.
- A viewer leak fails the run whatever the other numbers say.

## Consequences
- Changing thresholds needs a reason in the PR; a lower number is a regression, not a tuning.
- The sample content and the eval set change together.
- The CI job needs room for the Ollama image; it frees runner disk first.
