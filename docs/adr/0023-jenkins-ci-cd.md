# 0023 — Jenkins runs CI/CD on its own EC2 server

- **Status:** accepted
- **Date:** 2026-10-10

## Context
Until now GitHub Actions ran every check (`ci.yml`) and every deploy (`images.yml`) in
`sotto-api` and `sotto-web`. The owner is learning Cloud/Platform Engineering and wants Sotto's
CI/CD on Jenkins, run from a server he manages himself, set up the plain way: an EC2 instance he
reaches over SSH, configured by hand. Setup guide:
https://claude.ai/code/artifact/4949c203-aad7-434a-8b00-a140b968faa6

## Decision
- Jenkins LTS runs on a separate EC2 instance, `sotto-jenkins`: Ubuntu 24.04 on a `t4g.large`
  (ARM, 8 GB) in `eu-west-2`, with Docker (Buildx, Compose), Node 24 with pnpm via Corepack, and
  the AWS CLI. Access is SSH with a key pair (port 22 from the owner's IP); the Jenkins UI and
  GitHub webhooks use port 8080. It is created in the console, not in Terraform.
- Each app repo has a `Jenkinsfile` (Multibranch Pipeline). Every branch and PR runs the fast
  checks; `main` also builds the `linux/arm64` images, pushes `sha-<7>` and `main` tags to ECR,
  and deploys the demo through the existing `sotto-deploy` SSM document. The demo server, its
  Compose stack and `deploy.sh` are unchanged; it still has no SSH port.
- AWS access: the jenkins user's AWS CLI uses the same IAM access key as Actions (ADR 0007).
- GitHub Actions keeps the heavy checks in `ci.yml` (transcriber pytest, smoke, ingestion,
  evals, secret scan; Playwright, Storybook, accounts). `images.yml` stays in the repos as a
  fallback but is disabled in the Actions tab once Jenkins deploys, so nothing deploys twice.

## Consequences
- The owner maintains a second server: Jenkins and plugin updates, disk clean-up, the GitHub
  token's 90-day rotation, and its cost (a `t4g.large`, more than the demo; stop it when idle).
- The pipeline lives in `Jenkinsfile`; agents change CI/CD there, not in `images.yml`.
- Port 8080 is open to the internet for webhooks: the Jenkins admin password must be strong.
  Later hardening: HTTPS in front of Jenkins and webhooks limited to GitHub's IP ranges.
- One executor: builds run one at a time (fixed test ports, one demo server).
- Rolling back is re-enabling `images.yml`.
