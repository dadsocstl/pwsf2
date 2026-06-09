#!/usr/bin/env bash
# generate-full-ssp.sh
# Assembles a full System Security Plan (SSP) from OSCAL component definitions
# and control implementation records in the trestle workspace.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRESTLE_WS="$REPO_ROOT/oscal-compliance/trestle-workspace"
OUTPUT_DIR="$REPO_ROOT/oscal-compliance/output"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUTPUT_FILE="$OUTPUT_DIR/full-ssp-${TIMESTAMP}.json"

mkdir -p "$OUTPUT_DIR"

echo "=== CyberForge SSP Generator ==="
echo "Trestle workspace : $TRESTLE_WS"
echo "Output            : $OUTPUT_FILE"
echo ""

# Check for required source files
COMPONENT_DEF="$TRESTLE_WS/component-definitions/cyberforge-platform/cyberforge-platform.json"
IMPL="$TRESTLE_WS/ssps/my-system-ssp/control-implementations/implementation.json"
PROFILE="$TRESTLE_WS/profiles/jsig-sap-overlay.yaml"

for f in "$COMPONENT_DEF" "$IMPL" "$PROFILE"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: Required source file not found: $f"
    exit 1
  fi
done

# If compliance-trestle is available, use it; otherwise emit a JSON bundle.
if command -v trestle &>/dev/null; then
  echo "Using compliance-trestle CLI..."
  trestle author ssp-generate \
    --profile jsig-sap-overlay \
    --output "full-ssp-${TIMESTAMP}" \
    --workspace "$TRESTLE_WS"
  echo "SSP generated via trestle."
else
  echo "compliance-trestle not found; assembling JSON bundle from source files..."
  python3 - <<'PYEOF'
import json, yaml, sys, os

repo_root = os.environ.get("REPO_ROOT", ".")
trestle_ws = os.path.join(repo_root, "oscal-compliance", "trestle-workspace")
output_file = os.environ.get("OUTPUT_FILE", "/tmp/full-ssp.json")

def load_json(path):
    with open(path) as f:
        return json.load(f)

def load_yaml(path):
    with open(path) as f:
        return yaml.safe_load(f)

component_def = load_json(os.path.join(trestle_ws, "component-definitions/cyberforge-platform/cyberforge-platform.json"))
impl = load_json(os.path.join(trestle_ws, "ssps/my-system-ssp/control-implementations/implementation.json"))
profile = load_yaml(os.path.join(trestle_ws, "profiles/jsig-sap-overlay.yaml"))

ssp_bundle = {
    "system-security-plan": {
        "uuid": impl.get("uuid", "00000000-0000-0000-0000-000000000000"),
        "metadata": {
            "title": "CyberForge Platform SSP",
            "version": "1.0",
            "oscal-version": "1.0.4",
            "last-modified": os.popen("date -u +%Y-%m-%dT%H:%M:%SZ").read().strip()
        },
        "import-profile": {"href": profile.get("profile", {}).get("href", "")},
        "system-characteristics": component_def.get("component-definition", {}).get("metadata", {}),
        "control-implementation": impl.get("control-implementation", {})
    }
}

with open(output_file, "w") as f:
    json.dump(ssp_bundle, f, indent=2)

print(f"SSP bundle written to {output_file}")
PYEOF
fi

echo ""
echo "=== SSP generation complete ===" 