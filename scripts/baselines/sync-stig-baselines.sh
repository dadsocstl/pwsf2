#!/usr/bin/env bash
# sync-stig-baselines.sh
# Downloads and syncs STIG baselines from ComplianceAsCode and NIST OSCAL sources.
# In air-gapped environments, set MIRROR_BASE to an internal URL.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASELINES_DIR="$REPO_ROOT/baselines"
MIRROR_BASE="${MIRROR_BASE:-https://github.com/ComplianceAsCode/content/releases/latest/download}"
NIST_OSCAL_BASE="${NIST_OSCAL_BASE:-https://raw.githubusercontent.com/usnistgov/OSCAL/main/content/nist.gov/SP800-53/rev5}"

echo "=== Syncing STIG Baselines ==="
echo "Baselines dir : $BASELINES_DIR"
echo "Mirror base   : $MIRROR_BASE"
echo ""

# ---- Helper ----
download_if_missing() {
  local dest="$1"
  local url="$2"
  if [[ -f "$dest" && -s "$dest" ]]; then
    echo "  [SKIP] Already present: $(basename "$dest")"
  else
    echo "  [GET]  $url"
    mkdir -p "$(dirname "$dest")"
    curl -fsSL "$url" -o "$dest" || {
      echo "  [WARN] Download failed for $url — skipping."
    }
  fi
}

# ---- OS STIG (RHEL 9) ----
echo "--- OS STIG ---"
RHEL9_PROFILE="$REPO_ROOT/references/compliance-as-code/content/products/rhel9/profiles/stig.profile"
download_if_missing \
  "$BASELINES_DIR/os-stig/stig-rhel9-ds.xml" \
  "$MIRROR_BASE/scap-security-guide-rhel9-ds.xml" || true

# Sync the profile stub if the full download isn't available
if [[ ! -s "$RHEL9_PROFILE" ]]; then
  mkdir -p "$(dirname "$RHEL9_PROFILE")"
  echo "# RHEL9 STIG profile stub - replace with content from ComplianceAsCode" > "$RHEL9_PROFILE"
fi

# ---- Kubernetes STIG ----
echo "--- Kubernetes STIG ---"
download_if_missing \
  "$BASELINES_DIR/kubernetes-stig/stig-kubernetes-ds.xml" \
  "$MIRROR_BASE/scap-security-guide-kubernetes-ds.xml" || true

# ---- Container STIG ----
echo "--- Container STIG ---"
download_if_missing \
  "$BASELINES_DIR/container-stig/stig-container-ds.xml" \
  "$MIRROR_BASE/scap-security-guide-container-ds.xml" || true

# ---- NIST OSCAL 800-53 Rev5 catalog ----
echo "--- NIST OSCAL 800-53 Rev5 ---"
OSCAL_DIR="$REPO_ROOT/references/nist-oscal-content"
mkdir -p "$OSCAL_DIR"
download_if_missing \
  "$OSCAL_DIR/NIST_SP-800-53_rev5_catalog.json" \
  "$NIST_OSCAL_BASE/json/NIST_SP-800-53_rev5_catalog.json" || true
download_if_missing \
  "$OSCAL_DIR/NIST_SP-800-53_rev5_catalog.xml" \
  "$NIST_OSCAL_BASE/xml/NIST_SP-800-53_rev5_catalog.xml" || true

echo ""
echo "=== Baseline sync complete ==="