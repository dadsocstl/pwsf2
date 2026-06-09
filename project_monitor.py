#!/usr/bin/env python3
"""
project_monitor.py
Continuous monitoring script for the CyberForge project.
Checks file presence, sizes, and script executability, then prints a
health summary.  Exit code 0 = healthy, 1 = issues found.

Usage:
    python3 project_monitor.py [--once] [--interval SECONDS] [--json]
"""

import argparse
import json
import os
import stat
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration: items to monitor
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parent

# Each entry: (relative_path, min_bytes, must_be_executable)
MONITORED_FILES: list[tuple[str, int, bool]] = [
    ("README.md",                                                        100,  False),
    ("INSTRUCTIONS.md",                                                   50,  False),
    ("HEARTBEAT.md",                                                      50,  False),
    ("TODO.md",                                                           50,  False),
    ("bootstrap.sh",                                                     200,  True),
    ("scripts/validate-project.sh",                                      200,  True),
    ("scripts/generate-project-tree.sh",                                 100,  True),
    ("scripts/generate-full-ssp.sh",                                     200,  True),
    ("scripts/baselines/sync-stig-baselines.sh",                         200,  True),
    ("scripts/overlays/generate-stig-overlay.py",                        200,  False),
    ("scripts/scap/parse-scap-cci.py",                                   200,  False),
    ("infrastructure/terraform/main.tf",                                 100,  False),
    ("infrastructure/terraform/variables.tf",                            100,  False),
    ("platform-services/argocd/argocd-values.yaml",                     100,  False),
    ("platform-services/vault/vault-values.yaml",                        100,  False),
    ("platform-services/minio/minio-values.yaml",                        100,  False),
    (".gitlab-ci.yml",                                                   100,  False),
    ("supply-chain/attestation/cosign-policy.yaml",                      50,  False),
    ("supply-chain/sbom/syft-config.yaml",                               50,  False),
    ("tenancy/rbac/kubernetes/rbac.yaml",                                100,  False),
    ("oscal-compliance/trestle-workspace/profiles/jsig-sap-overlay.yaml", 50, False),
]

MONITORED_DIRS: list[str] = [
    "baselines",
    "docs",
    "infrastructure/terraform/modules",
    "pipelines",
    "platform-services",
    "references",
    "supply-chain",
    "tenancy",
]


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

def check_files(root: Path) -> list[dict]:
    results = []
    for rel, min_bytes, must_exec in MONITORED_FILES:
        path = root / rel
        entry: dict = {"path": rel, "status": "ok", "details": ""}
        if not path.is_file():
            entry["status"] = "missing"
            entry["details"] = "file not found"
        elif path.stat().st_size < min_bytes:
            entry["status"] = "too-small"
            entry["details"] = f"size {path.stat().st_size} < {min_bytes} bytes"
        elif must_exec and not os.access(str(path), os.X_OK):
            entry["status"] = "not-executable"
            entry["details"] = "missing execute permission"
        results.append(entry)
    return results


def check_dirs(root: Path) -> list[dict]:
    results = []
    for rel in MONITORED_DIRS:
        path = root / rel
        entry: dict = {"path": rel, "status": "ok", "details": ""}
        if not path.is_dir():
            entry["status"] = "missing"
            entry["details"] = "directory not found"
        else:
            # Count non-hidden files recursively
            file_count = sum(1 for _ in path.rglob("*") if _.is_file())
            entry["details"] = f"{file_count} file(s)"
        results.append(entry)
    return results


def run_checks(root: Path) -> dict:
    file_results = check_files(root)
    dir_results = check_dirs(root)

    issues = [r for r in file_results + dir_results if r["status"] != "ok"]
    healthy = len(issues) == 0

    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "healthy": healthy,
        "files_checked": len(file_results),
        "dirs_checked": len(dir_results),
        "issues": issues,
        "file_results": file_results,
        "dir_results": dir_results,
    }


def print_report(report: dict, as_json: bool = False):
    if as_json:
        print(json.dumps(report, indent=2))
        return

    ts = report["timestamp"]
    status = "HEALTHY" if report["healthy"] else "DEGRADED"
    print(f"[{ts}] Project Monitor — {status}")
    print(f"  Files checked : {report['files_checked']}")
    print(f"  Dirs checked  : {report['dirs_checked']}")

    issues = report["issues"]
    if issues:
        print(f"  Issues ({len(issues)}):")
        for iss in issues:
            print(f"    [{iss['status'].upper()}] {iss['path']} — {iss['details']}")
    else:
        print("  No issues found.")
    print()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--once", action="store_true", help="Run once and exit")
    p.add_argument("--interval", type=int, default=60, help="Poll interval in seconds (default: 60)")
    p.add_argument("--json", action="store_true", help="Output report as JSON")
    return p.parse_args()


def main():
    args = parse_args()

    if args.once:
        report = run_checks(REPO_ROOT)
        print_report(report, as_json=args.json)
        sys.exit(0 if report["healthy"] else 1)

    print(f"Starting project monitor (interval={args.interval}s). Press Ctrl+C to stop.")
    while True:
        report = run_checks(REPO_ROOT)
        print_report(report, as_json=args.json)
        time.sleep(args.interval)


if __name__ == "__main__":
    main()