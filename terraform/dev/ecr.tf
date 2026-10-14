# The image repositories moved to the "keep" stack (terraform/keep/ecr.tf): they lived here, so
# every `terraform destroy` deleted them, and the next Jenkins build on main had nowhere to push
# ("repository sotto/api does not exist"). These blocks make this stack forget them without
# deleting anything, if its state still lists them.
removed {
  from = aws_ecr_lifecycle_policy.service
  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_ecr_repository.service
  lifecycle {
    destroy = false
  }
}
