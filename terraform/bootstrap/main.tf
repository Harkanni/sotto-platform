# One-time stack: the S3 bucket that holds Terraform state for every other stack.
# It uses local state (the bucket can't store its own state before it exists). Run once:
#   cd terraform/bootstrap && terraform init && terraform apply
# Why S3 with native locking: Terraform 1.10+ can lock with a lockfile in the bucket itself,
# so no DynamoDB table is needed.

terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { project = "sotto", stack = "bootstrap", managed-by = "terraform" }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" {
  # Bucket names are global, so the account id keeps this one unique.
  bucket = "sotto-tfstate-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true # losing state means Terraform forgets what it built
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled" # lets you recover an older state file after a bad apply
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}

output "next_step" {
  value = "Copy terraform/dev/backend.hcl.example to backend.hcl and set bucket = \"${aws_s3_bucket.state.bucket}\"."
}
