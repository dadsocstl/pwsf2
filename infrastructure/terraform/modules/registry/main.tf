# modules/registry/main.tf
# Provisions an ECR (Elastic Container Registry) repository for the
# CyberForge platform with image scanning and lifecycle policies.

variable "cluster_name" { type = string }
variable "region"       { type = string }
variable "tags"         { type = map(string); default = {} }

locals {
  repos = [
    "cyberforge/platform",
    "cyberforge/compliance-scanner",
    "cyberforge/sidecar-falco",
    "cyberforge/sidecar-vault-agent",
  ]
}

resource "aws_ecr_repository" "platform" {
  for_each             = toset(local.repos)
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = merge(var.tags, { Name = each.value })
}

resource "aws_ecr_lifecycle_policy" "platform" {
  for_each   = aws_ecr_repository.platform
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain last 30 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images older than 14 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "ENHANCED"
  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    repository_filter {
      filter      = "cyberforge/*"
      filter_type = "WILDCARD"
    }
  }
}

output "registry_url" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

data "aws_caller_identity" "current" {}