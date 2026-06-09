# Architecture Overview

The CyberForge platform is organized as a layered secure delivery system:

1. **Infrastructure layer** - Terraform-driven cluster, networking, and platform dependencies.
2. **Platform services** - policy engines, observability stack, secrets, and deployment control plane.
3. **Compliance layer** - OSCAL artifacts, STIG overlays, and SCAP/CCI processing workflows.
4. **Supply-chain controls** - signing, attestation, and software request vetting.

This structure supports continuous compliance and auditable change management.