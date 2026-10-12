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
  # No files/ access here: only the host uses this role, and the host never touches uploads.
  # The app (in containers, which can't reach this role) has its own keys: app_storage.tf.
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

  # Burstable (t*) types only: never bill for burst above the baseline. Other families have no
  # credits, and AWS refuses the setting for them.
  dynamic "credit_specification" {
    for_each = startswith(var.demo_instance_type, "t") ? [1] : []
    content {
      cpu_credits = "standard"
    }
  }

  metadata_options {
    http_tokens                 = "required" # IMDSv2 only (blocks a classic SSRF credential theft)
    http_put_response_hop_limit = 1          # containers can't reach the instance's credentials (the app has its own: ADR 0018)
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.demo_volume_gb # grows in place; the OS extends the filesystem on boot
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

# A fixed public IP, so the sslip.io name (and later the DNS record) never changes while the
# instance stops and starts. Terraform's own EIP is released by `terraform destroy`; to keep one
# address for good, allocate an EIP yourself and set demo_eip_allocation_id (it's then only
# attached, never released).
resource "aws_eip" "demo" {
  count  = var.demo_eip_allocation_id == "" ? 1 : 0
  domain = "vpc"
  tags   = { Name = "sotto-demo" }
}

data "aws_eip" "kept" {
  count = var.demo_eip_allocation_id == "" ? 0 : 1
  id    = var.demo_eip_allocation_id
}

locals {
  demo_eip_id    = var.demo_eip_allocation_id == "" ? aws_eip.demo[0].id : data.aws_eip.kept[0].id
  demo_public_ip = var.demo_eip_allocation_id == "" ? aws_eip.demo[0].public_ip : data.aws_eip.kept[0].public_ip
}

resource "aws_eip_association" "demo" {
  instance_id   = aws_instance.demo.id
  allocation_id = local.demo_eip_id
}

# Moving the existing EIP into the counted resource without releasing it.
moved {
  from = aws_eip.demo
  to   = aws_eip.demo[0]
}
