# Air-Gapped Deployment Guide

This guide documents the baseline approach for deploying CyberForge in a disconnected environment.

## High-level flow
1. Mirror required images and artifacts into an approved internal registry.
2. Transfer signed release bundles through controlled media.
3. Apply infrastructure and platform manifests from internal sources only.
4. Validate policy, logging, and compliance controls after deployment.

All dependencies must be reviewed and approved before import.