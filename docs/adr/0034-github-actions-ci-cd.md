# 0034 — CI/CD back on GitHub Actions, on GitHub's runners

- **Status:** accepted (supersedes 0030)
- **Date:** 2026-10-17

## Context

ADR 0030 moved every check and deploy to Jenkins on an EC2 server the owner runs himself. To run
builds side by side it grew to a `c7g.4xlarge` (16 vCPUs), which costs more per hour than the
demo server, plus a second machine to patch and secure (Jenkins and its plugins, the open
webhook port, a GitHub token to rotate). GitHub-hosted runners, the arm64 ones included, are free
and unmetered for public repositories. The owner is making the repos public and wants CI/CD back
on GitHub Actions, with Jenkins gone.

## Decision

- Each repo has one workflow, `.github/workflows/pipeline.yml` ("CI/CD"), on every pull request,
  every push to `main` and on demand (Run workflow). It runs every check its Jenkinsfile ran, as
  parallel jobs. On `main`, only after every check has passed, it pushes and deploys: images to
  ECR and the demo through the `sotto-deploy` SSM document (sotto-api, sotto-web), or the demo
  config when `deploy/demo` changed (this repo). The demo server, its Compose stack and
  `deploy.sh` are unchanged.
- A new file name, not the old `ci.yml`/`images.yml`: GitHub remembers per file that a workflow
  was disabled in the Actions tab, and `images.yml` was disabled when Jenkins took over.
- Runners: `ubuntu-24.04` for the code checks, `ubuntu-24.04-arm` for everything that builds or
  boots an image, so the tested images are arm64 like the demo (Graviton). The jobs share image
  layers through the GitHub Actions cache (buildx `type=gha`): the first job builds and writes
  them, the later ones and the deploy rebuild from those layers, so `main` ships what was tested.
- AWS access stays the IAM access key in repository secrets (ADR 0007, no OIDC).
  `terraform output -raw github_secrets | sh` sets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
  `AWS_REGION`, `ECR_REGISTRY` and `CONFIG_BUCKET` in all three repos; the last three are optional
  (defaults: `eu-west-2`, and names worked out from the account). Only the deploy jobs read them,
  only on `main`. Pull requests, from forks too, never see a secret: no `pull_request_target`.
- While the demo is down (no ECR repository, or no running demo server), `main` skips the push
  and deploy with a notice instead of failing, as on Jenkins. After `terraform apply`, run the
  workflow on `main` in each app repo.
- The web's accounts flow builds sotto-api's image from its public GitHub repo (`main`, or the
  `api_ref` given to Run workflow) instead of pulling it from ECR, so that check needs neither
  AWS nor the demo.
- Public-repo hygiene: third-party actions are pinned to commit SHAs (a tag can be moved; the
  deploy jobs hold an AWS key) and Dependabot proposes updates weekly; the secrets scan covers
  every commit as well as the files, because a key deleted in a later commit is still readable
  in a public history. The full history of all three repos, every branch and PR included, was
  scanned before the switch (gitleaks 8.30.1 plus extra key patterns): nothing found.

## Consequences

- No CI server to run, patch or pay for. The owner terminates `sotto-jenkins` (with its EBS
  volume and any Elastic IP and security group), deletes the repos' Jenkins webhooks and revokes
  the GitHub token Jenkins used.
- Runners have 4 vCPUs. Builds run as parallel jobs on separate runners instead of parallel
  stages on one large host; a build without cached layers is slower than on 16 cores.
- Anything committed, in any commit, is public. Secrets only ever live in GitHub secrets, SSM
  Parameter Store or local `.env` files.
- A repo that stays private still runs, but its minutes count against the account's monthly
  Actions allowance (sotto-platform's checks are small; sotto-api's and sotto-web's are not).
  The accounts flow needs sotto-api to be public.
- Rolling back: the Jenkinsfiles are in the history (removed in `chore/github-actions`).
