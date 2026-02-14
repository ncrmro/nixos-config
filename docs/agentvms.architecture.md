# Agent VMs Architecture

This document describes the implementation architecture for agent VMs.

## Overview

Agent VMs use a two-phase deployment model:

1. **Base Image Build** - A generic qcow2 image built from `hosts/agent-base/` containing both agent users and basic configuration, stored in `~/.agentvms/`
2. **Agent-Specific Config** - After booting, run `nixos-rebuild` to apply the agent's full configuration from nixos-config

This approach maximizes code reuse while allowing per-agent customization.

## Directory Structure

All configuration lives in nixos-config:

```
hosts/
├── agent-base/                    # Base VM image builder
│   ├── default.nix                # Base NixOS config (both users)
│   └── qcow.nix                   # Disk image settings (20GB qcow2)
├── agent-drago/default.nix        # Drago NixOS (imports shared)
├── agent-luce/default.nix         # Luce NixOS (imports shared)
└── common/optional/
    └── agent-base.nix             # SHARED: GNOME, SPICE, SSH, Tailscale

home-manager/
├── common/agents/base.nix         # SHARED: SSH keys, Git, Bitwarden
├── drago/
│   ├── agent.nix                  # Drago home-manager
│   └── himalaya.nix               # Drago email config
└── luce/
    ├── agent.nix                  # Luce home-manager
    └── himalaya.nix               # Luce email config

modules/users/
├── drago.nix                      # Drago user definition
└── luce.nix                       # Luce user definition

secrets/
├── stalwart-mail-drago-password.age
└── stalwart-mail-luce-password.age
```

## Shared vs Agent-Specific

### Shared Configuration

**hosts/common/optional/agent-base.nix** contains:
- GNOME desktop with auto-login disabled (overridden per-agent)
- SPICE guest integration
- SSH server
- NetworkManager
- Tailscale (non-admin mode, agent tags)
- Nix flakes settings
- QEMU guest agent

**home-manager/common/agents/base.nix** contains:
- Keystone terminal packages (eza, htop, jq, fzf, etc.)
- SSH key auto-generation service
- Git configuration with SSH signing
- Bitwarden CLI
- GNOME Keyring integration
- Common shell aliases

### Agent-Specific Configuration

Each agent overrides:
- `home.username` and `home.homeDirectory`
- `programs.git.userEmail` and `programs.git.userName`
- Himalaya email configuration
- Display auto-login user
- SSH port forward and SPICE port

## Build Process

### Base Image Build

```bash
nix build .#nixosConfigurations.agent-base.config.system.build.qcow2
```

This produces `result/nixos.qcow2` (~7GB with full /nix/store).

### Deployment Flow

```
1. Copy base image to ~/.agentvms/
   └── cp result/nixos.qcow2 ~/.agentvms/agent-{name}.qcow2

2. Define VM with libvirt XML
   └── virsh --connect qemu:///session define agent-{name}.xml

3. Start VM
   └── virsh --connect qemu:///session start agent-{name}

4. SSH into VM
   └── ssh -p 222{3|4} {name}@localhost

5. Apply agent-specific config
   └── sudo nixos-rebuild switch --flake github:ncrmro/nixos-config#agent-{name}

6. Extract host key, update secrets.nix, re-encrypt
   └── See "Secrets Management" below

7. Rebuild to activate secrets
   └── sudo nixos-rebuild switch --flake github:ncrmro/nixos-config#agent-{name}
```

## Secrets Management

Agent VMs use agenix for secrets. The flow:

1. **Before Deployment** - Create secret file (e.g., stalwart-mail-luce-password.age)
2. **First Boot** - VM generates SSH host key
3. **Extract Key** - Get the host key from `/var/ssh/ssh_host_ed25519_key.pub`
4. **Update secrets.nix** - Add VM's host key to publicKeys arrays
5. **Re-encrypt** - Run `agenix -r` to re-encrypt secrets
6. **Rebuild VM** - Secrets now accessible in VM

### Host Key Extraction

