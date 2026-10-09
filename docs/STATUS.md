# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-09
**Current phase:** 4 — Ingestion and meetings (merged; fixing uploads on the demo)

**Demo:** deployed from `main` by the `images` workflows (`terraform output demo_url` prints the address)

## Fixing now: uploads fail on the demo (2026-10-09)

The owner reported: "I can't upload docs; I keep getting an error." Branch `fix/p4-uploads`.

**Root cause:** the demo's app containers had no AWS credentials. Phase 4's demo Compose assumed
"the server's IAM role signs every request", but since Phase 1 the instance requires IMDSv2 with
`http_put_response_hop_limit = 1` (`terraform/dev/demo.tf`), so the role never reaches a Docker
container. The api, worker and transcriber couldn't sign any S3 call: `POST /uploads` failed at
`CreateMultipartUpload` with a generic 500, and reading pages, peaks and sample files failed too.
The deploy stayed green because readiness didn't include storage. Separately, the bucket's CORS
rule (browser part uploads) exists only after the owner's `terraform apply`.

| Repo           | PR                                                 | What                                                                                                           | State         |
| -------------- | -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ------------- |
| sotto-api      | [#5](https://github.com/Harkanni/sotto-api/pull/5) | Storage in `/readyz`; `503 STORAGE_UNAVAILABLE` instead of a 500; sample load retry-safe                       | draft, pushed |
| sotto-platform | `fix/p4-uploads` (this PR)                         | Scoped IAM user + SSM keys for the app (ADR 0018); keys passed in Compose; deploy fails if the api isn't ready | draft, pushed |

**What the owner does, in order** (needs AWS admin credentials on your machine):

1. Merge sotto-api#5 once CI is green (its `images` workflow deploys the api).
2. `cd terraform/dev && git checkout fix/p4-uploads && terraform plan`. Expect to **add**
   `aws_iam_user.app_files`, its policy, `aws_iam_access_key.app_files`, two
   `aws_ssm_parameter` (`/sotto/demo/S3_*`), the bucket CORS and lifecycle rules (if you never
   applied Phase 4), and **change** `aws_iam_role_policy.server` and the `demo/*` config
   objects. Nothing should be destroyed or replaced. Then `terraform apply`.
3. Merge this PR. Its `deploy-config` run writes the new keys into the server's `.env`,
   restarts api/worker/transcriber, and now fails if the api isn't ready (it prints which
   dependency). If it ran before step 2, re-run it from the Actions tab.
4. Check: open the demo, upload a PDF from Docs → it reaches Ready.

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
- Waitlist (separate, live on Render): `harkanni/sotto-waitlist`. Untouched until Phase 8.

## Next step

1. The owner follows **What the owner does, in order** above (merge sotto-api#5, `terraform
apply`, merge this PR), then confirms uploads work on the demo.
2. An agent session continuing this fix: check CI on sotto-api#5 and this PR, fix anything red,
   then keep auditing Phase 4 (log in `sotto-web/PHASE_4_PROGRESS.md` → "Post-merge fixes").
3. Then Phase 5 (Ask and search) from `docs/PLAN.md`, creating `sotto-web/PHASE_5_PROGRESS.md`.

## Blockers and things the owner must do

- [ ] Buy `sotto.ai` (available, not bought). Until then the demo uses `https://<ip>.sslip.io`.
- [ ] Phase 3: create the Google and Microsoft OAuth apps (steps in the Phase 3 PR); until then
      those buttons stay hidden.
- [x] ECR repositories exist: sotto-api's `images` built and deployed `main` on 2026-10-06,
      and sotto-web's `accounts` job pulls `sotto/api:main`.
- [ ] Phase 4 + upload fix: `terraform apply` in `terraform/dev` (steps at the top). It adds
      the app's scoped S3 key (ADR 0018), the bucket's CORS rule (browser uploads), the
      abandoned-upload sweep, and trims the instance role.
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
