# TODO

## Completed ✅
- [x] Expand all placeholder documentation files.
- [x] Implement `scripts/validate-project.sh` — runs 52 checks, all passing.
- [x] Implement `scripts/generate-full-ssp.sh` — OSCAL SSP assembly script.
- [x] Implement `scripts/generate-project-tree.sh` — regenerates project-tree.txt.
- [x] Implement `scripts/baselines/sync-stig-baselines.sh` — STIG baseline sync.
- [x] Implement `scripts/overlays/generate-stig-overlay.py` — STIG overlay generator.
- [x] Implement `scripts/scap/parse-scap-cci.py` — SCAP ARF CCI parser.
- [x] Implement `project_monitor.py` — continuous project health monitor.
- [x] Implement `bootstrap.sh` — full environment bootstrap script.
- [x] Populate `.env.example` with all required variables.
- [x] Implement all Terraform infrastructure files (main, variables, 6 modules).
- [x] Implement all platform service Helm values (ArgoCD, Vault, MinIO, ELK, Kyverno).
- [x] Implement all baseline policy packs (container-stig, k8s-stig, OS STIG, sidecar-stack, ironbank-mirror).
- [x] Implement all CI/CD pipeline files (gitlab-ci, scap-scan, software-vetting, cosign-sign).
- [x] Implement supply-chain files (cosign-policy, syft-config).
- [x] Implement tenancy RBAC manifests.
- [x] Implement software request templates (COTS, GOTS, OSS) and vetting workflow.
- [x] Implement OSCAL compliance artifacts (JSIG overlay, component definition, SSP implementations).
- [x] Implement Windows 11 MLL overlay.
- [x] Populate reference files (DAAPM CSV, STIG profile, NIST 800-53 catalog stubs).
- [x] Create `.gitignore`.

## Remaining (operational tasks — require real environment)
- [ ] Run `scripts/baselines/sync-stig-baselines.sh` to download full STIG content.
- [ ] Configure `.env` from `.env.example` with real credentials.
- [ ] Initialize Terraform backend (S3 + DynamoDB for state locking).
- [ ] Run `terraform plan` / `terraform apply` for infrastructure provisioning.
- [ ] Deploy platform services to Kubernetes cluster.
- [ ] Run SCAP scan against live nodes and review compliance score.
- [ ] Expand OSCAL component definition as new platform components are added.
- [ ] Set up CyberForge Cosign signing key and distribute public key to Kyverno policies.
- [ ] Onboard first tenant namespace and test RBAC.