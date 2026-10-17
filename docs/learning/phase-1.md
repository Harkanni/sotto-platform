# Learning notes — Phase 1

What this phase used, why, and some drills to break things on purpose (then fix them).

## Concepts

| Concept                         | Where you'll find it                              | Why it matters                                                                                                    |
| ------------------------------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Multi-stage Docker builds       | `sotto-api/Dockerfile`, `sotto-web/Dockerfile`    | Compilers and dev deps stay out of the runtime image: smaller, fewer CVEs                                         |
| Non-root containers             | `USER node`, `USER 10001`                         | A compromised process can't modify the image or bind privileged ports                                             |
| Liveness vs readiness           | `/healthz` vs `/readyz`                           | Liveness failures restart a container; readiness failures only stop traffic. Mixing them up causes restart storms |
| Compose `depends_on` conditions | `local/compose.yaml`                              | `service_healthy` / `service_completed_successfully` ordering: the api waits for migrations                       |
| Reverse proxy, one origin       | `Caddyfile`                                       | `/api/*` and `/` on one host means no CORS and simpler cookies                                                    |
| ~~GitHub OIDC → AWS~~           | removed (ADR 0007: access keys in GitHub secrets) | Was: no long-lived AWS keys in GitHub; tokens per run, scoped to `main`                                           |
| SSM Run Command instead of SSH  | `aws_ssm_document.deploy`                         | No open port 22, every command audited, parameters validated                                                      |
| Remote state with locking       | `backend "s3" { use_lockfile = true }`            | Two applies can't corrupt state; versioning lets you roll back                                                    |
| IMDSv2 + hop limit 1            | `metadata_options`                                | Blocks SSRF-style credential theft and keeps containers away from instance credentials                            |
| Budgets                         | `budget.tf`                                       | The cheapest outage is the one that emails you before the bill does                                               |

## Commands to try

```bash
task up && task ps                          # whole stack locally (or on the workbench)
curl -s localhost:4000/readyz | jq          # readiness with per-dependency timings
docker compose -f local/compose.yaml stop redis && curl -i localhost:4000/readyz   # → 503
docker inspect --format '{{json .State.Health}}' sotto-api-1 | jq
terraform plan                              # read every line before apply
aws ssm list-commands --max-items 5         # see recent deploys
```

## Break-and-fix drills

1. **Readiness lies.** In `sotto-api/apps/api/src/health/checks.ts`, make `RedisCheck.check()` return without pinging. Stop Redis. What does `/readyz` say now, and what would a load balancer do with that? Revert it, and write a test that would have caught it.
2. **Migration race.** In `local/compose.yaml`, change the api's `migrate` condition to `service_started`. Run `task reset && task up` a few times. Why does the api sometimes crash, and why is `service_completed_successfully` the right fix?
3. **OOM on the demo.** On the demo server, lower the worker's memory limit in `/opt/sotto/compose.yaml` to `16m` and run `sudo docker compose up -d worker`. Find the evidence (`docker inspect`, `dmesg`), then put the limit back. (Prove to yourself why every service has a limit.)
4. **Locked out of state.** Run `terraform plan` in two terminals at once. Read the lock error, and find the lockfile in the state bucket.
