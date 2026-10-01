# ── The on-demand workbench (off by default: set workbench_enabled = true) ───────────────────
# 8 GB x86 server for running Private-mode models (Ollama) and, from Phase 9, a dev Kubernetes
# cluster. Start it when you need it (`task workbench:start`); it stops itself after an hour of
# low CPU, so a forgotten workbench costs pennies, not dollars.

resource "aws_security_group" "workbench" {
  count       = var.workbench_enabled ? 1 : 0
  name        = "sotto-workbench"
  description = "No inbound at all; use SSM Session Manager"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "workbench" {
  count                  = var.workbench_enabled ? 1 : 0
  ami                    = data.aws_ssm_parameter.al2023_x86_64.value
  instance_type          = var.workbench_instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.workbench[0].id]
  iam_instance_profile   = aws_iam_instance_profile.server.name
  user_data              = file("${path.module}/user_data/workbench.sh")

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 60 # model weights and container images
    encrypted   = true
  }

  tags = {
    Name       = "sotto-workbench"
    sotto-role = "workbench"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_cloudwatch_metric_alarm" "workbench_idle" {
  count               = var.workbench_enabled ? 1 : 0
  alarm_name          = "sotto-workbench-idle-stop"
  alarm_description   = "Stop the workbench after 60 minutes under 3% CPU"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = aws_instance.workbench[0].id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 12
  threshold           = 3
  comparison_operator = "LessThanThreshold"
  alarm_actions       = ["arn:aws:automate:${var.region}:ec2:stop"]
}
