# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-02
**Current phase:** 3 — Accounts and workspaces (in progress)
**Demo:** deployed from `main` by the `images` workflows (`terraform output demo_url` prints the address)

## Done

- Phase 0 — plan approved with the owner's answers. See `docs/PLAN.md` → Decisions.
- Phase 1 — all three scaffold PRs merged; `images` builds, pushes and deploys from `main`. CI
  authenticates to AWS with an IAM access key (ADR 0007); `deploy-config.yml` uses it too.
- Phase 2 — design system and app shell merged (sotto-web#2, sotto-platform#2): tokens,
  components with every state, per-tab stacks with compositor push/pop, + sheet, panes, ⌘K,
  offline shell, 46 stories, unit/e2e/story tests. ADR 0008 (client-side stack navigation).
- Waitlist (separate, live on Render): `harkanni/sotto-waitlist`. Untouched until Phase 8.

## In progress

| Repo           | Branch / PR                                                                           | What                                                                 |
| -------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| sotto-api      | `feat/p3-accounts` → [PR #3](https://github.com/Harkanni/sotto-api/pull/3) (draft)    | Better Auth, workspaces, members, invites, roles, collections, audit |
| sotto-web      | `feat/p3-accounts` → [PR #3](https://github.com/Harkanni/sotto-web/pull/3) (draft)    | Sign-in, onboarding, invites, Profile admin screens, access sheet    |
| sotto-platform | `docs/p3-status` → this PR                                                            | STATUS, permanent CLAUDE.md, ADRs, demo config for auth email        |

The detailed log for the phase is `sotto-web/PHASE_3_PROGRESS.md` (on `feat/p3-accounts`):
requirements, milestones, decisions, missing specifications, tests run.

## Next step

Continue Phase 3 from the first unfinished milestone in `sotto-web/PHASE_3_PROGRESS.md`.
Merge order when ready: this PR (and `terraform apply` for the new demo secrets) → sotto-api#3 →
sotto-web#3.

## Blockers and things the owner must do

- [ ] Buy `sotto.ai` (available, not bought). Until then the demo uses `https://<ip>.sslip.io`.
- [ ] Phase 3: create the Google and Microsoft OAuth apps (steps in the Phase 3 PR); until then
      those buttons stay hidden.
- [ ] Phase 3: approve how the demo sends email before the domain exists (proposal: Mailpit on
      the demo server behind a password; SES once the domain is verified).
- [ ] sotto-api `images` on `main` (2026-10-02 07:32) failed: ECR repository `sotto/worker` did not
      exist. `terraform/dev` defines it (`local.services`), so re-running `terraform apply` there
      should create it; then re-run `images`.
- [ ] ADR 0007 follow-up: the OIDC Terraform (`terraform/dev/github_oidc.tf`) is unused now.

## Open decisions

- Demo chat provider key (Anthropic, OpenAI or Google) — default: whichever key is added first.
- Meeting bot — default: build the Google Meet bot ourselves (Phase 7).

## Environment facts

- AWS: paid plan, region `eu-west-2` (London). Demo costs ~$35/month; budget alert at $40.
- Demo server: t4g.medium (ARM) → images are built for `linux/arm64` on GitHub's arm64 runners.
- Agent sandbox: no npm/PyPI/apt access and no Docker daemon. CI's `sync` jobs commit lockfiles
  and publish `node_modules` snapshots that `scripts/agent-deps.sh` restores (both app repos).
