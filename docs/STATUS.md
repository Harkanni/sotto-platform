# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-16 (Phase 7 branches brought up to date with `main`)
**Current phase:** 7 — Live notetaker (in progress: M5 of M0–M9)

**Demo:** deployed from `main` by Jenkins: each app's `Build and push image` → `Deploy to demo` stages, after every check passes (`terraform output demo_url` prints the address)

## In progress: Phase 7 (Live notetaker)

Log: `sotto-web/PHASE_7_PROGRESS.md` (requirements, milestones, next step, checks run). Done when
(PLAN): a live call is transcribed as it happens, and the bot joins a Meet call. The first half
holds in the rendered app.

| Repo           | Branch           | PR                        | State                                                                                                  |
| -------------- | ---------------- | ------------------------- | ------------------------------------------------------------------------------------------------------ |
| sotto-api      | `feat/p7-live`   | sotto-api#10 (draft)      | M1–M3 done: schema, Listen API (numbered audio chunks, SSE, End → meeting), live notes, ask mid-call   |
| sotto-web      | `feat/p7-live`   | sotto-web#12 (draft)      | M4 done (Listen capture and screens); M5 part 1 checked in the rendered app; M5 part 2 next            |
| sotto-platform | `docs/p7-status` | sotto-platform#10 (draft) | This STATUS; ADRs 0028 (live audio over HTTP chunks + SSE) and 0029 (a capture is private until saved) |

All three branches include `main` as of 2026-10-16. Merge order at the end of the phase:
sotto-api#10 first (migration `live_notetaker`), then sotto-web#12. sotto-platform#10 can merge
ahead of them (this STATUS and two decisions already taken), so `main`'s STATUS is current; the
rest of Phase 7's platform work (the bot's ADR, Compose and demo config) then comes in its own PR.

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
- CI/CD moved to Jenkins (ADR 0030; sotto-platform#9). Every check now runs in the
  Jenkinsfiles; GitHub Actions is no longer used. A newer push to a branch stops its older
  build (`abortPrevious`; sotto-api, sotto-web and this repo's `chore/jenkins-abort-previous`).
  `terraform destroy` removes everything, ECR included: while the demo is down, Jenkins on
  `main` skips the push and deploy; after `terraform apply`, run **Build** on each app's `main`.
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
- Jenkins builds run side by side (ADR 0030 update): no shared lock; each build gets a port
  slot from its executor number. Set the Jenkins node to 3 executors (5 at most).
- The GPU model server is now off by default (`model_server_enabled = false`): it needs the GPU
  quota and a zone offering `model_instance_type`; a clear error replaces the old crash.
  (`fix/terraform-fmt-model`: a comment broke `terraform fmt` alignment in `model.tf`.)
- Waitlist (separate, live on Render): `harkanni/sotto-waitlist`. Untouched until Phase 8.

## Next step

1. An agent session: Phase 7 M5 part 2 in sotto-web (`PHASE_7_PROGRESS.md` → Next steps): a
   "Live now" row on Meetings and Home, stories for Listen, an e2e with Chromium's fake
   microphone, `pnpm smoothness`, the Listen section of `UI_DESIGN_SYSTEM.md`. Then M6–M8
   (calendar connections and the Meet bot) and M9.
2. Optional, the owner: merge sotto-platform#10 now so `main`'s STATUS is current.
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
- [ ] Cleanup, when convenient: `terraform output github_secrets` and the OIDC Terraform
      (`terraform/dev/github_oidc.tf`, ADR 0007) are unused since CI moved to Jenkins.
- [x] GitHub Actions billing (2026-10-10): no longer matters; CI runs on Jenkins (ADR 0030).
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
- Images are built for `linux/arm64` on the Jenkins host, which is arm64 like the demo.
- Demo address: `terraform output demo_url` (and `demo_mail_url`, user `sotto`, password from
  `terraform output -raw demo_mail_password`).
- Agent sandbox (2026-10-16): npm, PyPI and the Ubuntu package mirror are reachable; Docker Hub
  and `binaries.prisma.sh` are not. Prisma's schema engine comes from the newest `dev-cache`
  snapshot (`scripts/agent-deps.sh`; GitHub Actions' `sync` job no longer publishes new ones).
  sotto-api's integration tests run against apt's Postgres 16 + pgvector, Redis and moto (S3):
  steps in `sotto-web/PHASE_7_PROGRESS.md`.
