# One image repository per service. CI pushes `sha-<commit>` tags plus a moving `main` tag.
resource "aws_ecr_repository" "service" {
  for_each             = toset(local.services)
  name                 = "sotto/${each.key}"
  image_tag_mutability = "MUTABLE" # `main` moves; sha tags never change in practice
  force_delete         = true      # dev only: lets `terraform destroy` remove repos with images

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
      description  = "Keep the 15 most recent images; storage costs money."
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 15 }
      action       = { type = "expire" }
    }]
  })
}
