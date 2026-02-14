# Agent VMs

Agent VMs are isolated NixOS virtual machines designed for autonomous AI agents. Each agent has its own identity, credentials, and environment.

## What are Agent VMs?

Agent VMs are lightweight NixOS VMs that provide:
- Isolated execution environments for AI agents
- Independent identities (SSH keys, email accounts, Tailscale nodes)
- Full desktop environments (GNOME) for GUI-based automation
- Bitwarden integration for secret management

## Why Agent VMs?

### Security Isolation
Each agent runs in its own VM, completely isolated from the host system. Agents cannot access host files, credentials, or other agents' data.

### Independent Identities
Every agent has its own:
- SSH keypair (auto-generated on first boot)
- Email account (via Stalwart mail server)
- Tailscale identity (for secure networking)
- Git identity (for commits and PRs)

### Reproducible Environments
VMs are built declaratively with NixOS. An agent can be destroyed and recreated from scratch at any time, with the same configuration.

### Safe Experimentation
If an agent corrupts its environment, simply delete the VM and rebuild it. No risk to the host system or other agents.

## Available Agents

| Agent | Purpose | SSH Port | SPICE Port |
|-------|---------|----------|------------|
| drago | Primary coding agent | 2223 | 5900 |
| luce | Secondary agent | 2224 | 5901 |

## Quick Start

### Building the Base Image

```bash
# Build the base qcow2 image (from nixos-config repo)
nix build .#nixosConfigurations.agent-base.config.system.build.qcow2

# Create ~/.agentvms/ and copy images for each agent
mkdir -p ~/.agentvms
cp result/nixos.qcow2 ~/.agentvms/agent-drago.qcow2
cp result/nixos.qcow2 ~/.agentvms/agent-luce.qcow2
```

### Deploying a VM

```bash
# Define the VM in libvirt
virsh --connect qemu:///session define hosts/agent-drago/vm.xml
virsh --connect qemu:///session start agent-drago

# SSH into the VM (initial password: "password")
ssh -p 2223 drago@localhost

# Apply the final configuration
sudo nixos-rebuild switch --flake github:ncrmro/nixos-config#agent-drago
```

### Connecting via SPICE (GUI)

```bash
# Connect to the graphical display
remote-viewer spice://localhost:5900
```

## Usage

### SSH Access

```bash
# Drago
ssh -p 2223 drago@localhost

# Luce
ssh -p 2224 luce@localhost
```

### Managing VMs

```bash
# List VMs
virsh --connect qemu:///session list --all

# Start/stop VMs
virsh --connect qemu:///session start agent-drago
virsh --connect qemu:///session shutdown agent-drago

# Force stop
virsh --connect qemu:///session destroy agent-drago

# Delete VM definition
virsh --connect qemu:///session undefine agent-drago
```

### Email (Himalaya)

```bash
# List inbox
himalaya envelope list

# Read message
himalaya message read <id>

# Send message
himalaya message write --to someone@example.com
```

### Tailscale

```bash
# Join the tailnet (run inside VM)
sudo tailscale up --login-server=https://headscale.ncrmro.com

# Check status
tailscale status
```

## Adding SSH Keys to GitHub

After the VM is deployed and SSH keys are generated:

```bash
# Inside the VM
cat ~/.ssh/id_ed25519.pub

# Copy the key and add to GitHub:
# Settings -> SSH and GPG keys -> New SSH key
```

## Troubleshooting

### VM won't start

Check if the qcow2 image exists:
```bash
ls -la ~/.agentvms/agent-drago.qcow2
```

Check libvirt logs:
```bash
journalctl --user -u libvirtd -n 50
```

### Can't SSH into VM

1. Ensure VM is running: `virsh --connect qemu:///session list`
2. Check port forwarding in VM XML definition
3. Verify SSH service is running inside VM

### SPICE display not working

Ensure qemu_full package is used (not qemu_kvm) and SPICE ports are configured in the VM XML.

## See Also

- [Architecture Documentation](./agentvms.architecture.md) - Implementation details
- [Stalwart Mail Setup](./stalwart.md) - Email server configuration
- [Tailscale Quickstart](./TAILSCALE_QUICKSTART.md) - VPN setup
