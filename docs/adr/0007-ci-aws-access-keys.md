# 0007 — GitHub Actions reach AWS with an IAM access key

- **Status:** accepted
- **Date:** 2026-10-02

## Context
Phase 1 set GitHub Actions up to assume an IAM role through GitHub's OIDC provider
(`terraform/dev/github_oidc.tf`), so no long-lived AWS credentials lived in GitHub. The owner has
since switched the image pipelines in `sotto-api` and `sotto-web` to a stored IAM access key and
removed OIDC from how the repos authenticate.

## Decision
Workflows authenticate to AWS with an IAM access key kept as GitHub Actions secrets
(`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), plus the `AWS_REGION` and `ECR_REGISTRY`
variables. OIDC is not reintroduced.

## Consequences
- The key never appears in a repo, log or image; it lives only in GitHub secrets.
- The key's IAM user should hold only what the pipelines need (push to the `sotto/*` ECR
  repositories, run the `sotto-deploy` SSM document on the demo server, write the config bucket).
- Rotate the key on a schedule (90 days is a sensible default) and immediately if a runner or
  account is ever in doubt; GitHub secrets can be updated without touching any workflow.
- Follow-ups for the owner, deliberately left untouched by the agent:
  - `.github/workflows/deploy-config.yml` in this repo still uses `role-to-assume`; switch it to
    the access-key secrets when ready (and add the secrets to this repo).
  - `terraform/dev/github_oidc.tf` still creates the OIDC provider and `sotto-github-deploy` role,
    and `terraform output github_variables` still prints `AWS_ROLE_ARN`. Remove or keep them as a
    learning reference; nothing in the image pipelines depends on them now.
- Phase 10 (GitOps) revisits this: short-lived credentials are the production-grade target.
