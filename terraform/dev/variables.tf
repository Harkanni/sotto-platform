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
    runs the app, the embedding model and faster-whisper; the chat model has its own GPU
    server (model.tf, ADR 0032). t4g.medium (4 GB) only fits the labelled mocks.
  EOT
  type        = string
  default     = "m7g.2xlarge"
}

variable "demo_volume_gb" {
  description = "Root disk: container images, model weights (~6 GB) and the database."
  type        = number
  default     = 100
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

# ── The private chat model on its own GPU server (model.tf, ADR 0032) ──────────────────────

variable "model_server_enabled" {
  description = <<-EOT
    Run the GPU model server. Off by default: it needs the GPU quota and a zone that offers
    model_instance_type. Turn it on with -var model_server_enabled=true (or terraform.tfvars).
    Off: the demo answers with passages only (no chat model).
  EOT
  type        = bool
  default     = false
}

variable "model_instance_type" {
  description = <<-EOT
    One NVIDIA L40S (48 GB) on g6e.xlarge: room for the model in FP8 plus a long context.
    Needs the "Running On-Demand G and VT instances" quota (4 vCPUs) in this region.
  EOT
  type        = string
  default     = "g6e.xlarge"
}

variable "model_hf_id" {
  description = "The Hugging Face model vLLM serves (FP8 weights fit the L40S)."
  type        = string
  default     = "Qwen/Qwen3.6-35B-A3B-FP8"
}

variable "model_max_len" {
  description = "Longest prompt + answer in tokens. Ask sends ~8 passages; 32K is plenty and fast."
  type        = number
  default     = 32768
}

variable "vllm_image" {
  description = "vLLM's OpenAI-compatible server image. Qwen3.6 needs vLLM 0.19 or later."
  type        = string
  default     = "vllm/vllm-openai:latest"
}
