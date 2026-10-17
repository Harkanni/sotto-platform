# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-17 (CI/CD back on GitHub Actions, ADR 0034; Phase 7's first half merged)
**Current phase:** 7 — Live notetaker (in progress: M5 of M0–M9)

**Demo:** deployed from `main` by GitHub Actions: each app's CI/CD workflow (`.github/workflows/pipeline.yml`) pushes the images and deploys after every check passes, and skips that while the demo is down (`terraform output demo_url` prints the address)

## In progress: Phase 7 (Live notetaker)

Log: `sotto-web/PHASE_7_PROGRESS.md` (requirements, milestones, next step, checks run). Done when
(PLAN): a live call is transcribed as it happens, and the bot joins a Meet call. The first half
holds in the rendered app.

| Repo           | Branch           | PR                         | State                                                                                                |
| -------------- | ---------------- | -------------------------- | ---------------------------------------------------------------------------------------------------- |
| sotto-api      | `feat/p7-live`   | sotto-api#10 (merged)      | M1–M3 done: schema, Listen API (numbered audio chunks, SSE, End → meeting), live notes, ask mid-call |
| sotto-web      | `feat/p7-live`   | sotto-web#12 (merged)      | M4 done (Listen capture and screens); M5 part 1 checked in the rendered app; M5 part 2 next          |
| sotto-platform | `docs/p7-status` | sotto-platform#10 (merged) | STATUS; ADRs 0028 (live audio over HTTP chunks + SSE) and 0029 (a capture is private until saved)    |

