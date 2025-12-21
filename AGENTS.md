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
  - `.submodules/keystone/` - The upstream Keystone repository containing core infrastructure modules
- `/bin/` - Helper scripts for deployment and management
- `/docs/` - Documentation for various setup procedures
- `/kubernetes/` - Raw Kubernetes manifests (legacy)
- `/secrets/` - Encrypted secrets managed by agenix

### Keystone Submodule

Located at `.submodules/keystone`, this is a Git submodule tracking the [ncrmro/keystone](https://github.com/ncrmro/keystone) repository. Keystone provides the core infrastructure-as-code building blocks used by this repository.

**Key capabilities:**
- **Self-Sovereign Infrastructure**: Configurations for bare-metal and cloud environments.
- **Server Roles**: Gateway, VPN endpoint, DNS, storage, and backup servers.
- **Client Roles**: Workstations (always-on dev machines) and Interactive Clients (laptops/portables).
- **Security**: TPM integration, Full Disk Encryption (LUKS), Secure Boot, and Zero-Knowledge architecture.
- **NixOS Modules**: Reusable modules for servers, clients, disko configurations, secure boot, and more.

**Development Workflow:**
When developing features intended for upstream Keystone:
1. Make changes in `.submodules/keystone`.
2. Test using the local override mechanism (e.g., `nixos-rebuild switch ... --override-input keystone "path:.submodules/keystone"`).
3. Commit and push changes from the submodule directory.
4. Update the flake input lock in the main repository.

## Common Commands

### Building and Deploying

```bash
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

Home Manager is integrated into NixOS and activated automatically during `nixos-rebuild switch`. **Never run `home-manager switch` directly** - it will cause conflicts with the NixOS-managed home-manager service.

```bash
# CORRECT: Home Manager is applied as part of NixOS rebuild
sudo nixos-rebuild switch --flake .#<hostname>

# WRONG: Do not use home-manager directly
# home-manager switch --flake .#ncrmro@<hostname>  # Don't do this!
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

For hosts running K3s, Kubernetes resources can be managed through NixOS modules in `/hosts/common/kubernetes/`. These modules use the `services.k3s.autoDeployCharts` for Helm chart deployments and raw manifest application.

#### Important: Helm Chart Hash Values

When using `services.k3s.autoDeployCharts`, the initial `hash` value should always be an empty string `""`, not `"sha256-PLACEHOLDER"` or similar placeholders. This allows Nix to fetch the chart and emit the proper hash on first deployment.

```nix
services.k3s.autoDeployCharts = {
  example-chart = {
    name = "example";
    repo = "https://charts.example.com";
    version = "1.0.0";
    hash = ""; # Use empty string for initial deployment
    targetNamespace = "default";
    values = { /* chart values */ };
  };
};
```

After the first deployment attempt, Nix will provide the correct hash which should then be updated in the configuration.

## Key Technologies

- **NixOS 25.05**: Primary stable channel
- **Disko**: Declarative disk partitioning
- **Lanzaboote**: Secure Boot support
- **K3s**: Lightweight Kubernetes
- **ZFS**: Advanced filesystem with snapshots and replication
- **Tailscale/Headscale**: Mesh VPN networking
- **Agenix**: Secret management

## Important Notes

- Use `nix flake check` to validate configuration before deployment
- Host-specific secrets are in `/secrets/` and require appropriate age keys
- ZFS systems require `networking.hostId` to be set uniquely per host
- Secure Boot systems use TPM for automatic disk unlock
