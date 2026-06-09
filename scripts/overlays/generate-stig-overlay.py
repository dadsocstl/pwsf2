#!/usr/bin/env python3
"""
CyberForge Dynamic STIG Overlay Generator
Version 1: Windows 11 M-L-L Baseline

- Reads official NIST OSCAL catalog
- References ComplianceAsCode STIG content (after sync)
- Applies overlay definition (YAML)
- Generates both YAML and JSON artifacts
- Works fully offline after initial sync

Usage:
    python3 generate-stig-overlay.py --overlay overlays/windows11/mll-overlay.yaml
"""

import argparse
import json
import yaml
import os
import sys
from datetime import datetime
from pathlib import Path

def load_yaml(path):
    with open(path, 'r') as f:
        return yaml.safe_load(f)

def load_json(path):
    with open(path, 'r') as f:
        return json.load(f)

def generate_overlay(overlay_path: str, output_dir: str):
    print(f"[*] Loading overlay definition: {overlay_path}")
    overlay = load_yaml(overlay_path)

    overlay_name = overlay['overlay']['name']
    print(f"[*] Generating overlay: {overlay_name}")

    # Paths
    project_root = Path(__file__).parent.parent.parent
    nist_catalog_path = project_root / "references/nist-oscal-content/NIST_SP-800-53_rev5_catalog.json"
    baseline_mapping_path = project_root / "baselines/baseline-mapping.json"

    # Load base catalog (we use our local reference)
    if nist_catalog_path.exists():
        catalog = load_json(nist_catalog_path)
        print(f"[+] Loaded NIST OSCAL catalog from {nist_catalog_path}")
    else:
        print(f"[!] NIST catalog not found at {nist_catalog_path}. Using minimal structure.")
        catalog = {"catalog": {"groups": []}}

    # Create output directory
    out_dir = Path(output_dir) / overlay_name
    out_dir.mkdir(parents=True, exist_ok=True)

    # === Generate OSCAL Profile (YAML + JSON) ===
    profile = {
        "profile": {
            "uuid": f"win11-mll-{datetime.now().strftime('%Y%m%d')}",
            "metadata": {
                "title": f"Windows 11 STIG - {overlay['overlay']['description']}",
                "last-modified": datetime.now().isoformat(),
                "version": "1.0",
                "oscal-version": "1.1.2"
            },
            "imports": [
                {
                    "href": str(nist_catalog_path),
                    "include": {
                        "with-ids": overlay['overlay']['tailoring']['select']
                    }
                }
            ],
            "modify": {
                "set-parameters": overlay['overlay']['tailoring'].get('set_values', [])
            }
        }
    }

    # Write YAML
    with open(out_dir / f"{overlay_name}-profile.yaml", "w") as f:
        yaml.dump(profile, f, sort_keys=False)
    print(f"[+] Generated {overlay_name}-profile.yaml")

    # Write JSON
    with open(out_dir / f"{overlay_name}-profile.json", "w") as f:
        json.dump(profile, f, indent=2)
    print(f"[+] Generated {overlay_name}-profile.json")

    # === Generate STIG Baseline Reference ===
    stig_baseline = {
        "baseline": {
            "name": overlay_name,
            "os": "Windows 11",
            "impact": "M-L-L",
            "source": "DISA STIG via ComplianceAsCode",
            "generated": datetime.now().isoformat(),
            "selected_controls": overlay['overlay']['tailoring']['select'],
            "notes": overlay['overlay']['tailoring'].get('modifications', [])
        }
    }

    with open(out_dir / f"{overlay_name}-stig-baseline.yaml", "w") as f:
        yaml.dump(stig_baseline, f, sort_keys=False)
    with open(out_dir / f"{overlay_name}-stig-baseline.json", "w") as f:
        json.dump(stig_baseline, f, indent=2)

    print(f"[+] Generated STIG baseline artifacts (YAML + JSON)")

    # === Generate Mapping File ===
    mapping = {
        "mapping": {
            "overlay": overlay_name,
            "nist_catalog": str(nist_catalog_path),
            "compliance_as_code": str(project_root / "references/compliance-as-code"),
            "generated": datetime.now().isoformat(),
            "controls_mapped": len(overlay['overlay']['tailoring']['select'])
        }
    }

    with open(out_dir / f"{overlay_name}-mapping.json", "w") as f:
        json.dump(mapping, f, indent=2)
    with open(out_dir / f"{overlay_name}-mapping.yaml", "w") as f:
        yaml.dump(mapping, f, sort_keys=False)

    print(f"[+] Generated mapping artifacts")
    print(f"\n✅ Overlay generation complete. Output: {out_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate Dynamic STIG Overlay")
    parser.add_argument("--overlay", required=True, help="Path to overlay YAML definition")
    parser.add_argument("--output", default="artifacts/overlays", help="Output directory")
    args = parser.parse_args()

    generate_overlay(args.overlay, args.output)
