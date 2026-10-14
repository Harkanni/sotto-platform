# 0032 — The demo's chat model runs on its own GPU server (Qwen3.6-35B-A3B on vLLM)

- **Status:** accepted (refines 0031: the chat model leaves the app server)
- **Date:** 2026-10-13

## Context

ADR 0031 put an 8B model on the app server's CPU. The owner wants answers that read like
ChatGPT or Claude, and that start and stream as quickly: an 8B model is noticeably weaker at
grounded, cited answers, and on a CPU it writes at reading pace at best. Cost is deferred: the
stack is destroyed after each build-and-test session until launch.

## Decision

- A separate **g6e.xlarge** (one NVIDIA L40S, 48 GB) runs **vLLM** serving
  **Qwen3.6-35B-A3B in FP8** (Qwen's official FP8 checkpoint), as `sotto-chat`. It's a
  mixture-of-experts model: 35B parameters of knowledge, about 3B active per word, so it writes
  fast; in Qwen's published results it is close to much larger models on reasoning and
  long-context work.
- **Thinking is off** (`chat_template_kwargs.enable_thinking=false`, sent by the api through
  `AI_OPENAI_COMPATIBLE_CHAT_EXTRA`): answers start immediately. Prefix caching makes
  follow-ups faster still.
- It stays **Private**: the app reaches it over the VPC's private network (port 8000 open only
  to the demo's security group, plus an API key from SSM). Nothing goes to a third party.
- Embeddings (nomic-embed-text, Ollama) and transcription (faster-whisper) stay on the app server.
- `model_server_enabled = false` removes the GPU server; the demo then answers with labelled
  passages only. The model and image are variables, so a better model later is a tfvars change.

## Consequences

- A GPU instance costs about $2 an hour on demand; fine for build-and-test sessions, to revisit
  before launch (stop when idle, Savings Plans, or a smaller GPU with a 4-bit model).
- New AWS accounts have no GPU quota: request "Running On-Demand G and VT instances" ≥ 4 vCPUs in
  eu-west-2 once.
- After each `terraform apply` the model server needs ~10–15 minutes to pull the image and the
  ~37 GB of weights before it answers; Ask says the model is unavailable until then.
- Transcription could move to the GPU later for even faster live transcripts (an amd64 CUDA
  transcriber image).
