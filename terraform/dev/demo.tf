# ── The always-on demo server ─────────────────────────────────────────────────────────────────
# No SSH: port 22 stays closed. You get a shell with `aws ssm start-session --target <id>`, and
# deploys arrive through the sotto-deploy SSM document.

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "server" {
  name               = "sotto-dev-server"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # Session Manager + Run Command
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy_document" "server" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.dev.arn]
  }
  statement {
    sid       = "ReadDeployConfig"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.dev.arn}/demo/*"]
  }
  statement {
    sid       = "WriteBackups"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.dev.arn}/backups/*"]
  }
  statement {
    sid       = "AppFiles"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload"]
    resources = ["${aws_s3_bucket.dev.arn}/files/*"]
  }
  statement {
    sid       = "ReadDemoSecrets"
    actions   = ["ssm:GetParametersByPath", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${var.region}:${local.account_id}:parameter/sotto/demo*"]
  }
}

resource "aws_iam_role_policy" "server" {
  role   = aws_iam_role.server.id
  policy = data.aws_iam_policy_document.server.json
}

resource "aws_iam_instance_profile" "server" {
  name = "sotto-dev-server"
  role = aws_iam_role.server.name
}

resource "aws_security_group" "demo" {
  name        = "sotto-demo"
  description = "HTTPS in for the demo; no SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "HTTP: redirect to HTTPS and ACME challenges"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "HTTP/3"
    from_port        = 443
    to_port          = 443
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    description      = "Pull images, reach AWS APIs and ACME"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "demo" {
  ami                    = data.aws_ssm_parameter.al2023_arm64.value
  instance_type          = var.demo_instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.demo.id]
  iam_instance_profile   = aws_iam_instance_profile.server.name

  user_data = templatefile("${path.module}/user_data/demo.sh.tftpl", {
    region       = var.region
    bucket       = aws_s3_bucket.dev.bucket
    ecr_registry = local.ecr_registry
  })

  credit_specification {
    cpu_credits = "standard" # never bill for burst above the baseline; the demo is mostly idle
  }

  metadata_options {
    http_tokens                 = "required" # IMDSv2 only (blocks a classic SSRF credential theft)
    http_put_response_hop_limit = 1          # containers can't reach the instance's credentials
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = {
    Name       = "sotto-demo"
    sotto-role = "demo" # the deploy role may only target instances with this tag
  }

  # Don't rebuild the server just because AWS published a newer AMI or the bootstrap script
  # changed; config changes arrive through deploy.sh instead.
  lifecycle {
    ignore_changes = [ami, user_data]
  }

  depends_on = [aws_s3_object.demo_config, aws_ssm_parameter.postgres_password, aws_ssm_parameter.rabbitmq_password]
}

# A fixed public IP, so the sslip.io name (and later the DNS record) never changes.
resource "aws_eip" "demo" {
  domain = "vpc"
  tags   = { Name = "sotto-demo" }
}

resource "aws_eip_association" "demo" {
  instance_id   = aws_instance.demo.id
  allocation_id = aws_eip.demo.id
}
