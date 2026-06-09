#!/usr/bin/env bash
# bootstrap.sh
# Bootstraps the CyberForge development and CI environment.
# Installs required CLI tools and validates the project structure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/cyberforge-bootstrap.log"
PYTHON_MIN="3.9"

echo "=== CyberForge Bootstrap ===" | tee "$LOG_FILE"
echo "Repo root : $REPO_ROOT"       | tee -a "$LOG_FILE"
echo "Date      : $(date -u)"        | tee -a "$LOG_FILE"
echo ""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
check_tool() {
  local tool="$1"
  if command -v "$tool" &>/dev/null; then
    echo "  [OK]      $tool  ($(command -v "$tool"))"
  else
    echo "  [MISSING] $tool"
    return 1
  fi
}

require_tool() {
  local tool="$1"
  local install_hint="${2:-}"
  if ! command -v "$tool" &>/dev/null; then
    echo ""
    echo "ERROR: Required tool '$tool' not found."
    [[ -n "$install_hint" ]] && echo "  Install hint: $install_hint"
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Check required tools
# ---------------------------------------------------------------------------
echo "--- Checking required tools ---"
MISSING=0
for tool in bash python3 curl git; do
  check_tool "$tool" || ((MISSING++)) || true
done

# Optional but strongly recommended
echo ""
echo "--- Checking optional/recommended tools ---"
for tool in terraform kubectl helm cosign syft trestle; do
  check_tool "$tool" || true
done

if [[ $MISSING -gt 0 ]]; then
  echo ""
  echo "ERROR: $MISSING required tool(s) are missing. Please install them and re-run."
  exit 1
fi

# ---------------------------------------------------------------------------
# Python version check
# ---------------------------------------------------------------------------
echo ""
echo "--- Python version check ---"
PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "  Python version : $PY_VER (minimum $PYTHON_MIN required)"
python3 -c "
import sys
required = tuple(int(x) for x in '${PYTHON_MIN}'.split('.'))
if sys.version_info[:2] < required:
    print(f'  ERROR: Python {sys.version_info.major}.{sys.version_info.minor} < {required[0]}.{required[1]}')
    sys.exit(1)
else:
    print('  [OK] Python version is sufficient')
"

# ---------------------------------------------------------------------------
# Install Python dependencies (if requirements.txt exists)
# ---------------------------------------------------------------------------
if [[ -f "$REPO_ROOT/requirements.txt" ]]; then
  echo ""
  echo "--- Installing Python dependencies ---"
  python3 -m pip install --quiet -r "$REPO_ROOT/requirements.txt"
  echo "  [OK] pip install complete"
fi

# ---------------------------------------------------------------------------
# Ensure scripts are executable
# ---------------------------------------------------------------------------
echo ""
echo "--- Making scripts executable ---"
find "$REPO_ROOT/scripts" -name "*.sh" -exec chmod +x {} \;
find "$REPO_ROOT/scripts" -name "*.py" -exec chmod +x {} \;
chmod +x "$REPO_ROOT/bootstrap.sh" 2>/dev/null || true
echo "  [OK] Script permissions set"

# ---------------------------------------------------------------------------
# Validate project structure
# ---------------------------------------------------------------------------
echo ""
echo "--- Running project validation ---"
if [[ -x "$REPO_ROOT/scripts/validate-project.sh" ]]; then
  bash "$REPO_ROOT/scripts/validate-project.sh" | tee -a "$LOG_FILE"
else
  echo "  [WARN] validate-project.sh not found or not executable — skipping"
fi

# ---------------------------------------------------------------------------
# .env setup
# ---------------------------------------------------------------------------
echo ""
echo "--- Environment setup ---"
if [[ ! -f "$REPO_ROOT/.env" ]]; then
  if [[ -f "$REPO_ROOT/.env.example" ]]; then
    cp "$REPO_ROOT/.env.example" "$REPO_ROOT/.env"
    echo "  [OK] Copied .env.example -> .env  (review and update before use)"
  else
    echo "  [WARN] No .env.example found"
  fi
else
  echo "  [SKIP] .env already exists"
fi

echo ""
echo "=== Bootstrap complete ==="
echo "  Log: $LOG_FILE"