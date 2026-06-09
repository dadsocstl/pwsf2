# modules/kubernetes-cluster/cilium.tf
# Deploys Cilium CNI in strict network-policy enforcement mode.

resource "helm_release" "cilium" {
  name             = "cilium"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  version          = "1.15.3"
  namespace        = "kube-system"

  set {
    name  = "eni.enabled"
    value = "true"
  }

  set {
    name  = "ipam.mode"
    value = "eni"
  }

  set {
    name  = "egressMasqueradeInterfaces"
    value = "eth0"
  }

  set {
    name  = "tunnel"
    value = "disabled"
  }

  # Enforce network policies
  set {
    name  = "policyEnforcementMode"
    value = "always"
  }

  # Hubble observability
  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }

  depends_on = [aws_eks_cluster.this]
}