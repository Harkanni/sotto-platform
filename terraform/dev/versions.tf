terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  # Partial config: the bucket name lives in backend.hcl (see backend.hcl.example), because it
  # contains your account id. `terraform init -backend-config=backend.hcl`
  backend "s3" {
    key          = "dev/terraform.tfstate"
    use_lockfile = true # native S3 locking, no DynamoDB
    encrypt      = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { project = "sotto", env = "dev", managed-by = "terraform" }
  }
}
