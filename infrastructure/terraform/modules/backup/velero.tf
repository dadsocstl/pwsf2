# modules/backup/velero.tf
# Deploys Velero for cluster backup and disaster recovery.

variable "cluster_name"  { type = string }
variable "backup_bucket" { type = string }
variable "region"        { type = string; default = "us-gov-west-1" }

resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "aws_s3_bucket" "velero" {
  bucket        = var.backup_bucket
  force_destroy = false

  tags = {
    Name    = var.backup_bucket
    purpose = "velero-backups"
    cluster = var.cluster_name
  }
}

resource "aws_s3_bucket_versioning" "velero" {
  bucket = aws_s3_bucket.velero.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero" {
  bucket = aws_s3_bucket.velero.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "velero" {
  bucket                  = aws_s3_bucket.velero.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "6.1.0"
  namespace  = kubernetes_namespace.velero.metadata[0].name

  set {
    name  = "configuration.provider"
    value = "aws"
  }

  set {
    name  = "configuration.backupStorageLocation[0].name"
    value = "default"
  }

  set {
    name  = "configuration.backupStorageLocation[0].provider"
    value = "aws"
  }

  set {
    name  = "configuration.backupStorageLocation[0].bucket"
    value = var.backup_bucket
  }

  set {
    name  = "configuration.backupStorageLocation[0].config.region"
    value = var.region
  }

  set {
    name  = "configuration.volumeSnapshotLocation[0].name"
    value = "default"
  }

  set {
    name  = "configuration.volumeSnapshotLocation[0].provider"
    value = "aws"
  }

  set {
    name  = "configuration.volumeSnapshotLocation[0].config.region"
    value = var.region
  }

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-aws"
  }

  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-aws:v1.9.0"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].mountPath"
    value = "/target"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].name"
    value = "plugins"
  }
}

output "backup_bucket" { value = aws_s3_bucket.velero.bucket }