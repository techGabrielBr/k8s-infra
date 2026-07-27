locals {
  ecr_repositories = ["users-api", "catalog-api", "payments-api"]
}

resource "aws_ecr_repository" "apis" {
  for_each = toset(local.ecr_repositories)

  name         = each.value
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