The owner merged sotto-api#10 and sotto-web#12 on 2026-10-17 with M1–M5 part 1. The rest of the
phase (M5 part 2, then M6–M9) starts from `main` on new branches; the rest of Phase 7's platform
work (the bot's ADR, Compose and demo config) comes in its own PR.

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
- Phase 6 — AI modes, providers and billing merged (sotto-api#7 and sotto-web#7 on 2026-10-10,
  sotto-platform#8 on 2026-10-12): Private, BYOK and Managed per workspace; envelope-encrypted keys; model
  catalog and Switch model; Restricted proven never to reach outside AI; metering, quotas and
  plans; Paystack test mode behind `PaymentProvider`; embedding re-index. ADRs 0023–0027.
- CI/CD back on GitHub Actions (ADR 0034, 2026-10-17; it supersedes the Jenkins setup of ADR
  0030; `chore/github-actions` in all three repos). One workflow per repo,
  `.github/workflows/pipeline.yml`, on GitHub's runners, arm64 for everything that builds or
  boots an image. It runs every check the Jenkinsfiles ran, as parallel jobs; on `main`, only
  after all of them pass, it pushes the images to ECR and deploys the demo (sotto-api,
  sotto-web) or pushes `deploy/demo` when it changed (this repo). `terraform destroy` removes
  everything, ECR included: while the demo is down, `main` skips the deploy with a notice; after
  `terraform apply`, run the workflow on `main` in sotto-api and sotto-web. A newer push to a PR
  stops its older run. Actions are pinned to commits, with Dependabot. The Jenkinsfiles are gone.
  Before the repos go public, every commit on every branch and PR of all three was scanned for
  secrets (gitleaks 8.30.1 plus extra key patterns): nothing found.
- One Terraform stack (2026-10-15, `chore/single-stack`): `terraform/keep` is gone; `apply`
  brings everything up and `destroy` takes everything down, the demo's IP included (ADR 0033
  superseded). If `terraform/keep` was ever applied, destroy it first.
- `fix/accounts-flow-ci` (sotto-web): the accounts flow prints the api's logs on failure
  (they were removed first) and gives the sample-content load 30 s. It passes 7/7 locally
  against api `main`.
- CI fixes merged (2026-10-15; sotto-web#18, sotto-api#15, sotto-platform#20): the Accounts flow
  waits for a healthchecked Compose stack and the api's `/readyz`, and prints each service's
  state and logs on failure (RabbitMQ never came up; the old wait loop failed silently); browser
  tests run the standalone server; steadier story tests; quieter logs; gitleaks pinned to
  v8.30.1. `main` built green and deployed. Log: `sotto-web/CI_PROGRESS.md`. Deferred,
  cosmetic: Prisma's OpenSSL warning in the api image (approach in that log).
- Demo mailbox fix merged (2026-10-15; sotto-web#19, sotto-platform#21): the app's service
  worker leaves `/api` and `/mail` to the browser. It answered `/mail/` too, which hides
  Mailpit's password prompt, so the mailbox looped on 401 in any browser that had opened Sotto.
- The GPU model server is now off by default (`model_server_enabled = false`): it needs the GPU
  quota and a zone offering `model_instance_type`; a clear error replaces the old crash.
  (`fix/terraform-fmt-model`: a comment broke `terraform fmt` alignment in `model.tf`.)
- Waitlist (separate, live on Render): `harkanni/sotto-waitlist`. Untouched until Phase 8.

## Next step

1. An agent session: Phase 7 M5 part 2 in sotto-web (`PHASE_7_PROGRESS.md` → Next steps): a
   "Live now" row on Meetings and Home, stories for Listen, an e2e with Chromium's fake
   microphone, `pnpm smoothness`, the Listen section of `UI_DESIGN_SYSTEM.md`. Then M6–M8
   (calendar connections and the Meet bot) and M9.
2. The owner: review and merge the three `chore/github-actions` PRs (any order), then the
   switch-over steps under **Blockers**.
3. Optional, the owner: a Paystack **test** secret key and plan codes in SSM
   (`/sotto/demo/PAYSTACK_SECRET_KEY`, `PAYSTACK_PLAN_PRO_MONTHLY`, …) to try Paystack's own test
   checkout; and a Managed provider key (`AI_MANAGED_CHAT`, `AI_MANAGED_KEY`) for the demo.

## Blockers and things the owner must do

- [ ] Phase 6: confirm Paystack's `transaction/verify` and subscription-list shapes with a real
      test key (ADR 0026); the stand-in follows Paystack's docs.
- [ ] Buy `sotto.ai` (available, not bought). Until then the demo uses `https://<ip>.sslip.io`,
      which changes with every `terraform destroy` + `apply`, and which some security tools block.
- [ ] Phase 3: create the Google and Microsoft OAuth apps (steps in the Phase 3 PR); until then
      those buttons stay hidden. Phase 7's calendar connection needs them too (until then it
      runs on a labelled stand-in).
- [ ] Phase 7: a Google account for the notetaker bot ("Sotto Notetaker") is the owner's choice;
      without one it joins Meet as a guest that the host must admit.
- [ ] CI/CD switch-over (ADR 0034), once the `chore/github-actions` PRs are merged:
  - [ ] Make sotto-api and sotto-web public (Settings → General → Danger Zone). sotto-platform
        can stay private (its checks fit the free monthly minutes) or go public too. The web's
        accounts flow builds sotto-api from GitHub, so sotto-api must be public.
  - [ ] In each repo, Settings → Actions → General: actions allowed (they may have been switched
        off for Jenkins). The old `images` workflow can stay disabled; nothing uses it.
  - [ ] Repository secrets: after a `terraform apply`, `terraform output -raw github_secrets | sh`
        sets them in all three repos (or set `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` by
        hand). The same key sat on the internet-facing Jenkins server, so rotating it as Jenkins
        goes is cheap hygiene: a new key for the IAM user, into `terraform.tfvars`, then the
        command above.
  - [ ] Retire Jenkins: terminate `sotto-jenkins` (and its EBS volume, Elastic IP and security
        group, if any), delete the Jenkins webhooks in the three repos' settings, and revoke the
        GitHub token Jenkins used.
  - [ ] Optional, before going public: the `alert_email` default in `terraform/dev/variables.tf`
        is a personal address (move it to `terraform.tfvars`), and a few early sotto-platform
        commits carry a personal author email (only visible if this repo goes public).
- [x] GitHub Actions billing (2026-10-17): free and unmetered on GitHub's standard runners, arm64
      included, once the repos are public (ADR 0034).
- [x] Terraform for Phases 4–6 (scoped S3 key, CORS, `/sotto/demo/AI_KEYS_MASTER`, …): the
      single stack was applied from scratch on 2026-10-15, and the first boot writes the server's
      `.env` from SSM.
- [x] ECR repositories: recreated by that apply; Jenkins `main` builds pushed and deployed the
      api, worker, transcriber and web on 2026-10-15.
- [x] Phase 4 decision (mock engines on a small demo server): decided in ADR 0031, real private
      AI on a larger server; the chat model's GPU server is ADR 0032 (off by default).

## Open decisions

- Demo Managed provider key (Anthropic, OpenAI or Google) — default: none. Workspaces can add
  their own keys (BYOK) once the master key is applied; without either, the demo's Ask answers
  with labelled passages (ADR 0020).
- Real prices and limits — the plans config holds labelled placeholders (ADR 0025).
- Gating Business features (audit export, admin policies) — listed, not enforced (ADR 0025).
- Meeting bot — default: build the Google Meet bot ourselves (Phase 7).

## Environment facts

- AWS: paid plan, region `eu-west-2` (London). The demo server (m7g.2xlarge) costs about $300 a
  month running all the time (ADR 0031); budget alert at $350. Stopping it when not demoing saves
  most of that. The GPU chat server is off by default (about $2 an hour when on, ADR 0032).
- Images are built for `linux/arm64` on GitHub's arm64 runners (`ubuntu-24.04-arm`), like the
  demo.
- Demo address: `terraform output demo_url` (and `demo_mail_url`, user `sotto`, password from
  `terraform output -raw demo_mail_password`).
- Agent sandbox (2026-10-16): npm, PyPI and the Ubuntu package mirror are reachable; Docker Hub
  and `binaries.prisma.sh` are not. Prisma's schema engine comes from the newest `dev-cache`
  snapshot (`scripts/agent-deps.sh`; the old Actions `sync` job that published them was not
  brought back).
  sotto-api's integration tests run against apt's Postgres 16 + pgvector, Redis and moto (S3):
  steps in `sotto-web/PHASE_7_PROGRESS.md`.
