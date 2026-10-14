# One image repository per service, kept between sessions: Jenkins pushes to them on every
# merge to main, whether or not the demo is up, and a new demo pulls `main` from them on boot.
# Storage is $0.10 per GB-month; keeping the last 10 images per service stays around $1–2.
locals {
  services = ["web", "api", "worker", "transcriber"]
}

resource "aws_ecr_repository" "service" {
  for_each             = toset(local.services)
  name                 = "sotto/${each.key}"
  image_tag_mutability = "MUTABLE" # `main` moves; sha tags never change in practice
  force_delete         = true      # destroying this stack on purpose removes them, images and all

  image_scanning_configuration {
    scan_on_push = true # free basic scan for known CVEs
  }
}

resource "aws_ecr_lifecycle_policy" "service" {
  for_each   = aws_ecr_repository.service
  repository = each.value.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the 10 most recent images; storage costs money."
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }
      action       = { type = "expire" }
    }]
  })
}

output "ecr_repositories" {
  value = [for r in aws_ecr_repository.service : r.repository_url]
}
