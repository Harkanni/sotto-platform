# 0031 — The demo runs real, private AI on a larger Graviton server

- **Status:** accepted (supersedes the "labelled mocks on the demo" default from Phase 4)
- **Date:** 2026-10-12

## Context

The demo ran on a t4g.medium (2 vCPU, 4 GB) with labelled mock embeddings and transcripts and
no chat model, because nothing else fit. The owner wants the demo to show the real product:
private answers, real transcripts, real notes, live notes in Listen mode.

## Decision

- The demo moves to **m7g.2xlarge** (8 Graviton vCPU, 32 GB) with a 100 GB disk. ARM keeps the
  arm64 images Jenkins already builds. The type is a variable (`demo_instance_type`).
- Everything stays inside the server: an **Ollama** service serves `nomic-embed-text` and a
  Private chat model (`demo_chat_model`, default `llama3.1:8b`, ~5 GB in memory), and the
  transcriber runs **faster-whisper `small`** on the CPU. Ollama reports healthy only after its
  models are pulled; the api and worker wait for it.
- CPU, not GPU: an 8B model at 4-bit runs at a readable pace on 8 Graviton cores, with no GPU
  quota request, x86 images or GPU drivers. A GPU host (g5/g6) is the upgrade if answers must
  be faster or the model larger.
- The address is kept: an Elastic IP the owner allocates once can be passed as
  `demo_eip_allocation_id`, so `terraform destroy`/`apply` no longer changes the sslip.io name
  (and the OAuth redirect URLs that depend on it).

## Consequences

- Cost: about $300 a month running all the time (check the EC2 pricing page for eu-west-2);
  the budget alert moves to $350. Stopping the instance when not demoing saves most of it.
- Existing demo files were embedded with the mock model: after the first deploy, run the
  re-index once (`docker compose run --rm worker node dist/reindex-cli.js --swap`).
- First deploy takes a few extra minutes (models download once into volumes).
