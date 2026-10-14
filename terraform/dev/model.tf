# The demo's private chat model on its own GPU server (ADR 0032): vLLM serving Qwen3.6-35B-A3B
# in FP8 on one NVIDIA L40S. The app server reaches it over the VPC's private network, so
# questions never leave your AWS account: it counts as Private, like Ollama did.
#
# Why a separate server: GPU instances are x86 and the app images are arm64; the model can be
# stopped or resized on its own; and Phase 9's Kubernetes will want it as its own node anyway.

# AWS's Deep Learning base image: NVIDIA driver, CUDA, Docker and the NVIDIA container toolkit
# preinstalled, so the server only has to start vLLM.
data "aws_ssm_parameter" "gpu_ami" {
  name = "/aws/service/deeplearning/ami/x86_64/base-oss-nvidia-driver-gpu-ubuntu-22.04/latest/ami-id"
}

# The model cache from the "keep" stack (terraform/keep, ADR 0033), if it exists: images and
# weights that survive `terraform destroy`, so a new model server starts in minutes.
data "aws_ebs_volumes" "model_cache" {
  filter {
    name   = "tag:Name"
    values = ["sotto-model-cache"]
  }
}

data "aws_ebs_volume" "model_cache" {
  count = length(data.aws_ebs_volumes.model_cache.ids) > 0 ? 1 : 0
  filter {
    name   = "volume-id"
    values = [data.aws_ebs_volumes.model_cache.ids[0]]
  }
}

locals {
  model_cache_id = try(data.aws_ebs_volume.model_cache[0].id, "")
  model_cached   = local.model_cache_id != ""
}

# Not every availability zone has every GPU type: pick a zone that offers it (the cache's zone
# when there's a cache: a volume only attaches in its own zone), then the default subnet there.
data "aws_ec2_instance_type_offerings" "model" {
  location_type = "availability-zone"
  filter {
    name   = "instance-type"
    values = [var.model_instance_type]
  }
}

data "aws_subnets" "model" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    # "none" when no zone offers the type: an empty filter would match every subnet.
    values = local.model_cached ? [data.aws_ebs_volume.model_cache[0].availability_zone] : coalescelist(data.aws_ec2_instance_type_offerings.model.locations, ["none"])
  }
}

# Only the app server may call the model: port 8000 from the demo's security group, nothing
# from the internet. Outbound is open to pull the image and the weights.
resource "aws_security_group" "model" {
  count       = var.model_server_enabled ? 1 : 0
  name_prefix = "sotto-model-"
  description = "vLLM: reachable only from the demo server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "vLLM OpenAI-compatible API from the app server"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.demo.id]
  }

  egress {
    description = "Image and model downloads"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# A key between the app and vLLM, on top of the security group (defence in depth). It reaches
# the app's .env through SSM like every other setting.
resource "random_password" "model_api_key" {
  length  = 40
  special = false
}

resource "aws_ssm_parameter" "model_api_key" {
  count = var.model_server_enabled ? 1 : 0
  name  = "/sotto/demo/AI_OPENAI_COMPATIBLE_KEY"
  type  = "SecureString"
  value = random_password.model_api_key.result
}

# The model server only needs Session Manager (to look at it) and to read its key.
resource "aws_iam_role" "model" {
  count              = var.model_server_enabled ? 1 : 0
  name_prefix        = "sotto-model-"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "model_ssm_core" {
  count      = var.model_server_enabled ? 1 : 0
  role       = aws_iam_role.model[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "model_key" {
  count = var.model_server_enabled ? 1 : 0
  role  = aws_iam_role.model[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = aws_ssm_parameter.model_api_key[0].arn
    }]
  })
}

resource "aws_iam_instance_profile" "model" {
  count       = var.model_server_enabled ? 1 : 0
  name_prefix = "sotto-model-"
  role        = aws_iam_role.model[0].name
}

resource "aws_instance" "model" {
  count                  = var.model_server_enabled ? 1 : 0
  ami                    = data.aws_ssm_parameter.gpu_ami.value
  instance_type          = var.model_instance_type
  subnet_id              = try(data.aws_subnets.model.ids[0], null)
  vpc_security_group_ids = [aws_security_group.model[0].id]
  iam_instance_profile   = aws_iam_instance_profile.model[0].name

  user_data = templatefile("${path.module}/user_data/model.sh.tftpl", {
    region     = var.region
    key_param  = aws_ssm_parameter.model_api_key[0].name
    model      = var.model_hf_id
    max_len    = var.model_max_len
    vllm_image = var.vllm_image
    cache_id   = local.model_cache_id
  })
  # A changed model or image means a fresh server: simplest way to apply it.
  user_data_replace_on_change = true

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2 # the host reads its key; containers don't need the role
  }

  # With the cache, images and weights live there and the root disk stays small. Without it,
  # the root disk holds them (~60 GB) and is fast, because loading the weights is disk-bound.
  root_block_device {
    volume_type = "gp3"
    volume_size = local.model_cached ? 60 : 200
    throughput  = local.model_cached ? 125 : 500
    iops        = local.model_cached ? 3000 : 6000
    encrypted   = true
  }

  lifecycle {
    precondition {
      condition     = length(data.aws_subnets.model.ids) > 0
      error_message = "No availability zone in this region offers ${var.model_instance_type} (or the model cache's zone doesn't). Pick another model_instance_type, or set model_server_enabled = false."
    }
  }

  tags = {
    Name       = "sotto-model"
    sotto-role = "model"
  }
}

resource "aws_volume_attachment" "model_cache" {
  count       = var.model_server_enabled && local.model_cached ? 1 : 0
  device_name = "/dev/sdf"
  volume_id   = local.model_cache_id
  instance_id = aws_instance.model[0].id

  # Stop the server before detaching on destroy, so the cache is never left half-written.
  stop_instance_before_detaching = true
}

# What the app needs to reach it. deploy.sh writes these into the demo's .env.
resource "aws_ssm_parameter" "model_url" {
  count = var.model_server_enabled ? 1 : 0
  name  = "/sotto/demo/AI_OPENAI_COMPATIBLE_URL"
  type  = "String"
  value = "http://${aws_instance.model[0].private_ip}:8000/v1"
}

resource "aws_ssm_parameter" "private_chat" {
  count = var.model_server_enabled ? 1 : 0
  name  = "/sotto/demo/AI_PRIVATE_CHAT"
  type  = "String"
  value = "openai-compatible:sotto-chat" # vLLM's --served-model-name
}

# Answers start at once: Qwen3.6 reasons silently first unless told not to (ADR 0032).
resource "aws_ssm_parameter" "chat_extra" {
  count = var.model_server_enabled ? 1 : 0
  name  = "/sotto/demo/AI_OPENAI_COMPATIBLE_CHAT_EXTRA"
  type  = "String"
  value = jsonencode({ chat_template_kwargs = { enable_thinking = false } })
}
