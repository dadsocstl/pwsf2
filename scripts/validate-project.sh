#!/usr/bin/env bash
# validate-project.sh
# Validates that required project files and directories are present and non-empty.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check_file() {
  local path="$REPO_ROOT/$1"
  local label="${2:-$1}"
  if [[ -f "$path" && -s "$path" ]]; then
    echo "  [PASS] $label"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label  (missing or empty: $path)"
    FAIL=$((FAIL + 1))
  fi
}

check_dir() {
  local path="$REPO_ROOT/$1"
  local label="${2:-$1}"
  if [[ -d "$path" ]]; then
    echo "  [PASS] $label"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label  (directory not found: $path)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== CyberForge Project Validation ==="
echo ""

echo "--- Top-level documentation ---"
check_file "README.md"
check_file "INSTRUCTIONS.md"
check_file "AGENTS.md"
check_file "SKILLS.md"
check_file "TODO.md"
check_file "TOOLS.md"
check_file "HEARTBEAT.md"

echo ""
echo "--- Core scripts ---"
check_file "bootstrap.sh"
check_file "scripts/generate-project-tree.sh"
check_file "scripts/generate-full-ssp.sh"
check_file "scripts/validate-project.sh"
check_file "scripts/baselines/sync-stig-baselines.sh"
check_file "scripts/overlays/generate-stig-overlay.py"
check_file "scripts/scap/parse-scap-cci.py"

echo ""
echo "--- Infrastructure ---"
check_file "infrastructure/terraform/main.tf"
check_file "infrastructure/terraform/variables.tf"
check_file "infrastructure/terraform/terraform.tfvars.example"
check_dir  "infrastructure/terraform/modules/kubernetes-cluster"
check_dir  "infrastructure/terraform/modules/networking"
check_dir  "infrastructure/terraform/modules/rbac"
check_dir  "infrastructure/terraform/modules/registry"
check_dir  "infrastructure/terraform/modules/monitoring"
check_dir  "infrastructure/terraform/modules/backup"

echo ""
echo "--- Platform services ---"
check_file "platform-services/argocd/argocd-values.yaml"
check_file "platform-services/vault/vault-values.yaml"
check_file "platform-services/minio/minio-values.yaml"
check_file "platform-services/elk-stack/helm/values.yaml"
check_file "platform-services/policy-engines/kyverno/require-signed-images.yaml"

echo ""
echo "--- Baselines ---"
check_file "baselines/container-stig/policies/security-context.yaml"
check_file "baselines/kubernetes-stig/policies/pod-security.yaml"
check_file "baselines/os-stig/ansible-playbooks/hardening.yml"
check_file "baselines/sidecar-stack/falco/falco-rules.yaml"
check_file "baselines/sidecar-stack/kyverno/policies/require-signed-images.yaml"
check_file "baselines/ironbank-mirror/mirror-config.yaml"

echo ""
echo "--- CI/CD Pipelines ---"
check_file ".gitlab-ci.yml"
check_file "pipelines/compliance/scap-scan.yml"
check_file "pipelines/software-requests/software-vetting.yml"
check_file "pipelines/supply-chain/cosign-sign.yml"

echo ""
echo "--- Supply chain ---"
check_file "supply-chain/attestation/cosign-policy.yaml"
check_file "supply-chain/sbom/syft-config.yaml"

echo ""
echo "--- Tenancy ---"
check_file "tenancy/rbac/kubernetes/rbac.yaml"

echo ""
echo "--- Software requests ---"
check_file "software-requests/templates/oss-request.md"
check_file "software-requests/workflows/software-vetting-pipeline.yml"

echo ""
echo "--- OSCAL compliance ---"
check_file "oscal-compliance/trestle-workspace/profiles/jsig-sap-overlay.yaml"
check_file "oscal-compliance/trestle-workspace/component-definitions/cyberforge-platform/cyberforge-platform.json"
check_file "oscal-compliance/trestle-workspace/ssps/my-system-ssp/control-implementations/implementation.json"

echo ""
echo "--- Overlays ---"
check_file "overlays/windows11/mll-overlay.yaml"

echo ""
echo "--- Docs ---"
check_file "docs/architecture.md"
check_file "docs/air-gapped-deployment.md"
check_file "docs/runbook-production.md"

echo ""
echo "--- References ---"
check_file "references/daapm/daapm-controls.csv"
check_file "references/compliance-as-code/content/products/rhel9/profiles/stig.profile"

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [[ $FAIL -gt 0 ]]; then
  echo "VALIDATION FAILED - $FAIL file(s)/directory(ies) need attention."
  exit 1
else
  echo "VALIDATION PASSED"
  exit 0
fi