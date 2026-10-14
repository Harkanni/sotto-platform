# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-10 (Phase 6 complete)
**Current phase:** 6 — AI modes, providers and billing (complete, PRs ready for review)

**Demo:** deployed from `main` by Jenkins: each app's `Build and push image` → `Deploy to demo` stages, after every check passes (`terraform output demo_url` prints the address)

## Ready for review: Phase 6 (AI modes, providers and billing)

Log: `sotto-web/PHASE_6_PROGRESS.md` (one log for all three repos: requirements, milestones,
checks run, decisions).

| Repo           | Branch             | PR               | State                                                                                     |
| -------------- | ------------------ | ---------------- | ----------------------------------------------------------------------------------------- |
| sotto-api      | `feat/p6-ai-modes` | sotto-api#7      | Ready: key vault, BYOK adapters, AI settings, gateway, metering, Paystack, re-index       |
| sotto-web      | `feat/p6-ai-modes` | sotto-web#7      | Ready: AI settings, Switch model, Answer with Private, Usage and billing, onboarding step |
| sotto-platform | `docs/p6-status`   | sotto-platform#8 | Ready: ADRs 0023–0027, Compose settings, demo master key (Terraform), this STATUS         |

Merge order: sotto-api#7 first (migration `ai_modes_and_billing`), then sotto-web#7, then this
PR. **CI must run green first**: GitHub Actions is refusing to start jobs (Blockers).

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
- Phase 5 — Ask and search merged (sotto-api#6, sotto-web#6, sotto-platform#7):
  hybrid retrieval with access in SQL, `GET /search`, notes, streamed answers with citations,
  the eval set in CI with real embeddings. ADRs 0019–0022. Log: `sotto-web/PHASE_5_PROGRESS.md`.
- Phase 6 — AI modes, providers and billing, ready for review (sotto-api#7, sotto-web#7,
  sotto-platform#8): Private, BYOK and Managed per workspace; envelope-encrypted keys; model
  catalog and Switch model; Restricted proven never to reach outside AI; metering, quotas and
  plans; Paystack test mode behind `PaymentProvider`; embedding re-index. ADRs 0023–0027.
- CI/CD moved to Jenkins (ADR 0030; sotto-platform#9). Every check now runs in the
  Jenkinsfiles; GitHub Actions is no longer used. A newer push to a branch stops its older
  build (`abortPrevious`; sotto-api, sotto-web and this repo's `chore/jenkins-abort-previous`).
  `terraform destroy` removes everything, ECR included: while the demo is down, Jenkins on
  `main` skips the push and deploy; after `terraform apply`, run **Build** on each app's `main`.
- Jenkins builds run side by side (ADR 0030 update): no shared lock; each build gets a port
  slot from its executor number. Set the Jenkins node to 3 executors (5 at most).
- The GPU model server is now off by default (`model_server_enabled = false`): it needs the GPU
  quota and a zone offering `model_instance_type`; a clear error replaces the old crash.
- Waitlist (separate, live on Render): `harkanni/sotto-waitlist`. Untouched until Phase 8.

## Next step

1. The owner: fix GitHub Actions billing (Blockers), re-run CI on the three PRs, then review and
   merge sotto-api#7, sotto-web#7, sotto-platform#8 in that order. The `ai_modes_and_billing`
   migration runs on deploy.
2. The owner, for the demo: `terraform apply` in `terraform/dev` (adds
   `/sotto/demo/AI_KEYS_MASTER`; nothing else changes from this phase), then re-run
   `deploy-config`. Until then the demo's AI settings says keys can't be stored.
3. Optional, the owner: a Paystack **test** secret key and plan codes in SSM
   (`/sotto/demo/PAYSTACK_SECRET_KEY`, `PAYSTACK_PLAN_PRO_MONTHLY`, …) to try Paystack's own test
   checkout; and a Managed provider key (`AI_MANAGED_CHAT`, `AI_MANAGED_KEY`) for the demo.
4. An agent session after the merges: start Phase 7 (PLAN Milestones row 7, the live notetaker)
   with `sotto-web/PHASE_7_PROGRESS.md`.

## Blockers and things the owner must do

- [ ] **GitHub Actions won't start jobs** (2026-10-10, every repo): "recent account payments have
      failed or your spending limit needs to be increased" → GitHub → Settings → Billing & plans.
      No workflow runs until then (CI, `sync`, image builds, deploys). Phase 6's checks were run
      locally and are recorded in the log.
- [ ] Phase 6: `terraform apply` for the demo master key (Next step 2).
- [ ] Phase 6: confirm Paystack's `transaction/verify` and subscription-list shapes with a real
      test key (ADR 0026); the stand-in follows Paystack's docs.

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

- Demo Managed provider key (Anthropic, OpenAI or Google) — default: none. Workspaces can add
  their own keys (BYOK) once the master key is applied; without either, the demo's Ask answers
  with labelled passages (ADR 0020).
- Real prices and limits — the plans config holds labelled placeholders (ADR 0025).
- Gating Business features (audit export, admin policies) — listed, not enforced (ADR 0025).
- Meeting bot — default: build the Google Meet bot ourselves (Phase 7).

## Environment facts

- AWS: paid plan, region `eu-west-2` (London). Demo costs ~$35/month; budget alert at $40.
- Demo server: t4g.medium (ARM) → images are built for `linux/arm64` on GitHub's arm64 runners.
- Agent sandbox: no npm/PyPI/apt access and no Docker daemon. CI's `sync` jobs commit lockfiles
  and publish `node_modules` snapshots that `scripts/agent-deps.sh` restores (both app repos).
