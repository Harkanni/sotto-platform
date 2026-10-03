# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-03
**Current phase:** 4 — Ingestion and meetings (in progress)
**Demo:** deployed from `main` by the `images` workflows (`terraform output demo_url` prints the address)

## Done

- Phase 0 — plan approved with the owner's answers. See `docs/PLAN.md` → Decisions.
- Phase 1 — all three scaffold PRs merged; `images` builds, pushes and deploys from `main`. CI
  authenticates to AWS with an IAM access key (ADR 0007); `deploy-config.yml` uses it too.
- Phase 2 — design system and app shell merged (sotto-web#2, sotto-platform#2). ADR 0008.
- Phase 3 — accounts and workspaces merged (sotto-api#3, sotto-web#3, sotto-platform#3): magic
  link, passkeys, Google/Microsoft (hidden until configured), workspaces, invites, roles,
  collection access in SQL, audit log + CSV, onboarding. ADRs 0009–0015.
- Waitlist (separate, live on Render): `harkanni/sotto-waitlist`. Untouched until Phase 8.

## In progress

| Repo           | Branch / PR                                                                               | What                                                                    |
| -------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| sotto-api      | `feat/p4-ingestion` → [PR #4](https://github.com/Harkanni/sotto-api/pull/4) (draft)        | Uploads, files API, worker pipeline, transcriber, meetings, live status |
| sotto-web      | `feat/p4-ingestion` → [PR #4](https://github.com/Harkanni/sotto-web/pull/4) (draft)        | Uploads, recording, Docs and Meetings on real files, player, transcript |
| sotto-platform | `docs/p4-status` → this PR (draft)                                                         | STATUS, ADRs, Compose (storage, models), demo config                    |

Phase 4 state: M0 (plan) and M1 (schema, migration, storage module, contracts) done. The
detailed log is `sotto-web/PHASE_4_PROGRESS.md` on `feat/p4-ingestion`: requirements,
milestones, decisions, missing specifications, tests run.

## Next step

An agent session continues with the phase log's **Next steps** (M2: uploads and files API).

## Blockers and things the owner must do

- [ ] Buy `sotto.ai` (available, not bought). Until then the demo uses `https://<ip>.sslip.io`.
- [ ] Phase 3: create the Google and Microsoft OAuth apps (steps in the Phase 3 PR); until then
      those buttons stay hidden.
- [ ] Phase 3: if not done yet, `terraform apply` in `terraform/dev` (demo `AUTH_SECRET`, the
      mailbox password, ECR repositories `sotto/api` and `sotto/worker`).
- [ ] Phase 4 decision: the demo server (t4g.medium, 4 GB) has no room for a local chat model
      and is tight for real transcription + embeddings (see the phase log, "Missing
      specifications" 3–4). Default until you decide: labelled mock engines on the demo, real
      ones locally and in CI.
- [ ] Check: `terraform output github_secrets` prints `gh secret set` for `AWS_REGION` and
      `ECR_REGISTRY`, but the workflows read them as **variables** (`vars.`). They work today
      (the variables are set); keep both in sync if you rotate anything.
- [ ] ECR is missing repositories: sotto-api `images` on `main` (2026-10-02 07:32) failed on
      `sotto/worker`, and on 2026-10-03 sotto-web's `accounts` job found no `sotto/api` in the
      registry its `ECR_REGISTRY` points to. `terraform/dev/ecr.tf` defines all four
      (`local.services`), so `terraform apply` (step 1 above) creates them in that account.
- [ ] ADR 0007 follow-up: the OIDC Terraform (`terraform/dev/github_oidc.tf`) is unused now.

## Open decisions

- Demo chat provider key (Anthropic, OpenAI or Google) — default: whichever key is added first.
- Meeting bot — default: build the Google Meet bot ourselves (Phase 7).

## Environment facts

- AWS: paid plan, region `eu-west-2` (London). Demo costs ~$35/month; budget alert at $40.
- Demo server: t4g.medium (ARM) → images are built for `linux/arm64` on GitHub's arm64 runners.
- Agent sandbox: no npm/PyPI/apt access and no Docker daemon. CI's `sync` jobs commit lockfiles
  and publish `node_modules` snapshots that `scripts/agent-deps.sh` restores (both app repos).
