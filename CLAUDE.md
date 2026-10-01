# Sotto — agent context (sotto-platform)

Sotto is a privacy-first SaaS where internal teams upload memos and meeting recordings, then ask questions and get answers with sources. It is built across three private repos that are cloned side by side:

```
~/code/sotto/
├── sotto-platform/   ← this repo: docs hub, Compose stack, Terraform, deploy, later Helm/Argo CD
├── sotto-api/        ← NestJS api, Node worker, Python transcriber, Prisma (pnpm monorepo)
└── sotto-web/        ← Next.js 16 app (product + marketing)
```

## Read these first, in order

1. `docs/STATUS.md` — where the build is right now and the exact next step. **Always start here.**
2. `docs/PLAN.md` — the approved plan: architecture, providers, data model, API, phases, decisions.
3. `docs/BRIEF.md` — the original product and engineering brief (design system, UX rules, quality bar).
4. `docs/adr/` — decisions and why.

Where the plan and the brief disagree, **the plan wins** (it is newer). The main overrides:

- 12 phases (0–11), not 11. The live notetaker is Phase 7; the landing page is Phase 8.
- Every AI capability (chat, embeddings, transcription, diarization, meeting bot) sits behind a swappable provider. Nothing is hard-coded to Ollama or any vendor.
- Payments: Paystack first behind `PaymentProvider`; Stripe later.
- Sign-in: magic link, passkeys, Google and Microsoft.
- Development and the always-on demo run on AWS (eu-west-2), not the owner's laptop.

## Working rules

- `main` is always deployable. All work goes through a branch and a pull request with green CI. The owner (Akanni, GitHub `harkanni`) merges; agents never merge their own PRs.
- Branch names: `feat/p<phase>-<slice>`, `fix/…`, `chore/…`. Commits: Conventional Commits.
- **Every PR updates `docs/STATUS.md`** in this repo (open PRs, what's done, next step). A PR in sotto-api or sotto-web gets a companion STATUS update here.
- Never commit secrets. Only `.env.example` files. Real values live in local `.env`, GitHub Actions secrets, or AWS SSM Parameter Store (`/sotto/<env>/…`).
- Teaching mode: annotate every Dockerfile, Compose file and Terraform file with short "why" comments. The owner is learning Cloud/Platform Engineering; phases 9–11 are "guide me" by default (task, hints, a way to check — he writes it, the agent reviews).
- Ask before adding any paid service.
- Label every mock; never stub a feature silently.

## This repo's layout

| Path | Holds |
| --- | --- |
| `docs/` | STATUS, PLAN, BRIEF, ADRs, CHANGELOG, runbooks, LEARNING notes |
| `local/` | Docker Compose for the whole stack, built from `../sotto-api` and `../sotto-web` |
| `deploy/demo/` | The Compose + Caddy files the always-on demo server runs |
| `terraform/` | `bootstrap/` (state bucket) and `dev/` (demo + workbench servers, ECR, OIDC, S3, budget) |
| `Taskfile.yml` | Common commands (`task up`, `task down`, `task tf:plan` …) |
