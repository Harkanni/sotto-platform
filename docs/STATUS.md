# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-12 (Phase 7 in progress; blockers consolidated)
**Current phase:** 7 — Live notetaker (in progress)

**Demo:** deployed from `main` by the `images` workflows (`terraform output demo_url` prints the address)

## In progress: Phase 7 (Live notetaker)

Log: `sotto-web/PHASE_7_PROGRESS.md` (requirements, milestones, next step, checks run).

| Repo           | Branch           | PR                        | State                                                     |
| -------------- | ---------------- | ------------------------- | --------------------------------------------------------- |
| sotto-api      | `feat/p7-live`   | sotto-api#10 (draft)      | M1 schema done; Listen API next                           |
| sotto-web      | `feat/p7-live`   | sotto-web#12 (draft)      | Phase 7 log; Listen mode after the API                    |
| sotto-platform | `docs/p7-status` | sotto-platform#10 (draft) | Based on `docs/p6-status` (sotto-platform#8 isn't merged) |

Listen mode first (live transcript and notes in the app, ask mid-call), then calendar and the
self-hosted Meet bot. Audio goes up as numbered HTTP chunks with the transcript coming back over
SSE rather than a WebSocket (Next's rewrites don't carry WebSocket upgrades, and no dependency
can be added while CI is blocked); an ADR records it.

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
  Jenkinsfiles; GitHub Actions is no longer used.
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
4. Phase 7 is under way on the branches above (Phase 6 is merged in sotto-api and sotto-web;
   this repo's #8 and #9 are still open). An agent session continues from the Phase 7 log's
   **Next steps**.
5. ADR numbers: 0023–0027 Phase 6 (merged), 0028–0029 Phase 7 (this branch), 0030 Jenkins
   (sotto-platform#9, renumbered), 0031 the demo's real-AI host.

## Blockers and things the owner must do

Consolidated 2026-10-12. CI/CD has moved from GitHub Actions to Jenkins (the owner's decision;
sotto-platform#9 records it as ADR 0023).

**Blocking merges and deploys** (updated 2026-10-13)

- [ ] **Jenkins can't report to GitHub**: every build logs `Could not update commit status …
  Resource not accessible by personal access token (403)`. The token in Jenkins credential
      `github-sotto` needs **Commit statuses: Read and write** (fine-grained) or the `repo` scope
      (classic), for all three repos. Until then PRs show no Jenkins check.
- [x] sotto-platform `main` fmt fixed (#14, merged).
- [ ] sotto-platform#15: security group description AWS refused (blocks `terraform apply`), and
      the keep stack (model cache + fixed IP, ADR 0033). Apply `terraform/keep` once.
- [ ] Jenkins token: fine-grained **Commit statuses: Read and write** (it is read-only now).
- [ ] Merge the CI ports once green: sotto-api#11, sotto-web#13 (sotto-platform#12 is merged).
- [ ] Jenkins host: Lockable Resources plugin; `sudo npx -y playwright@1 install-deps chromium`;
      ≥60 GB disk. AWS access is the jenkins user's AWS CLI profile; ECR registry and config
      bucket are derived from the account (no global variables).
- Merged: #9 (Jenkins, ADR 0030), #11 (OIDC removed), #12 (platform on Jenkins), #13 (bigger
  demo). Open: #14 (GPU model server, ADR 0032; needs a GPU quota first), sotto-api#12 (sends the
  model's thinking-off option).

**For the demo**

- [ ] Phase 6: `terraform apply` in `terraform/dev` (adds `/sotto/demo/AI_KEYS_MASTER`), then
      redeploy the config. Until then the demo can't store workspace API keys.
- [ ] Phase 4 upload fix: `terraform apply` (the app's scoped S3 key, bucket CORS and lifecycle),
      if not done yet.
- [ ] Demo's AI: app server m7g.2xlarge (ADR 0031, merged) + chat on a g6e.xlarge GPU with
      Qwen3.6-35B-A3B (ADR 0032, sotto-platform#14). Request the G-instance quota (4 vCPUs,
      eu-west-2) first; after the first deploy, run the re-index once (steps in #13).

**For features (Phase 3 and 7)**

- [ ] Google and Microsoft OAuth apps: sign-in buttons stay hidden without them, and Phase 7's
      calendar connection needs them (with calendar read scopes).
- [ ] A Google account for the notetaker bot ("Sotto Notetaker"), or accept that it joins Meet
      as a signed-out guest the host must admit.
- [ ] Optional: a Paystack test key and plan codes (confirms ADR 0026's response shapes); a
      Managed provider key.
- [ ] Buy `sotto.ai` (domain and company email); until then the demo uses `<ip>.sslip.io`.

**Housekeeping**

- [x] `terraform/dev/github_oidc.tf` removed in sotto-platform#11 (plan: 3 to destroy); and with Jenkins, the GitHub
      secrets and variables for AWS (`AWS_ACCESS_KEY_ID`, `ECR_REGISTRY` …) can be removed once
      `images.yml` is off.

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
