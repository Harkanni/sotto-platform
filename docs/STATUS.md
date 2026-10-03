# Build status

> Handoff file. Every PR updates it. A new session reads this first, then continues from **Next step**.

**Updated:** 2026-10-03
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
| sotto-api      | `feat/p3-accounts` → [PR #3](https://github.com/Harkanni/sotto-api/pull/3) — CI green | Better Auth, workspaces, members, invites, roles, collections, audit |
| sotto-web      | `feat/p3-accounts` → [PR #3](https://github.com/Harkanni/sotto-web/pull/3)            | Sign-in, onboarding, invites, Profile, collections with access, E2E  |
| sotto-platform | `docs/p3-status` → this PR                                                            | STATUS, CLAUDE.md, ADRs 0009–0015, demo auth + mailbox config        |

Phase 3 state: milestones M0–M6 done; M7 (done-when E2E, CI job, demo config, ADRs) written and
passing locally on iPhone and desktop. What's left is merging in order (below) so the web PR's
`accounts` job can run against the new API image.

The detailed log for the phase is `sotto-web/PHASE_3_PROGRESS.md` (on `feat/p3-accounts`):
requirements, milestones, decisions, missing specifications, tests run.

## Next step

Owner, in this order:

1. Review ADR 0015 (the demo's mailbox) and merge this PR; run `terraform apply` in
   `terraform/dev`. It creates the demo's `AUTH_SECRET` and mailbox password in SSM, and the
   missing ECR repository `sotto/worker`.
2. Merge sotto-api#3. Its `images` workflow then publishes `sotto/api:main` with Phase 3 and
   deploys the demo (the API migrates on deploy).
3. Re-run sotto-web#3's CI: the `accounts` job pulls that image and runs the done-when E2E.
   Merge when green; `images` deploys the web.
4. On the demo: sign in at the demo URL; the link arrives at `<demo>/mail/` (user `sotto`,
   `terraform output -raw demo_mail_password`).

An agent session continues with whatever the phase log's **Next steps** says (after merging:
Phase 4).

## Blockers and things the owner must do

- [ ] Buy `sotto.ai` (available, not bought). Until then the demo uses `https://<ip>.sslip.io`.
- [ ] Phase 3: create the Google and Microsoft OAuth apps (steps in the Phase 3 PR); until then
      those buttons stay hidden.
- [ ] Phase 3: approve how the demo sends email before the domain exists: ADR 0015 (Mailpit at
      `/mail/` behind a password; SES once the domain is verified), then `terraform apply`.
- [ ] This PR's CI shows "action required": approve the workflow run in the Actions tab.
- [ ] Check: `terraform output github_secrets` prints `gh secret set` for `AWS_REGION` and
      `ECR_REGISTRY`, but the workflows read them as **variables** (`vars.`). They work today
      (the variables are set); keep both in sync if you rotate anything.
- [ ] sotto-api `images` on `main` (2026-10-02 07:32) failed: ECR repository `sotto/worker` did not
      exist (and fail-fast cancelled the api build). `terraform/dev` defines it
      (`local.services`), so `terraform apply` (step 1 above) creates it.
- [ ] ADR 0007 follow-up: the OIDC Terraform (`terraform/dev/github_oidc.tf`) is unused now.

## Open decisions

- Demo chat provider key (Anthropic, OpenAI or Google) — default: whichever key is added first.
- Meeting bot — default: build the Google Meet bot ourselves (Phase 7).

## Environment facts

- AWS: paid plan, region `eu-west-2` (London). Demo costs ~$35/month; budget alert at $40.
- Demo server: t4g.medium (ARM) → images are built for `linux/arm64` on GitHub's arm64 runners.
- Agent sandbox: no npm/PyPI/apt access and no Docker daemon. CI's `sync` jobs commit lockfiles
  and publish `node_modules` snapshots that `scripts/agent-deps.sh` restores (both app repos).
