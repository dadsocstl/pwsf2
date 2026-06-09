# infrastructure/terraform/variables.tf
# Input variable declarations for the CyberForge Terraform stack.

variable "region" {
  description = "AWS region for deployment."
  type        = string
  default     = "us-gov-west-1"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster."
  type        = string
  default     = "cyberforge"
}

variable "vpc_cidr" {
  description = "CIDR block for the platform VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_count" {
  description = "Number of worker nodes."
  type        = number
  default     = 3
}

variable "instance_type" {
  description = "EC2 instance type for worker nodes."
  type        = string
  default     = "m5.2xlarge"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig file used by the Kubernetes and Helm providers."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use."
  type        = string
  default     = "cyberforge-prod"
}

variable "backup_bucket" {
  description = "S3 bucket name for Velero backups."
  type        = string
  default     = "cyberforge-backups"
}

variable "common_tags" {
  description = "Common resource tags applied to all created resources."
  type        = map(string)
  default = {
    project     = "cyberforge"
    environment = "production"
    managed_by  = "terraform"
    compliance  = "nist-800-53"
  }
}