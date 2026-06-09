#!/usr/bin/env python3
"""
Basic CCI Parser from SCAP ARF Results
Extracts rule results and CCI references from OpenSCAP ARF XML
and merges them into OSCAL mapping / component definition.

Usage:
    python3 parse-scap-cci.py \
        --arf artifacts/scap/scap-results.xml \
        --mapping artifacts/overlays/windows11-mll/windows11-mll-mapping.json \
        --output artifacts/oscal/cci-mapping.json
"""

import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from datetime import datetime

def parse_arf(arf_path: str):
    """Parse SCAP ARF and extract rule results + CCI references."""
    tree = ET.parse(arf_path)
    root = tree.getroot()

    ns = {
        'arf': 'http://scap.nist.gov/schema/asset-reporting-format/1.1',
        'xccdf': 'http://checklists.nist.gov/xccdf/1.2',
        'cci': 'http://iase.disa.mil/cci'
    }

    results = []

    for rule_result in root.findall('.//xccdf:rule-result', ns):
        rule_id = rule_result.get('idref', '')
        result = rule_result.find('xccdf:result', ns)
        result_text = result.text if result is not None else 'unknown'

        cci_refs = []
        for ident in rule_result.findall('xccdf:ident', ns):
            if ident.get('system', '').endswith('cci'):
                cci_refs.append(ident.text)

        if rule_id:
            results.append({
                'rule_id': rule_id,
                'result': result_text,
                'cci': cci_refs
            })

    return results

def merge_into_mapping(scap_results, existing_mapping_path, output_path):
    mapping = {}
    if Path(existing_mapping_path).exists():
        with open(existing_mapping_path) as f:
            mapping = json.load(f)

    mapping.setdefault('scap_cci_mapping', {})
    mapping['scap_cci_mapping']['generated'] = datetime.now().isoformat()
    mapping['scap_cci_mapping']['source'] = str(existing_mapping_path)
    mapping['scap_cci_mapping']['results'] = scap_results
    mapping['scap_cci_mapping']['total_rules'] = len(scap_results)
    mapping['scap_cci_mapping']['rules_with_cci'] = sum(1 for r in scap_results if r['cci'])

    with open(output_path, 'w') as f:
        json.dump(mapping, f, indent=2)

    print(f"[+] Merged {len(scap_results)} SCAP results into mapping")
    print(f"[+] Rules with CCI references: {mapping['scap_cci_mapping']['rules_with_cci']}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--arf", required=True, help="Path to SCAP ARF results XML")
    parser.add_argument("--mapping", required=True, help="Existing OSCAL mapping JSON")
    parser.add_argument("--output", required=True, help="Output enriched mapping JSON")
    args = parser.parse_args()

    results = parse_arf(args.arf)
    merge_into_mapping(results, args.mapping, args.output)
