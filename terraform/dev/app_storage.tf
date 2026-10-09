# ── The app's own credentials for uploaded files (ADR 0018) ───────────────────────────────────
# The api, worker and transcriber run in Docker on the demo server, and Docker containers can't
# reach the instance's IAM role: IMDSv2 with a hop limit of 1 (demo.tf). That is on purpose —
# the role can read every demo secret in SSM. So the app gets its own IAM user, allowed only the
# bucket's files/ prefix, and its keys reach the containers through SSM like every other secret
# (deploy.sh writes /sotto/demo/* into the server's .env).
#
# A static key also suits presigned URLs: a URL signed with the role's short-lived session stops
# working when that session ends, which can be sooner than the hour an upload part is given.
# Rotate: `terraform apply -replace=aws_iam_access_key.app_files`, then re-run deploy-config.
resource "aws_iam_user" "app_files" {
  name = "sotto-demo-app"
  path = "/sotto/"
}

data "aws_iam_policy_document" "app_files" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"] # also turns a missing object into 404 instead of 403
    resources = [aws_s3_bucket.dev.arn]
  }
  statement {
    sid = "AppFiles"
    # PutObject covers multipart create/part/complete; ListMultipartUploadParts resumes uploads.
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
      "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts",
    ]
    resources = ["${aws_s3_bucket.dev.arn}/files/*"]
  }
}

resource "aws_iam_user_policy" "app_files" {
  name   = "files-prefix-only"
  user   = aws_iam_user.app_files.name
  policy = data.aws_iam_policy_document.app_files.json
}

resource "aws_iam_access_key" "app_files" {
  user = aws_iam_user.app_files.name
}

# The names match what the app reads (S3_ACCESS_KEY_ID / S3_SECRET_ACCESS_KEY), so deploy.sh's
# "every parameter under /sotto/demo/ becomes NAME=value" is all the wiring there is.
resource "aws_ssm_parameter" "s3_access_key_id" {
  name  = "/sotto/demo/S3_ACCESS_KEY_ID"
  type  = "SecureString"
  value = aws_iam_access_key.app_files.id
}

resource "aws_ssm_parameter" "s3_secret_access_key" {
  name  = "/sotto/demo/S3_SECRET_ACCESS_KEY"
  type  = "SecureString"
  value = aws_iam_access_key.app_files.secret
}
