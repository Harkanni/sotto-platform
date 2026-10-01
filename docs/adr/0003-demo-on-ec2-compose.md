# 0003 — Always-on demo: one EC2 server with Docker Compose

- **Status:** accepted
- **Date:** 2026-10-01

## Context
The owner wants progress visible from Phase 1, develops on AWS (laptop is busy), and has about $200 of credits. EKS comes much later (Phase 11).

## Decision
- **Demo:** t4g.medium (4 GB, ARM) in eu-west-2, always on, running the stack in Docker Compose behind Caddy (automatic HTTPS; `<ip>.sslip.io` until `sotto.ai` is bought).
- **Workbench:** m7i-flex.large (8 GB), on demand, stops itself after an hour idle; for Private-mode models and, later, the dev Kubernetes cluster.
- Images build on GitHub's arm64 runners, push to ECR through GitHub OIDC (no long-lived keys), and deploy through SSM Run Command (no SSH).
- Secrets live in SSM Parameter Store under `/sotto/demo/`.

## Consequences
- About $30/month, with an AWS Budgets alert at $30.
- Postgres runs in a container on the demo box, with a nightly `pg_dump` to S3; not production-grade, which is fine for a demo.
