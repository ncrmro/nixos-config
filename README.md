## NixOS configuration (flake)

This repository contains my NixOS flake and host configurations.

## Documentation

- [Installing NixOS with nixos-anywhere](docs/INSTALL_NIXOS_ANYWHERE.md) - Installation instructions, ZFS notes, Secure Boot (lanzaboote), TPM enrollment, and post-install commands
- [Headscale and Tailscale Setup](docs/HEADSCALE_SETUP.md) - Self-hosted Tailscale control server setup and client configuration
- [Tailscale + GitHub Actions](docs/TAILSCALE_GITHUB_ACTIONS.md) - **NEW!** Comprehensive guide for Tailscale/Headscale integration with GitHub Actions
- [Tailscale Quick Start](docs/TAILSCALE_QUICKSTART.md) - **NEW!** Quick setup guide for GitHub Actions with Tailscale
- [VPS Notes](docs/vps-notes.md) - Notes about VPS setup
- [DNS Configuration](docs/DNS.md) - DNS setup and configuration
- [Kubernetes Modules](docs/KUBERNETES_MODULES.md) - Kubernetes modules documentation
- [Kubernetes SSL Certificates](docs/KUBERNETES_SSL_CERTIFICATES.md) - SSL certificate management for Kubernetes
- [Root Disk TPM Secure Boot Unlock](docs/ROOT_DISK_TPM_SECURE_BOOT_UNLOCK.md) - TPM and Secure Boot disk unlock configuration
- [ZFS Remote Replication](docs/ZFS_REMOTE_REPLICATION.md) - ZFS remote replication setup
- [Fingerprint Enrollment](docs/fingerprint-enrollment.md) - Fingerprint authentication setup
- [Mounting Old Disks](docs/mounting-old-disks.md) - Instructions for mounting legacy disks
- [ZFS Tweaks](docs/zfs-tweaks.md) - ZFS performance and configuration tweaks

### GitHub Actions Examples

This repository includes example workflows and reusable actions for integrating with Tailscale:
- [Setup Tailscale Action](.github/actions/setup-tailscale/) - Reusable action for connecting to Tailscale
- [Kubernetes Deployment Example](.github/workflows/deploy-k8s-example.yml) - Deploy to K8s via Tailscale
- [Service Health Check Example](.github/workflows/service-health-check-example.yml) - Monitor services over Tailscale
- [Database Backup Example](.github/workflows/database-backup-example.yml) - Backup databases via Tailscale
