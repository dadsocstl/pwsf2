# infrastructure/terraform/main.tf
# CyberForge Platform — top-level Terraform entry point.
# Composes the networking, kubernetes-cluster, registry, rbac,
# monitoring, and backup modules into a single deployable stack.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
  backend "s3" {
    bucket         = "cyberforge-tfstate"
    key            = "cyberforge/terraform.tfstate"
    region         = "us-gov-west-1"
    encrypt        = true
    dynamodb_table = "cyberforge-tflock"
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------

module "networking" {
  source       = "./modules/networking"
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
  region       = var.region
  tags         = var.common_tags
}

module "kubernetes_cluster" {
  source         = "./modules/kubernetes-cluster"
  cluster_name   = var.cluster_name
  node_count     = var.node_count
  instance_type  = var.instance_type
  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.private_subnet_ids
  region         = var.region
  tags           = var.common_tags
}

module "registry" {
  source       = "./modules/registry"
  cluster_name = var.cluster_name
  region       = var.region
  tags         = var.common_tags
}

module "rbac" {
  source       = "./modules/rbac"
  cluster_name = var.cluster_name
  depends_on   = [module.kubernetes_cluster]
}

module "monitoring" {
  source       = "./modules/monitoring"
  cluster_name = var.cluster_name
  depends_on   = [module.kubernetes_cluster]
}

module "backup" {
  source           = "./modules/backup"
  cluster_name     = var.cluster_name
  backup_bucket    = var.backup_bucket
  region           = var.region
  depends_on       = [module.kubernetes_cluster]
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = module.kubernetes_cluster.cluster_name
}

output "registry_url" {
  description = "Container registry URL"
  value       = module.registry.registry_url
}

output "vpc_id" {
  description = "VPC identifier"
  value       = module.networking.vpc_id
}