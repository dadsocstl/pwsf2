#!/usr/bin/env python3
"""
generate-stig-overlay.py
Generates a STIG overlay YAML file from a DAAPM controls CSV and a base
STIG profile.  The overlay marks controls as applicable, inherited, or
not-applicable based on mapping data.

Usage:
    python3 generate-stig-overlay.py \
        --daapm references/daapm/daapm-controls.csv \
        --profile overlays/windows11/mll-overlay.yaml \
        --output overlays/windows11/generated-overlay.yaml

    Or run without arguments to use defaults relative to the repo root.
"""

import argparse
import csv
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml

# ---------------------------------------------------------------------------
# Defaults (relative to repo root, discovered from script location)
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent

DEFAULT_DAAPM = REPO_ROOT / "references" / "daapm" / "daapm-controls.csv"
DEFAULT_BASE_OVERLAY = REPO_ROOT / "overlays" / "windows11" / "mll-overlay.yaml"
DEFAULT_OUTPUT = REPO_ROOT / "overlays" / "windows11" / "generated-overlay.yaml"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def load_daapm_controls(csv_path: Path) -> dict:
    """Return a dict of {control_id: row} from the DAAPM CSV."""
    controls = {}
    try:
        with csv_path.open(newline="") as f:
            reader = csv.DictReader(f)
            for row in reader:
                cid = row.get("control_id", row.get("Control ID", "")).strip()
                if cid:
                    controls[cid] = row
    except FileNotFoundError:
        print(f"[WARN] DAAPM CSV not found at {csv_path}; overlay will be empty.")
    return controls


def load_base_overlay(yaml_path: Path) -> dict:
    """Load an existing overlay YAML; return empty structure if missing."""
    if yaml_path.is_file():
        with yaml_path.open() as f:
            data = yaml.safe_load(f) or {}
        return data
    return {}


def build_overlay(controls: dict, base: dict, profile_name: str) -> dict:
    """Construct an overlay dict from DAAPM controls."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    overlay: dict = {
        "profile": profile_name,
        "generated": now,
        "controls": [],
    }

    # Carry forward any base controls
    existing_ids = {c.get("id") for c in base.get("controls", [])}

    for cid, row in sorted(controls.items()):
        if cid in existing_ids:
            continue  # already in base overlay
        status = row.get("status", row.get("Status", "applicable")).strip().lower()
        entry = {
            "id": cid,
            "status": status,
            "description": row.get("description", row.get("Description", f"DAAPM control {cid}")),
        }
        origin = row.get("origin", row.get("Origin", "")).strip()
        if origin:
            entry["origin"] = origin
        overlay["controls"].append(entry)

    # Merge in base controls
    overlay["controls"].extend(base.get("controls", []))

    return overlay


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--daapm", default=str(DEFAULT_DAAPM), help="Path to DAAPM controls CSV")
    p.add_argument("--profile", default=str(DEFAULT_BASE_OVERLAY), help="Path to base overlay YAML")
    p.add_argument("--output", default=str(DEFAULT_OUTPUT), help="Output overlay YAML path")
    p.add_argument("--profile-name", default="windows11-mll", help="Profile name to embed in overlay")
    return p.parse_args()


def main():
    args = parse_args()

    print("=== STIG Overlay Generator ===")
    print(f"  DAAPM CSV    : {args.daapm}")
    print(f"  Base overlay : {args.profile}")
    print(f"  Output       : {args.output}")
    print()

    daapm_path = Path(args.daapm)
    profile_path = Path(args.profile)
    output_path = Path(args.output)

    controls = load_daapm_controls(daapm_path)
    base = load_base_overlay(profile_path)
    overlay = build_overlay(controls, base, args.profile_name)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w") as f:
        yaml.dump(overlay, f, default_flow_style=False, sort_keys=False)

    print(f"Overlay written: {output_path}")
    print(f"  Controls included: {len(overlay['controls'])}")
    print("=== Done ===")


if __name__ == "__main__":
    main()