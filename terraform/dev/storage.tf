# One private bucket for the dev environment, split by prefix:
#   demo/     deploy files (compose, Caddyfile, scripts) the demo server syncs on each deploy
#   backups/  nightly Postgres dumps (kept 14 days)
#   files/    uploaded documents and recordings (from Phase 4)
resource "aws_s3_bucket" "dev" {
  bucket        = local.bucket_name
  force_destroy = true # dev only
}

resource "aws_s3_bucket_public_access_block" "dev" {
  bucket                  = aws_s3_bucket.dev.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms" # AWS-managed KMS key; customer files are confidential by default
    }
    bucket_key_enabled = true # far fewer KMS calls, so it stays cheap
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id
  rule {
    id     = "expire-backups"
    status = "Enabled"
    filter {
      prefix = "backups/"
    }
    expiration {
      days = 14
    }
  }
}

# Upload the demo deploy files. Editing a file in deploy/demo and re-applying (or merging to
# main, which runs the deploy-config workflow) is how config changes reach the server.
resource "aws_s3_object" "demo_config" {
  for_each = fileset("${path.module}/../../deploy/demo", "*")
  bucket   = aws_s3_bucket.dev.id
  key      = "demo/${each.value}"
  source   = "${path.module}/../../deploy/demo/${each.value}"
  etag     = filemd5("${path.module}/../../deploy/demo/${each.value}")
}
