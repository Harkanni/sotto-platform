# What GitHub Actions may do in AWS (ADR 0007, ADR 0034): push the sotto/* images, run the
# sotto-deploy document on the demo server, publish deploy/demo to the config bucket, and look
# up whether the demo is up at all.
#
# Why the CI user isn't a resource in this stack: `terraform destroy` would delete its key along
# with everything else. CI couldn't then reach AWS to see that the demo is down, so main's deploy
# jobs would fail instead of skipping, and every apply would mint a new key to copy into three
# repos. So the user is made once, by hand, and its key outlives destroy and apply. This file only
# writes the policy that user should have:
#   aws iam put-user-policy --user-name sotto-ci --policy-name sotto-ci \
#     --policy-document "$(terraform output -raw ci_policy)"
# The ARNs are built from names, not from resources, so the policy stays valid across a destroy
# and apply (same names, same account).
data "aws_iam_policy_document" "ci" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  # DescribeRepositories: "is the demo up?" (no sotto/api repository means it's been destroyed).
  statement {
    sid = "EcrPushAndLookUp"
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories", "ecr:GetDownloadUrlForLayer", "ecr:InitiateLayerUpload",
      "ecr:PutImage", "ecr:UploadLayerPart",
    ]
    resources = ["arn:aws:ecr:${var.region}:${local.account_id}:repository/sotto/*"]
  }
  # The other half of "is the demo up?": a running instance tagged sotto-role=demo.
  statement {
    sid       = "FindTheDemoServer"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
  statement {
    sid       = "RunDeployDocument"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:${var.region}:${local.account_id}:document/sotto-deploy"]
  }
  statement {
    sid       = "OnlyOnTheDemoServer"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:${var.region}:${local.account_id}:instance/*"]
    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/sotto-role"
      values   = ["demo"]
    }
  }
  statement {
    sid       = "WatchCommands"
    actions   = ["ssm:ListCommands", "ssm:ListCommandInvocations", "ssm:GetCommandInvocation"]
    resources = ["*"]
  }
  statement {
    sid       = "PublishDeployConfig"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}/demo/*"]
  }
}

# Minified: one line at the end of every apply instead of sixty.
output "ci_policy" {
  description = "The CI user's policy (JSON), for aws iam put-user-policy: see terraform/README.md, The CI key"
  value       = data.aws_iam_policy_document.ci.minified_json
}