```bash
# From host, via SSH
ssh -p 2223 drago@localhost "cat /var/ssh/ssh_host_ed25519_key.pub"

# Or from VM console
cat /var/ssh/ssh_host_ed25519_key.pub
```

## Adding New Agents

### Step 1: Create User Module

Create `modules/users/{name}.nix`:

```nix
{ config, pkgs, ... }:
{
  users.users.{name} = {
    isNormalUser = true;
    description = "Agent Description";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "password";
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # Add authorized SSH keys
    ];
  };
}
```

### Step 2: Create Host Config

Create `hosts/agent-{name}/default.nix`:

```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../common/optional/agent-base.nix
    ../../modules/users/{name}.nix
    ../../modules/users/ncrmro.nix  # Admin user
    inputs.home-manager.nixosModules.default
    inputs.agenix.nixosModules.default
  ];

  networking.hostName = "agent-{name}";

  # Auto-login user
  services.displayManager.autoLogin.user = "{name}";

  # Secrets
  age.secrets.stalwart-mail-{name}-password = {
    file = ../../secrets/stalwart-mail-{name}-password.age;
    owner = "{name}";
    mode = "0400";
  };

  home-manager.users.{name} = {
    imports = [
      ../../home-manager/{name}/agent.nix
      ../../home-manager/{name}/himalaya.nix
    ];
  };

  system.stateVersion = "24.05";
}
```

### Step 3: Create Home-Manager Config

Create `home-manager/{name}/agent.nix`:

```nix
{ pkgs, ... }:
{
  imports = [ ../common/agents/base.nix ];

  home.username = "{name}";
  home.homeDirectory = "/home/{name}";

  programs.git.userEmail = "{name}@ncrmro.com";
  programs.git.userName = "{Name}";

  home.stateVersion = "24.05";
}
```

### Step 4: Create Himalaya Config

Create `home-manager/{name}/himalaya.nix` (copy from drago, update email/user).

### Step 5: Create Secret

```bash
# Create the password
echo "secure-password" | age -e -R secrets.nix > secrets/stalwart-mail-{name}-password.age

# Update secrets.nix to add the new secret
```

### Step 6: Register in flake.nix

Add to `nixosConfigurations`:

```nix
agent-{name} = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./hosts/agent-{name} ];
  specialArgs = { inherit inputs self; outputs = self; };
};
```

### Step 7: Update agent-base

Add the new user to `hosts/agent-base/default.nix` so base images include the user.

### Step 8: Build and Deploy

```bash
# Rebuild base image
nix build .#nixosConfigurations.agent-base.config.system.build.qcow2

# Copy to ~/.agentvms/
mkdir -p ~/.agentvms
cp result/nixos.qcow2 ~/.agentvms/agent-{name}.qcow2

# Deploy as described above
```

## Network Configuration

### Port Assignments

| Agent | SSH Port | SPICE Port |
|-------|----------|------------|
| drago | 2223 | 5900 |
| luce | 2224 | 5901 |
| (next) | 2225 | 5902 |

### Tailscale

Agents join the tailnet with agent-specific tags for ACL control:

```bash
tailscale up --login-server=https://headscale.ncrmro.com --advertise-tags=tag:agent
```

## Libvirt XML Template

```xml
<domain type='kvm'>
  <name>agent-{name}</name>
  <memory unit='GiB'>4</memory>
  <vcpu>2</vcpu>
  <os>
    <type arch='x86_64'>hvm</type>
    <boot dev='hd'/>
  </os>
  <devices>
    <emulator>/run/current-system/sw/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/home/ncrmro/.agentvms/agent-{name}.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='user'>
      <mac address='52:54:00:XX:XX:XX'/>
      <model type='virtio'/>
    </interface>
    <graphics type='spice' port='590X' autoport='no' listen='127.0.0.1'/>
    <video>
      <model type='virtio'/>
    </video>
    <channel type='spicevmc'>
      <target type='virtio' name='com.redhat.spice.0'/>
    </channel>
  </devices>
</domain>
```

## Related Documentation

- [Agent VMs User Guide](./agentvms.md) - Usage instructions
- [Agenix Secret Management](./AGENIX_SECRET_MANAGEMENT.md) - Secret encryption
