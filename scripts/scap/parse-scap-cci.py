#!/usr/bin/env python3
"""
parse-scap-cci.py
Parses a SCAP ARF (Assessment Results Format) XML file and extracts
CCI (Control Correlation Identifier) findings into a structured JSON
or CSV report.

Requires Python 3.9+.

Usage:
    python3 parse-scap-cci.py --input results/arf-results.xml --output report.json
    python3 parse-scap-cci.py --input results/arf-results.xml --format csv --output report.csv
"""

import argparse
import csv
import json
import sys

if sys.version_info < (3, 9):
    sys.exit(f"ERROR: Python 3.9 or later is required. Running {sys.version}")

from pathlib import Path
import xml.etree.ElementTree as ET

# ---------------------------------------------------------------------------
# SCAP / ARF namespace map
# ---------------------------------------------------------------------------
NS = {
    "arf":  "http://scap.nist.gov/schema/asset-reporting-format/1.1",
    "ai":   "http://scap.nist.gov/schema/asset-identification/1.1",
    "xccdf": "http://checklists.nist.gov/xccdf/1.2",
    "cdf":  "http://checklists.nist.gov/xccdf/1.1",
    "dc":   "http://purl.org/dc/elements/1.1/",
    "cci":  "http://iase.disa.mil/cci",
}


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

def parse_arf(arf_path: Path) -> list[dict]:
    """Parse an ARF XML file and return a list of CCI finding dicts."""
    findings = []
    tree = ET.parse(str(arf_path))
    root = tree.getroot()

    # Support both XCCDF 1.1 and 1.2 namespaces
    xccdf_ns = None
    for prefix in ("xccdf", "cdf"):
        if root.find(f".//{{{NS[prefix]}}}TestResult") is not None:
            xccdf_ns = NS[prefix]
            break

    if xccdf_ns is None:
        # Try to detect namespace from root tag
        tag = root.tag
        if "{" in tag:
            xccdf_ns = tag[1:tag.index("}")]
        else:
            xccdf_ns = NS["xccdf"]

    for rule_result in root.iter(f"{{{xccdf_ns}}}rule-result"):
        rule_id = rule_result.get("idref", "unknown")
        result_elem = rule_result.find(f"{{{xccdf_ns}}}result")
        result_text = result_elem.text.strip() if result_elem is not None else "unknown"

        # Collect CCIs referenced in ident elements
        ccis = []
        for ident in rule_result.findall(f"{{{xccdf_ns}}}ident"):
            system = ident.get("system", "")
            if "cci" in system.lower() or "iase.disa.mil" in system.lower():
                ccis.append(ident.text.strip() if ident.text else "")

        # Message / fix text
        message_elem = rule_result.find(f"{{{xccdf_ns}}}message")
        message = message_elem.text.strip() if message_elem is not None and message_elem.text else ""

        findings.append({
            "rule_id": rule_id,
            "result": result_text,
            "ccis": ccis,
            "message": message,
        })

    return findings


def summarize(findings: list[dict]) -> dict:
    """Return a summary dict with pass/fail/notchecked counts."""
    summary: dict = {"total": len(findings), "pass": 0, "fail": 0, "notchecked": 0, "other": 0}
    for f in findings:
        r = f["result"].lower()
        if r == "pass":
            summary["pass"] += 1
        elif r in ("fail", "error"):
            summary["fail"] += 1
        elif r in ("notchecked", "notapplicable", "informational"):
            summary["notchecked"] += 1
        else:
            summary["other"] += 1
    return summary


# ---------------------------------------------------------------------------
# Output writers
# ---------------------------------------------------------------------------

def write_json(findings: list[dict], output_path: Path):
    summary = summarize(findings)
    report = {"summary": summary, "findings": findings}
    with output_path.open("w") as f:
        json.dump(report, f, indent=2)
    print(f"JSON report written: {output_path}")


def write_csv(findings: list[dict], output_path: Path):
    fieldnames = ["rule_id", "result", "ccis", "message"]
    with output_path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in findings:
            writer.writerow({
                "rule_id": row["rule_id"],
                "result": row["result"],
                "ccis": "; ".join(row["ccis"]),
                "message": row["message"],
            })
    print(f"CSV report written: {output_path}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, help="Path to ARF XML results file")
    p.add_argument("--output", required=True, help="Output report file path")
    p.add_argument("--format", choices=["json", "csv"], default="json", help="Output format (default: json)")
    return p.parse_args()


def main():
    args = parse_args()
    arf_path = Path(args.input)
    output_path = Path(args.output)

    if not arf_path.is_file():
        print(f"ERROR: Input file not found: {arf_path}", file=sys.stderr)
        sys.exit(1)

    print(f"Parsing ARF: {arf_path}")
    findings = parse_arf(arf_path)
    print(f"  Found {len(findings)} rule results")

    summary = summarize(findings)
    print(f"  Pass: {summary['pass']}  Fail: {summary['fail']}  "
          f"NotChecked: {summary['notchecked']}  Other: {summary['other']}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    if args.format == "csv":
        write_csv(findings, output_path)
    else:
        write_json(findings, output_path)


if __name__ == "__main__":
    main()