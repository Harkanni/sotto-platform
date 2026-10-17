# Sotto — working instructions (sotto-platform)

Read this first, in every session. It is permanent: the rules shared by all three repos, and how
to pick the work up from any new session.

Sotto is a privacy-first SaaS where internal teams upload memos and meeting recordings, then ask
questions and get answers with sources. It is built across three repos, cloned side by side:

```
~/code/sotto/
├── sotto-platform/   ← this repo: docs hub, Compose stack, Terraform, deploy, later Helm/Argo CD
├── sotto-api/        ← NestJS api, Node worker, Python transcriber, Prisma (pnpm monorepo)
└── sotto-web/        ← Next.js 16 app (product + marketing), design system, Storybook
```

Each repo has its own `CLAUDE.md` with its architecture, conventions and test commands.

## Start of every session: recover, then continue

1. Read this file and the `CLAUDE.md` of the repo you'll work in.
2. Read `docs/STATUS.md`: the current phase, open PRs and branches, blockers.
3. Read the current phase's log, `sotto-web/PHASE_<n>_PROGRESS.md` (one log covers all three
   repos), and `sotto-web/UI_DESIGN_SYSTEM.md` before any UI work.
4. In all three repos: `git fetch`, `git status`, `git log --oneline -15`; read the open PR
   checklists.
5. Compare the log with the code. Where they disagree, investigate and correct the log first.
6. Continue from the first unfinished task. Never restart a phase, repeat finished work or
   replace working code without a clear technical reason.

Reference: `docs/PLAN.md` (the approved plan), `docs/BRIEF.md` (the original brief; the plan
wins where they differ: 12 phases, swappable AI providers, Paystack first, sign-in with magic
link, passkeys, Google and Microsoft, development and the demo on AWS eu-west-2), `docs/adr/`
(decisions and why).

## Shared rules

- **UI and UX come first.** The interface must feel premium, native and buttery. New screens
  extend the existing design system (`sotto-web/UI_DESIGN_SYSTEM.md`); never restyle what the
  owner approved out of preference.
- `main` is always deployable. All work goes through a branch and a pull request with green CI.
  The owner (Akanni, GitHub `Harkanni`) merges; agents never merge their own PRs, force-push or
  rewrite history.
- Branch names: `feat/p<phase>-<slice>`, `fix/…`, `chore/…`, `docs/…`. Conventional Commits.
- Work in progress lives on a pushed branch with a draft PR whose description is a checklist.
  Checkpoint after every logically complete task (checks → phase log → commit → push); when a
  session may end, record the exact next step first.
- **Every PR updates `docs/STATUS.md`** in this repo (open PRs, what's done, next step). A PR in
  sotto-api or sotto-web gets a companion STATUS update here. API + web pairs: the API PR merges
  first.
- Never commit secrets. Only `.env.example` files. Real values live in local `.env`, GitHub
  Actions secrets, or AWS SSM Parameter Store (`/sotto/<env>/…`). sotto-api and sotto-web are
  public: anything in any commit, not just the latest files, can be read by anyone. AWS access
  for CI uses an IAM access key kept as GitHub Actions secrets (ADR 0007); don't reintroduce
  OIDC, and never give pull request jobs a secret (no `pull_request_target`).
- **CI/CD runs on GitHub Actions** (ADR 0034; Jenkins is gone). Each repo's
  `.github/workflows/pipeline.yml` runs the checks on every PR and push to `main`; on `main`,
  after every check passes, the app repos push their arm64 images to ECR and deploy the demo
  through the `sotto-deploy` SSM document, and this repo pushes `deploy/demo` when it changed.
  While the demo is down, `main` skips the deploy; after `terraform apply`, run the workflow on
  `main` (Actions → CI/CD → Run workflow) in sotto-api and sotto-web.
- Teaching mode: annotate every Dockerfile, Compose file and Terraform file with short "why"
  comments. The owner is learning Cloud/Platform Engineering; phases 9–11 are "guide me" by
  default (task, hints, a way to check — he writes it, the agent reviews).
- Ask before adding any paid service or changing live infrastructure.
- Label every mock; never stub silently.

## This repo's layout

| Path           | Holds                                                                                   |
| -------------- | --------------------------------------------------------------------------------------- |
| `docs/`        | STATUS, PLAN, BRIEF, ADRs, CHANGELOG, runbooks, LEARNING notes                          |
| `local/`       | Docker Compose for the whole stack, built from `../sotto-api` and `../sotto-web`        |
| `deploy/demo/` | The Compose + Caddy files the always-on demo server runs                                |
| `terraform/`   | `bootstrap/` (state bucket) and `dev/` (demo + workbench servers, ECR, S3, SSM, budget) |
| `Taskfile.yml` | Common commands (`task up`, `task down`, `task tf:plan` …)                              |
