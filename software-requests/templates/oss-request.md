# Software Request: Open Source Software (OSS)
# Complete this template and submit as a pull request to the `software-requests/` directory.

## Package Information

| Field             | Value                          |
|-------------------|--------------------------------|
| Package Name      |                                |
| Version Requested |                                |
| License Type      |                                |
| Project URL       |                                |
| Container Image   |                                |
| Source Repository |                                |

## Justification

**Business/Mission Need:**
> Describe why this software is needed and which CyberForge component or workload requires it.

**Alternatives Considered:**
> List any alternatives evaluated and why they were not selected.

## Security Review

**Known CVEs / Advisories:**
> List any known CVEs at the requested version and their mitigations.

**License Compatibility:**
> Confirm that the license is compatible with government use and USG distribution requirements.

**Supply Chain:**
> Is the package available in IronBank? If so, reference the image.
> If not, is the source reproducible and verifiable?

**SBOM Available:**
- [ ] Yes — attach or link the SBOM (SPDX/CycloneDX)
- [ ] No — SBOM generation will be run during the vetting pipeline

## Risk Assessment

| Category          | Risk Level (Low/Med/High) | Notes |
|-------------------|--------------------------|-------|
| CVE Severity      |                          |       |
| License Risk      |                          |       |
| Supply Chain Risk |                          |       |
| Operational Risk  |                          |       |

**Overall Risk Level:** Low / Medium / High _(circle one)_

## Approval

| Role               | Name | Signature | Date |
|--------------------|------|-----------|------|
| Requesting Team    |      |           |      |
| Security Reviewer  |      |           |      |
| Authorizing Ofcl   |      |           |      |

---
*Submit as a pull request. The automated vetting pipeline will run SBOM generation,
vulnerability scanning, and license checks before routing for human approval.*