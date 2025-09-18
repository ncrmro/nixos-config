## Repository Overview

This is a NixOS configuration repository using flakes for managing system configurations across multiple hosts. The repository manages both NixOS system configurations and Home Manager user configurations, with a focus on infrastructure-as-code patterns.

## Architecture

### Core Components

- **Flake-based Configuration**: All system configurations are managed through `flake.nix` which defines multiple NixOS systems and Home Manager configurations
- **Host-specific Configurations**: Each host (mox, maia, ocean, mercury, etc.) has its own configuration in `/hosts/<hostname>/`
- **Modular Structure**: Common configurations are shared via `/hosts/common/` with optional features that can be imported per-host
- **Kubernetes Integration**: Several hosts run K3s with NixOS-managed Kubernetes resources
- **ZFS Storage**: Many systems use ZFS with LUKS encryption and remote replication
- **Secret Management**: Uses agenix for encrypted secrets management

### Directory Structure

- `/hosts/` - Host-specific configurations
  - `/common/global/` - Global settings applied to all hosts
  - `/common/optional/` - Optional modules (tailscale, docker, k3s, etc.)
  - `/common/kubernetes/` - Kubernetes module definitions
- `/home-manager/` - User-specific Home Manager configurations
- `/modules/` - Custom NixOS and user modules
- `/bin/` - Helper scripts for deployment and management
- `/docs/` - Documentation for various setup procedures
- `/kubernetes/` - Raw Kubernetes manifests (legacy)
- `/secrets/` - Encrypted secrets managed by agenix

## Common Commands

### Building and Deploying

```bash
# Format code with alejandra
alejandra .

# Check flake configuration
nix flake check

# Update flake inputs
nix flake update

# Deploy to local system
sudo nixos-rebuild switch --flake .#<hostname>

# Deploy to remote host
./bin/sync <hostname> <ip_address>

# Update specific hosts (convenience scripts)
./bin/updateMaia       # Update maia host
./bin/updateOcean      # Update ocean host
./bin/updateMercury    # Update mercury host
```

### Development Workflow

```bash
# Check and format code before committing
./bin/check

# Setup pre-commit hooks
./bin/setup-precommit

# Test configuration in VM
nix build .#nixosConfigurations.test-vm.config.system.build.vm
./result/bin/run-test-vm-vm
```

### Home Manager

```bash
# Switch Home Manager configuration
home-manager switch --flake .#ncrmro@<hostname>
```

## Configuration Patterns

### Adding a New Host

1. Create directory `/hosts/<hostname>/`
2. Add `default.nix` with host configuration
3. Add `hardware-configuration.nix` (generate with `nixos-generate-config`)
4. Optional: Add `disk-config.nix` for disko-managed disk layout
5. Register in `flake.nix` under `nixosConfigurations`

### Enabling Optional Features

Import from `/hosts/common/optional/` in your host's `default.nix`:

```nix
imports = [
  ../common/global
  ../common/optional/tailscale.nix
  ../common/optional/docker-rootless.nix
];
```

### Kubernetes Resources

For hosts running K3s, Kubernetes resources can be managed through NixOS modules in `/hosts/common/kubernetes/`. These modules use the `services.kubernetes.helm.releases` and raw manifest application.

## Key Technologies

- **NixOS 25.05**: Primary stable channel
- **Disko**: Declarative disk partitioning
- **Lanzaboote**: Secure Boot support
- **K3s**: Lightweight Kubernetes
- **ZFS**: Advanced filesystem with snapshots and replication
- **Tailscale/Headscale**: Mesh VPN networking
- **Agenix**: Secret management

## Important Notes

- Always run `alejandra .` before committing to maintain consistent formatting
- Use `nix flake check` to validate configuration before deployment
- Host-specific secrets are in `/secrets/` and require appropriate age keys
- ZFS systems require `networking.hostId` to be set uniquely per host
- Secure Boot systems use TPM for automatic disk unlock
