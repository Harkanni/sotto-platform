output "demo_url" {
  value = "https://${local.site_address}"
}

output "demo_instance_id" {
  value = aws_instance.demo.id
}

output "workbench_instance_id" {
  value = var.workbench_enabled ? aws_instance.workbench[0].id : ""
}

output "github_secrets" {
  description = "Run these once (GitHub CLI) to configure AWS credentials and deployment settings for the repos."
  sensitive   = true

  value = join("\n", flatten([
    for repo in var.github_repos : [
      "gh secret set AWS_ACCESS_KEY_ID --repo ${var.github_owner}/${repo} --body '${var.aws_access_key_id}'",
      "gh secret set AWS_SECRET_ACCESS_KEY --repo ${var.github_owner}/${repo} --body '${var.aws_secret_access_key}'",
      "gh secret set AWS_REGION --repo ${var.github_owner}/${repo} --body '${var.region}'",
      "gh secret set ECR_REGISTRY --repo ${var.github_owner}/${repo} --body '${local.ecr_registry}'",
      "gh secret set CONFIG_BUCKET --repo ${var.github_owner}/${repo} --body '${aws_s3_bucket.dev.bucket}'",
    ]
  ]))
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
