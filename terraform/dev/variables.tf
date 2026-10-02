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
  type    = number
  default = 40
}

variable "demo_instance_type" {
  description = "ARM (Graviton) is cheaper per GB of RAM. 4 GB fits the demo stack with limits."
  type        = string
  default     = "t4g.medium"
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
