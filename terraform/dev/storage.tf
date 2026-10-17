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
  # Uploads abandoned half-way leave invisible parts that S3 still bills for. Sotto cancels
  # them itself when it can; this sweeps up whatever is left (a closed laptop, a crash).
  rule {
    id     = "abort-abandoned-uploads"
    status = "Enabled"
    filter {
      prefix = "files/"
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Browsers upload and play files straight from S3 with presigned URLs (Phase 4), so the bucket
# must allow the demo's origin. ETag is exposed because the browser sends each part's ETag back
# to finish an upload; Range lets the player seek inside a recording.
resource "aws_s3_bucket_cors_configuration" "dev" {
  bucket = aws_s3_bucket.dev.id
  cors_rule {
    allowed_methods = ["GET", "PUT", "HEAD"]
    allowed_origins = ["https://${local.site_address}"]
    allowed_headers = ["Content-Type", "Range"]
    expose_headers  = ["ETag", "Content-Length", "Content-Range", "Accept-Ranges"]
    max_age_seconds = 3600
  }
}

# Upload the demo deploy files. Editing a file in deploy/demo and re-applying (or merging to
# main, which runs pipeline.yml's deploy-config job) is how config changes reach the server.
resource "aws_s3_object" "demo_config" {
  for_each = fileset("${path.module}/../../deploy/demo", "*")
  bucket   = aws_s3_bucket.dev.id
  key      = "demo/${each.value}"
  source   = "${path.module}/../../deploy/demo/${each.value}"
  etag     = filemd5("${path.module}/../../deploy/demo/${each.value}")
}
