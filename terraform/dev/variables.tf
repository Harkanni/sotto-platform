variable "region" {
  description = "AWS region. London is closest to Lagos among the regions with every service we use."
  type        = string
  default     = "eu-west-2"
}

variable "github_owner" {
  description = "GitHub user or org that owns the repos (case as GitHub shows it)."
  type        = string
  default     = "Harkanni"
}

variable "github_repos" {
  description = "Repos whose main-branch workflows may push images and trigger deploys."
  type        = list(string)
  default     = ["sotto-web", "sotto-api", "sotto-platform"]
}

variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
}

variable "alert_email" {
  description = "Where AWS Budgets sends cost alerts. Set it in terraform.tfvars."
  type        = string
  default     = "sendaraven2@gmail.com"
}

variable "monthly_budget_usd" {
  description = "Alert threshold. The demo on m7g.2xlarge runs about $300 a month on its own."
  type        = number
  default     = 350
}

variable "demo_instance_type" {
  description = <<-EOT
    ARM (Graviton), because the images are built for linux/arm64. m7g.2xlarge (8 vCPU, 32 GB)
    runs the whole stack with real AI: Ollama with an 8B chat model and the embedding model,
    and faster-whisper, with room to spare (ADR 0031). t4g.medium (4 GB) only fits the
    labelled mocks.
  EOT
  type        = string
  default     = "m7g.2xlarge"
}

variable "demo_volume_gb" {
  description = "Root disk: container images, model weights (~6 GB) and the database."
  type        = number
  default     = 100
}

variable "demo_chat_model" {
  description = "The Private chat model Ollama pulls and serves on the demo."
  type        = string
  default     = "llama3.1:8b"
}

variable "demo_eip_allocation_id" {
  description = <<-EOT
    Optional: an Elastic IP you allocated yourself (eipalloc-...). Terraform then only attaches
    it and never releases it, so the demo keeps the same address (and sslip.io name, and OAuth
    redirect URLs) across `terraform destroy` and `apply`. Empty: Terraform allocates one, which
    a destroy releases.
  EOT
  type        = string
  default     = ""
}

variable "workbench_enabled" {
  description = "Create the on-demand workbench (8 GB) for Private-mode models and Kubernetes practice."
  type        = bool
  default     = false
}

variable "workbench_instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "domain" {
  description = "Leave empty until sotto.ai is bought; the demo then uses <ip>.sslip.io."
  type        = string
  default     = ""
}
