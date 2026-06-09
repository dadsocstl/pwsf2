# modules/rbac/main.tf
# Creates Kubernetes RBAC roles and bindings for CyberForge platform teams.

variable "cluster_name" { type = string }

resource "kubernetes_cluster_role" "platform_admin" {
  metadata {
    name = "cyberforge-platform-admin"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role" "compliance_reader" {
  metadata {
    name = "cyberforge-compliance-reader"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "configmaps", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["policy"]
    resources  = ["podsecuritypolicies"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role" "developer" {
  metadata {
    name = "cyberforge-developer"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/exec", "services", "configmaps"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

# Namespace for platform operations
resource "kubernetes_namespace" "cyberforge" {
  metadata {
    name = "cyberforge"
    labels = {
      "app.kubernetes.io/managed-by"              = "terraform"
      "pod-security.kubernetes.io/enforce"        = "restricted"
      "pod-security.kubernetes.io/audit"          = "restricted"
      "pod-security.kubernetes.io/warn"           = "restricted"
    }
  }
}

output "platform_admin_role"   { value = kubernetes_cluster_role.platform_admin.metadata[0].name }
output "compliance_reader_role" { value = kubernetes_cluster_role.compliance_reader.metadata[0].name }
output "developer_role"        { value = kubernetes_cluster_role.developer.metadata[0].name }