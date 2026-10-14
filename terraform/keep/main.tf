# The "keep" stack: the few things worth keeping between build-and-test sessions, so
# `terraform destroy` in terraform/dev doesn't throw them away. Apply once; don't destroy it
# unless you mean to lose them.
#
#   - the model cache: one EBS volume holding the GPU server's Docker images (vLLM, ~20 GB) and
#     the model weights (~37 GB). A fresh model server attaches it and starts in a few minutes
#     instead of downloading everything again (ADR 0033).
#   - the demo's public IP: an Elastic IP, so the sslip.io address (and the OAuth redirect URLs
#     built on it) stays the same every session.
#   - the image repositories (ecr.tf): Jenkins pushes to them from main even while the demo is
#     down, and a new demo pulls the latest images from them.
#
# terraform/dev finds both by their Name tags; with this stack absent it works as before.
#
#   cd terraform/keep && terraform init -backend-config=../dev/backend.hcl && terraform apply

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Same state bucket as terraform/dev (backend.hcl), its own key.
  backend "s3" {
    key          = "keep/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { project = "sotto", env = "keep", managed-by = "terraform" }
  }
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "model_instance_type" {
  description = "The GPU type terraform/dev uses: the cache goes in a zone that offers it."
  type        = string
  default     = "g6e.xlarge"
}

variable "model_cache_gb" {
  description = "Images (~20 GB) and weights (~37 GB) with room for one more model."
  type        = number
  default     = 100
}

variable "model_cache_throughput" {
  description = <<-EOT
    MB/s. gp3 includes 125; each extra MB/s is billed monthly. 250 loads the weights in about
    2.5 minutes for a few dollars a month.
  EOT
  type        = number
  default     = 250
}

# EBS volumes live in one availability zone, and the GPU server must start in the same one:
# pick (deterministically) a zone that offers the GPU type.
data "aws_ec2_instance_type_offerings" "model" {
  location_type = "availability-zone"
  filter {
    name   = "instance-type"
    values = [var.model_instance_type]
  }
}

resource "aws_ebs_volume" "model_cache" {
  availability_zone = sort(data.aws_ec2_instance_type_offerings.model.locations)[0]
  type              = "gp3"
  size              = var.model_cache_gb
  throughput        = var.model_cache_throughput
  iops              = 3000 # gp3's included baseline
  encrypted         = true

  tags = { Name = "sotto-model-cache" }
}

resource "aws_eip" "demo" {
  domain = "vpc"
  tags   = { Name = "sotto-demo-kept" }
}

output "model_cache_volume" {
  value = { id = aws_ebs_volume.model_cache.id, zone = aws_ebs_volume.model_cache.availability_zone }
}

output "demo_ip" {
  description = "The demo's address for good: https://<ip with dashes>.sslip.io"
  value       = aws_eip.demo.public_ip
}
