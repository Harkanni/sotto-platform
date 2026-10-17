# Terraform

Two stacks:

| Stack | What it creates | State |
| --- | --- | --- |
| `bootstrap/` | The S3 bucket that stores Terraform state (versioned, encrypted, private) | Local, run once |
| `dev/` | Always-on demo server, optional workbench, ECR repos, S3 bucket, SSM secrets + deploy document, budget alert | S3, locked with a lockfile |

```mermaid
flowchart LR
  gh["GitHub Actions (main)"] -- "IAM access key (repo secrets)" --> aws["AWS APIs"]
  aws -- push --> ecr[("ECR sotto/*")]
  aws -- "SendCommand sotto-deploy" --> ssm["SSM Run Command"]
  ssm --> demo["EC2 · demo"]
  demo -- pull --> ecr
  demo -- "secrets" --> params[("SSM Parameter Store /sotto/demo")]
  demo -- "config, backups, files" --> s3[("S3 sotto-dev-<account>")]
  users["Browser"] -- "HTTPS · <ip>.sslip.io" --> demo
```

## First-time setup (about 20 minutes)

You need the AWS CLI (logged in as an admin user, **not** the root account), Terraform ≥ 1.10, and the GitHub CLI. [AWS CloudShell](https://console.aws.amazon.com/cloudshell) already has the AWS CLI; install Terraform there if you prefer not to use your laptop.

```bash
# 1. State bucket (once per AWS account)
cd terraform/bootstrap
terraform init && terraform apply

# 2. Point the dev stack at it
cd ../dev
cp backend.hcl.example backend.hcl            # put the bucket name from step 1 in it
cp terraform.tfvars.example terraform.tfvars  # put your email in it
terraform init -backend-config=backend.hcl
terraform plan                                # read it: ~35 resources, nothing destroyed
terraform apply

# 3. Once: the CI user and its key ("The CI key" below), then the repos' secrets
terraform output -raw github_secrets | sh     # needs `gh auth login` first

# 4. See it
terraform output demo_url
```

The first boot takes 3–5 minutes (Docker install, then Postgres, Redis, RabbitMQ and Caddy start). Until the app images are deployed, the URL says *"Sotto's demo is starting up"*. To deploy the apps, run the CI/CD workflow on `main` in sotto-api and sotto-web (Actions → CI/CD → Run workflow), or merge any PR. While the demo is down, `main` skips the deploy rather than failing.

## The CI key

GitHub Actions reaches AWS with one IAM user's access key, kept as repository secrets (ADR 0007, ADR 0034). That user is made once, by hand, outside this stack (`dev/ci.tf` says why): `terraform destroy` leaves its key alone, so CI can still see that the demo is down and skip the deploy, and the secrets stay the same from one session to the next. Terraform writes the user's policy; you attach it.

```bash
cd terraform/dev                              # with the stack applied
# The user, with exactly what CI needs (an existing CI user works too: skip create-user)
aws iam create-user --user-name sotto-ci
aws iam put-user-policy --user-name sotto-ci --policy-name sotto-ci \
  --policy-document "$(terraform output -raw ci_policy)"
# Its key: copy AccessKeyId and SecretAccessKey into terraform.tfvars
# (aws_access_key_id, aws_secret_access_key)
aws iam create-access-key --user-name sotto-ci
terraform apply                               # only the outputs change
terraform output -raw github_secrets | sh     # all three repos
```

To rotate: `create-access-key` again, swap the two values in `terraform.tfvars`, `terraform apply`, the same `| sh`, then `aws iam delete-access-key --user-name sotto-ci --access-key-id <old id>`. With no key in `terraform.tfvars`, `github_secrets` leaves the repos' key secrets alone and only sets the region, registry and bucket.

## Everyday

| Task | Command |
| --- | --- |
| Shell on the demo server (no SSH) | `terraform output -raw shell \| sh` |
| Logs | in the shell: `cd /opt/sotto && sudo docker compose logs -f api` |
| What's deployed | in the shell: `cat /opt/sotto/tags.env` |
| Redeploy by hand | in the shell: `sudo /opt/sotto/deploy.sh sha-<commit> api worker` |
| Start the workbench | `task workbench:start` (set `workbench_enabled = true` first) |
| Tear everything down | `terraform destroy` in `dev/` (the state bucket survives) |

## Costs (eu-west-2, approximate)

| Item | Per month |
| --- | --- |
| t4g.medium demo, 24/7 | ~$27 |
| 30 GB gp3 disk + public IPv4 | ~$6 |
| ECR, S3, SSM, KMS (light use) | ~$1–2 |
| Workbench m7i-flex.large | ~$0.11 per hour while running |
| **Total, demo only** | **~$35** |

So the $200 credit covers roughly five to six months. The budget alert emails you at 80% of $40 and when the month is forecast to exceed it. To spend less, stop the demo instance when you don't need it (the EIP keeps its address; you pay ~$4/month for it while stopped).

## Security notes

- No SSH and no port 22. Shells go through SSM Session Manager and are logged by AWS.
- CI reaches AWS with one IAM access key kept as GitHub Actions secrets (ADR 0007). Only the deploy jobs on `main` read it; pull requests, forks included, never do. Its IAM user should only push to `sotto/*` repositories, run the `sotto-deploy` document on the instance tagged `sotto-role=demo` (parameters are pattern-checked) and write the config bucket. Rotate it every 90 days or so.
- IMDSv2 is required and the hop limit is 1, so containers can't read the server's AWS credentials.
- Database and queue passwords are generated by Terraform and stored as SecureStrings. They also live in the state file, which is why the state bucket is private, encrypted and versioned.
