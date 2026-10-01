output "demo_url" {
  value = "https://${local.site_address}"
}

output "demo_instance_id" {
  value = aws_instance.demo.id
}

output "workbench_instance_id" {
  value = var.workbench_enabled ? aws_instance.workbench[0].id : ""
}

output "github_variables" {
  description = "Run these once (GitHub CLI) so the repos' images and deploy workflows switch on."
  value = join("\n", flatten([for repo in var.github_repos : [
    "gh variable set AWS_ROLE_ARN --repo ${var.github_owner}/${repo} --body '${aws_iam_role.github_deploy.arn}'",
    "gh variable set AWS_REGION --repo ${var.github_owner}/${repo} --body '${var.region}'",
    "gh variable set ECR_REGISTRY --repo ${var.github_owner}/${repo} --body '${local.ecr_registry}'",
    "gh variable set CONFIG_BUCKET --repo ${var.github_owner}/${repo} --body '${aws_s3_bucket.dev.bucket}'",
  ]]))
}

output "shell" {
  description = "Open a shell on the demo server (needs the Session Manager plugin for the AWS CLI)."
  value       = "aws ssm start-session --region ${var.region} --target ${aws_instance.demo.id}"
}
