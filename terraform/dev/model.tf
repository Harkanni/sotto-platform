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

# Not every availability zone has every GPU type: pick a zone that offers it, then the default
# subnet there.
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
    values = data.aws_ec2_instance_type_offerings.model.locations
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
    description     = "vLLM's OpenAI-compatible API, from the app"
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
  subnet_id              = data.aws_subnets.model.ids[0]
  vpc_security_group_ids = [aws_security_group.model[0].id]
  iam_instance_profile   = aws_iam_instance_profile.model[0].name

  user_data = templatefile("${path.module}/user_data/model.sh.tftpl", {
    region     = var.region
    key_param  = aws_ssm_parameter.model_api_key[0].name
    model      = var.model_hf_id
    max_len    = var.model_max_len
    vllm_image = var.vllm_image
  })
  # A changed model or image means a fresh server: simplest way to apply it.
  user_data_replace_on_change = true

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2 # the host reads its key; containers don't need the role
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 200 # vLLM image (~10 GB) and the FP8 weights (~37 GB), with room to switch
    throughput  = 500 # loading 37 GB of weights is disk-bound
    iops        = 6000
    encrypted   = true
  }

  tags = {
    Name       = "sotto-model"
    sotto-role = "model"
  }
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
