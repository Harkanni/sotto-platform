# 0018 — The demo's app containers sign S3 requests with their own scoped key

- **Status:** accepted
- **Date:** 2026-10-09

## Context

Phase 4 put uploaded files in the dev bucket's `files/` prefix and assumed "the server's IAM role
signs every request". It can't: since Phase 1 the demo server requires IMDSv2 with a hop limit of
1 (`terraform/dev/demo.tf`), so instance-role credentials never reach a Docker container. The
api, worker and transcriber had no credentials at all, and every upload failed at its first
storage call ("Something went wrong on our side"). The deploy stayed green because the api's
readiness check didn't include storage.

Two ways out: raise the hop limit to 2 (AWS's usual advice for containers), or give the app its
own credentials. The instance role can read every demo secret in SSM, and a hop limit of 2 would
hand it to every container, including the public-facing web app and Mailpit.

## Decision

- Keep the hop limit at 1. The instance role keeps only what the host needs (config sync,
  backups, secrets, ECR); its `files/` access is removed.
- Terraform creates an IAM user, `sotto-demo-app`, allowed only `files/*` (get, put, delete,
  abort and list multipart parts) and `ListBucket`; its access key goes to SSM as
  `/sotto/demo/S3_ACCESS_KEY_ID` and `/sotto/demo/S3_SECRET_ACCESS_KEY`. `deploy.sh` already turns
  `/sotto/demo/*` into the server's `.env`; Compose passes the two values to the api, worker and
  transcriber, whose storage clients use them when set.
- The api's readiness check includes storage, so a deploy that can't reach the bucket fails
  instead of going green.

## Consequences

- A long-lived key, like CI's (ADR 0007): rotate with
  `terraform apply -replace=aws_iam_access_key.app_files`, then re-run `deploy-config`.
- Presigned upload and playback URLs stay valid for their whole lifetime (a role session can
  expire first).
- Phase 11 (EKS) replaces this with per-service roles (EKS Pod Identity), and the key goes.
