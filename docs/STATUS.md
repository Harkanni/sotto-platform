# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-09
**Current phase:** 5 — Ask and search (in progress)

**Demo:** deployed from `main` by the `images` workflows (`terraform output demo_url` prints the address)

## In progress: Phase 5 (Ask and search)

Log: `sotto-web/PHASE_5_PROGRESS.md` (one log for all three repos: requirements, milestones,
next step).

| Repo           | Branch           | PR    | State |
| -------------- | ---------------- | ----- | ----- |
| sotto-api      | `feat/p5-ask`    | draft | M1    |
| sotto-web      | `feat/p5-ask`    | draft | M0    |
| sotto-platform | `docs/p5-status` | draft | M0    |

## Done

- Phase 0 — plan approved with the owner's answers. See `docs/PLAN.md` → Decisions.
- Phase 1 — all three scaffold PRs merged; `images` builds, pushes and deploys from `main`. CI
  authenticates to AWS with an IAM access key (ADR 0007); `deploy-config.yml` uses it too.
- Phase 2 — design system and app shell merged (sotto-web#2, sotto-platform#2). ADR 0008.
- Phase 3 — accounts and workspaces merged (sotto-api#3, sotto-web#3, sotto-platform#3): magic
  link, passkeys, Google/Microsoft (hidden until configured), workspaces, invites, roles,
  collection access in SQL, audit log + CSV, onboarding. ADRs 0009–0015.
- Phase 4 — ingestion and meetings merged (sotto-api#4, sotto-web#4, sotto-platform#4–5):
  uploads, the worker pipeline, the transcriber, meetings, live status, recording, player and
  transcript. ADRs 0016–0017. Log: `sotto-web/PHASE_4_PROGRESS.md`.
- Phase 4 upload fixes merged (sotto-api#5, sotto-platform#6, sotto-web#5): the app's scoped
  S3 key (ADR 0018), storage in `/readyz`, finished uploads never shown as failed.
- Waitlist (separate, live on Render): `harkanni/sotto-waitlist`. Untouched until Phase 8.

## Next step

1. An agent session: continue Phase 5 from **Next steps** in `sotto-web/PHASE_5_PROGRESS.md`.
2. The owner, if not done yet: `terraform apply` in `terraform/dev` (the upload fix's scoped S3
   key and the bucket's CORS rule; see Blockers), then upload a PDF on the demo.

## Blockers and things the owner must do

- [ ] Buy `sotto.ai` (available, not bought). Until then the demo uses `https://<ip>.sslip.io`.
- [ ] Phase 3: create the Google and Microsoft OAuth apps (steps in the Phase 3 PR); until then
      those buttons stay hidden.
- [x] ECR repositories exist: sotto-api's `images` built and deployed `main` on 2026-10-06,
      and sotto-web's `accounts` job pulls `sotto/api:main`.
- [ ] Phase 4 + upload fix: `cd terraform/dev && terraform plan`, then `terraform apply` (if
      not done yet). Expect to **add** `aws_iam_user.app_files`, its policy and access key,
      two `aws_ssm_parameter` (`/sotto/demo/S3_*`), the bucket CORS and lifecycle rules, and
      **change** `aws_iam_role_policy.server` and the `demo/*` config objects; nothing
      destroyed or replaced. Then re-run `deploy-config` from the Actions tab so the server's
      `.env` gets the keys (it fails if the api isn't ready, naming the dependency).
- [ ] Phase 4 decision: the demo server (t4g.medium, 4 GB) has no room for a local chat model
      and is tight for real transcription + embeddings (see the phase log, "Missing
      specifications" 3–4). Default until you decide: labelled mock engines on the demo, real
      ones locally and in CI.
- [ ] Check: `terraform output github_secrets` prints `gh secret set` for `AWS_REGION` and
      `ECR_REGISTRY`, but the workflows read them as **variables** (`vars.`). They work today
      (the variables are set); keep both in sync if you rotate anything.
- [ ] ADR 0007 follow-up: the OIDC Terraform (`terraform/dev/github_oidc.tf`) is unused now.

## Open decisions

- Demo chat provider key (Anthropic, OpenAI or Google) — default: whichever key is added first.
- Meeting bot — default: build the Google Meet bot ourselves (Phase 7).

## Environment facts

- AWS: paid plan, region `eu-west-2` (London). Demo costs ~$35/month; budget alert at $40.
- Demo server: t4g.medium (ARM) → images are built for `linux/arm64` on GitHub's arm64 runners.
- Agent sandbox: no npm/PyPI/apt access and no Docker daemon. CI's `sync` jobs commit lockfiles
  and publish `node_modules` snapshots that `scripts/agent-deps.sh` restores (both app repos).
