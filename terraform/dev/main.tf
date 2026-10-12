data "aws_caller_identity" "current" {}

# Phase 1 uses the account's default VPC to keep cost and moving parts low: one public server,
# no NAT gateway. Phase 11 builds a proper VPC (public/private subnets across AZs) for EKS.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# Latest Amazon Linux 2023 images, looked up from AWS's public SSM parameters.
data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

data "aws_ssm_parameter" "al2023_x86_64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  ecr_registry = "${local.account_id}.dkr.ecr.${var.region}.amazonaws.com"
  bucket_name  = "sotto-dev-${local.account_id}"
  services     = ["web", "api", "worker", "transcriber"]
  site_address = var.domain != "" ? "demo.${var.domain}" : "${replace(local.demo_public_ip, ".", "-")}.sslip.io"
}
