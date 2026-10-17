output "demo_url" {
  value = "https://${local.site_address}"
}

output "demo_instance_id" {
  value = aws_instance.demo.id
}

output "workbench_instance_id" {
  value = var.workbench_enabled ? aws_instance.workbench[0].id : ""
}

locals {
  # The key secrets only when terraform.tfvars holds the CI user's key. Printed with empty values
  # and piped to `sh`, they would blank the working key the repos already have.
  ci_key_set = var.aws_access_key_id != "" && var.aws_secret_access_key != ""
  github_key_secrets = local.ci_key_set ? flatten([
    for repo in var.github_repos : [
      "gh secret set AWS_ACCESS_KEY_ID --repo ${var.github_owner}/${repo} --body '${var.aws_access_key_id}'",
      "gh secret set AWS_SECRET_ACCESS_KEY --repo ${var.github_owner}/${repo} --body '${var.aws_secret_access_key}'",
    ]
  ]) : ["echo 'No CI key in terraform.tfvars: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY left as they are.' >&2"]
  github_config_secrets = flatten([
    for repo in var.github_repos : [
      "gh secret set AWS_REGION --repo ${var.github_owner}/${repo} --body '${var.region}'",
      "gh secret set ECR_REGISTRY --repo ${var.github_owner}/${repo} --body '${local.ecr_registry}'",
      "gh secret set CONFIG_BUCKET --repo ${var.github_owner}/${repo} --body '${aws_s3_bucket.dev.bucket}'",
    ]
  ])
}

output "github_secrets" {
  description = "Commands (GitHub CLI) that set the AWS key and deploy settings as secrets in the three repos: terraform output -raw github_secrets | sh"
  sensitive   = true
  value       = join("\n", concat(local.github_key_secrets, local.github_config_secrets))
}

output "shell" {
  description = "Open a shell on the demo server (needs the Session Manager plugin for the AWS CLI)."
  value       = "aws ssm start-session --region ${var.region} --target ${aws_instance.demo.id}"
}

output "demo_mail_url" {
  description = "Where the demo's emails land until SES is set up (user: sotto)"
  value       = "https://${local.site_address}/mail/"
}

output "demo_mail_password" {
  description = "Password for the demo's mailbox (terraform output -raw demo_mail_password)"
  value       = random_password.mailpit.result
  sensitive   = true
}

output "model_server" {
  description = "The GPU model server: its private address, and how to watch it start."
  value = var.model_server_enabled ? {
    instance_id = aws_instance.model[0].id
    private_url = "http://${aws_instance.model[0].private_ip}:8000/v1"
    logs        = "aws ssm start-session --region ${var.region} --target ${aws_instance.model[0].id}  # then: sudo docker logs -f vllm"
  } : null
}
