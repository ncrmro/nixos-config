## Repository Overview

This is a NixOS configuration repository using flakes for managing system configurations across multiple hosts. The repository manages both NixOS system configurations and Home Manager user configurations, with a focus on infrastructure-as-code patterns.

## Investigating Issues on Hosts

When debugging service problems, investigate autonomously — run commands directly rather than asking the user to run them for you.

**Step 1: Identify the host**
```bash
cat /etc/hostname
```
Always check this first — available services differ per host (see Host Inventory below).

**Step 2: Use systemctl and journalctl liberally**
```bash
systemctl status <service>                         # Current state + recent logs
systemctl list-units --failed                      # All failed units
journalctl -u <service> --since "10 min ago"       # Recent logs
journalctl -u <service> -p err --since today       # Errors only
journalctl -u <service> --no-pager | tail -100     # Last 100 lines
```

**Step 3: sudo is not available**

`sudo` commands will fail. When investigation requires elevated privileges (reading root-owned logs, restarting services, checking firewall rules), write a short script to `/tmp` that dumps the output to a temp file, then ask the user to run it:

```bash
# Write a dump script the user can execute
cat > /tmp/debug-service.sh << 'EOF'
#!/bin/bash
sudo journalctl -u stalwart --since "1 hour ago" > /tmp/stalwart-logs.txt
sudo systemctl show stalwart --property=ActiveState,SubState,MainPID > /tmp/stalwart-status.txt
sudo ss -tlnp | grep -E ':(25|465|993|587) ' > /tmp/stalwart-ports.txt
echo "Done. Files written to /tmp/stalwart-*.txt"
EOF
chmod +x /tmp/debug-service.sh
```

The user runs the script once, then you read `/tmp/stalwart-logs.txt` etc. directly. This avoids repeated back-and-forth copy-pasting of command output.

## Keystone: Shared Convention Layer

[Keystone](https://github.com/ncrmro/keystone) is the upstream platform providing reusable NixOS modules that any user could adopt for their own infrastructure. It lives at `.submodules/keystone` as a git submodule and is consumed as a flake input.

**When to put something in keystone vs nixos-config:**
- **Keystone**: Reusable modules that others could benefit from (server roles, desktop setup, terminal environment, mail, DNS, binary cache, hardware key management)
- **nixos-config**: Host-specific configuration, secrets, per-user overrides, local-only services

**Keystone modules used in this repo:**

| Module | Import Path | Purpose |
|--------|-------------|---------|
| `operating-system` | `keystone.nixosModules.operating-system` | Base OS config, user management, hypervisor |
| `hardwareKey` | `keystone.nixosModules.hardwareKey` | YubiKey SSH/GPG management |
| `server` | `keystone.nixosModules.server` | Server infrastructure (ACME, DNS auto-generation, services) |
| `desktop` | `keystone.nixosModules.desktop` | Desktop environment (Hyprland, GNOME, etc.) |
| `headscale-dns` | `keystone.nixosModules.headscale-dns` | Auto-import DNS records from server configs |
| `terminal` | `keystone.homeModules.terminal` | Terminal environment for agents/users |

**Key keystone options used:**
- `keystone.os.mail` - Stalwart mail server (replaces direct `services.stalwart-mail` config)
- `keystone.os.gitServer` - Forgejo git server
- `keystone.server.acme` - Wildcard TLS certs via Cloudflare DNS-01
- `keystone.server.services.attic` - Attic binary cache server
- `keystone.server.tailscaleIP` - Tailscale IP for auto-DNS record generation
- `keystone.server.generatedDNSRecords` - Auto-generated DNS records consumed by mercury
- `keystone.binaryCache.push` - Attic binary cache push (on workstation/laptop)
- `keystone.os.agents.<name>` - Agent VM user provisioning (SSH keys, email, space repo)
- `keystone.os.services.airplay` - AirPlay receiver
- `keystone.os.services.resolved` - systemd-resolved for Tailscale MagicDNS

**Wrapper modules in this repo** (`modules/`):
- `modules/keystone.nix` - Imports `operating-system` + `hardwareKey`, configures YubiKeys and ncrmro user
- `modules/keystone.server.nix` - Imports `server` module, enables it
- `modules/keystone.desktop.nix` - Imports `desktop` module, configures for ncrmro user

## Clean Git History: Submodule + Flake Update Workflow

This repo has two git submodules that are also flake inputs. Both the submodule directory and `flake.lock` must be committed together to keep them pointing at the same commit.

**Submodules:**
- `.submodules/keystone` - GitHub: `github:ncrmro/keystone`
- `agenix-secrets` - Private Forgejo: `git+ssh://forgejo@git.ncrmro.com:2222/ncrmro/agenix-secrets.git`

### The Golden Rule

**NEVER run bare `nix flake update`**. A full update pulls new nixpkgs and all other inputs, causing massive rebuilds unrelated to your change. Always target specific inputs:

```bash
nix flake update keystone                    # keystone only
nix flake update agenix-secrets              # secrets only
nix flake update keystone agenix-secrets     # both submodules
```

### Updating Keystone

```bash
# 1. Make and test changes locally
cd .submodules/keystone
# ... edit files ...
cd ../..
./bin/keystone-dev --build   # Verify changes build (no sudo needed)

# 2. Commit and push from submodule
cd .submodules/keystone
git add -A && git commit -m "feat(server): description" && git push
cd ../..

# 3. Update flake input AND stage submodule together in ONE commit
nix flake update keystone
git add .submodules/keystone flake.lock
git commit -m "feat: update keystone (description)"
```

### Updating Agenix Secrets

```bash
# 1. Edit secrets in submodule
cd agenix-secrets
agenix -e secrets/new-secret.age   # or edit secrets.nix
git add -A && git commit -m "Add new secret" && git push
cd ..

# 2. Update flake input AND stage submodule together in ONE commit
nix flake update agenix-secrets
git add agenix-secrets flake.lock
git commit -m "chore: update agenix-secrets"
```

### Why Both Together?

The `flake.lock` pins the GitHub/Forgejo version while the submodule directory tracks the local checkout. Both must point to the same commit. Committing them separately creates confusion about which version is active and pollutes git history with unnecessary split commits.

### Handling flake.lock Conflicts During Rebase

```bash
git checkout --theirs flake.lock
nix flake update keystone   # or agenix-secrets, or both
git add flake.lock
git rebase --continue
```

### Adding External Nix Package Sources

Add as **flake inputs**, NOT git submodules. Choose the appropriate flake:
- **nixos-config flake.nix**: Packages/modules specific to this configuration
- **keystone flake.nix**: Packages/modules that should be part of the upstream platform

## Host Inventory

### Servers

| Host | Role | Location | Tailscale IP | Key Services |
|------|------|----------|--------------|--------------|
| **ocean** | Homelab server | Home LAN (192.168.1.10) | 100.64.0.6 | See below |
| **mercury** | VPS | Cloud | 100.64.0.38 | Headscale, DERP, AdGuard, Nginx |
| **maia** | Legacy server | Home LAN | — | SSH only (minimal config) |

### Desktops/Laptops

| Host | Role | Key Features |
|------|------|--------------|
| **ncrmro-workstation** | Primary desktop | AMD GPU, ZFS, Secure Boot, bridge networking for VMs, agent hosting, Attic push |
| **ncrmro-laptop** | Portable laptop | ZFS, Secure Boot, fingerprint reader, ZFS remote replication to maia |
| **mox** | Older desktop | Minimal config |

### Agent VMs

| Host | Agent | SSH Port | SPICE Port | Headscale User |
|------|-------|----------|------------|----------------|
| **agent-drago** | Primary coding agent | 2230 | 5900 | drago |
| **agent-luce** | Secondary agent | 2224 | 5901 | luce |
| **agent-drago-minimal** | Fast-build minimal image | — | — | — |
| **agent-base** | Base image for cloning | — | — | — |

### Other

| Host | Purpose |
|------|---------|
| **test-vm** | Desktop testing VM |
| **devbox** | Development box |
| **catalystPrimary** | Catalyst cluster node |

## Services on Ocean

Ocean is the primary homelab server. Services are configured through a mix of keystone modules and local optional modules.

| Service | Config Location | Access URL |
|---------|----------------|------------|
| **Stalwart Mail** | `keystone.os.mail` + `hosts/ocean/default.nix` | mail.ncrmro.com (IMAP/SMTP) |
| **Forgejo** | `keystone.os.gitServer` | git.ncrmro.com |
| **Attic** (binary cache) | `keystone.server.services.attic` | cache.ncrmro.com |
| **Grafana** | `hosts/ocean/observability/grafana.nix` | grafana.ncrmro.com |
| **Prometheus** | `hosts/ocean/observability/prometheus.nix` | prometheus.ncrmro.com |
| **Loki** | `hosts/ocean/observability/loki.nix` | loki.ncrmro.com |
| **Vaultwarden** | `hosts/ocean/vaultwarden.nix` | vaultwarden.ncrmro.com |
| **Home Assistant** | `hosts/common/optional/home-assistant.nix` | homeassistant.ncrmro.com |
| **AdGuard Home** | `hosts/ocean/adguard-home.nix` | adguard.ncrmro.com |
| **Servarr** (Sonarr, Radarr, etc.) | `hosts/common/optional/servarr.nix` | Various |
| **Immich** | `hosts/ocean/immich.nix` | immich.ncrmro.com |
| **RSSHub** | `hosts/ocean/rsshub.nix` | rsshub.ncrmro.com |
| **Miniflux** | `hosts/ocean/miniflux.nix` | miniflux.ncrmro.com |
| **Nginx** | `hosts/ocean/nginx.nix` | Reverse proxy for all services |
| **SMB Backups** | `hosts/common/optional/smb-backup-shares.nix` | Time Machine + Windows backup |
| **NFS** | `hosts/ocean/nfs.nix` | ZFS dataset exports |
| **Alloy** | `hosts/common/optional/alloy-client.nix` | Log/metric shipping to Loki/Prometheus |

All `*.ncrmro.com` domains resolve via Tailscale MagicDNS only. ACME wildcard certs are managed by `keystone.server.acme` via Cloudflare DNS-01.

## Services on Mercury

Mercury is a VPS running headscale and public-facing services.

| Service | Config Location |
|---------|----------------|
| **Headscale** | `modules/nixos/headscale/default.nix` |
| **DERP relay** | Part of headscale config |
| **AdGuard Home** | `hosts/mercury/adguard-home.nix` |
| **Nginx** | `hosts/mercury/nginx.nix` |
| **Alloy** | `hosts/common/optional/alloy-client.nix` |

### Auto-DNS Pipeline

DNS records flow automatically from ocean to mercury:
1. Ocean's `keystone.server` generates DNS records based on enabled services (`keystone.server.generatedDNSRecords`)
2. Mercury imports these via `keystone.headscale.dnsRecords = oceanConfig.keystone.server.generatedDNSRecords`
3. Headscale distributes them to all tailnet clients via MagicDNS

To add a new service with auto-DNS, enable it in ocean's keystone config and rebuild both ocean and mercury.

## Architecture

### Directory Structure

- `/hosts/` - Host-specific configurations
  - `/common/global/` - Global settings applied to all hosts
  - `/common/optional/` - Optional modules (tailscale, docker, k3s, etc.)
  - `/common/kubernetes/` - Kubernetes module definitions (legacy, not actively used)
- `/home-manager/` - User-specific Home Manager configurations
  - `/common/global/` - Shared home config
  - `/common/features/` - Feature modules (cli, desktop, email, etc.)
  - `/common/agents/` - Shared agent home config
  - `/common/optional/` - Optional home modules (MCP, mosh, etc.)
- `/modules/` - Custom NixOS and user modules
  - `keystone.nix`, `keystone.server.nix`, `keystone.desktop.nix` - Keystone wrapper modules
  - `/modules/nixos/` - Local NixOS modules (headscale, steam, bambu-studio)
  - `/modules/users/` - User definitions and SSH keys
- `.submodules/keystone/` - Upstream Keystone submodule
- `/agenix-secrets/` - Private submodule with encrypted secrets
- `/bin/` - Helper scripts
- `/overlays/` - Nix overlays (imports keystone overlay + local packages)
- `/packages/` - Local package definitions (claude-code, codex, gemini-cli, mcp-language-server, zesh)

### Flake Input Follows

Many flake inputs follow keystone to keep versions consistent and avoid duplicate downloads:
- `nixpkgs` follows `keystone/nixpkgs` (nixos-unstable)
- `home-manager`, `lanzaboote`, `agenix`, `nixos-hardware`, `nix-index-database`, `nix-flatpak` all follow keystone

## Host Infrastructure

| Host | Role | Tailscale IP | Key Services |
|------|------|-------------|--------------|
| **ocean** | Homelab server | `100.64.0.6` | Forgejo (git), Stalwart mail, Immich, Vaultwarden, Grafana, Prometheus, Loki, Miniflux, Attic, AdGuard, Home Assistant, SMB backups |
| **mercury** | VPN/DNS server | `100.64.0.38` | Headscale, DERP relay, AdGuard |
| **ncrmro-workstation** | Dev workstation | — | OS agents (agent-drago), desktop environment |
| **maia** | Laptop | — | Desktop environment |

**Ocean hosts most infrastructure services.** When debugging connectivity to services like Forgejo (`git.ncrmro.com:2222`), Stalwart mail, or Grafana, the target host is ocean. All services are accessible via Tailscale only (except Headscale on mercury which is public).

**Key ocean service endpoints:**
- Forgejo SSH: `git.ncrmro.com:2222` (via `keystone.os.gitServer`)
- Forgejo HTTP: `git.ncrmro.com` (nginx reverse proxy, port 3001)
- Stalwart mail: `mail.ncrmro.com` (IMAP 993, SMTP 465)
- Stalwart admin: port 8082

## Common Commands

### Building and Deploying

```bash
# Deploy to local system
sudo nixos-rebuild switch --flake .#<hostname>

# Deploy to remote host via Tailscale
./bin/sync <hostname> <ip_address>

# Update specific hosts (convenience scripts)
./bin/updateOcean         # Rebuild ocean
./bin/updateMercury       # Rebuild mercury
./bin/updateMaia          # Rebuild maia
./bin/updateWorkstation   # Rebuild workstation

# Verify local keystone changes (without sudo)
./bin/keystone-dev --build

# Check flake configuration
nix flake check
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

Home Manager is integrated into NixOS and activated automatically during `nixos-rebuild switch`. **Never run `home-manager switch` directly** - it conflicts with the NixOS-managed home-manager service.

## Agent VMs

Agent VMs are isolated NixOS virtual machines for autonomous AI agents. Each agent has its own identity, credentials, and environment. They run on the workstation host via libvirt/QEMU.

### Agent VM Configuration

Key configuration files:
- `hosts/common/optional/agent-base.nix` - System-level config (GNOME, SSH, systemd-resolved, browser policies)
- `hosts/common/optional/agent-minimal.nix` - Minimal SSH-only variant (fast build)
- `home-manager/common/agents/base.nix` - Shared packages (bat, fd, fzf, jq, btop, gh, browsers, SSH keygen)
- `home-manager/drago/agent.nix` - Drago-specific config (imports keystone.terminal + agent base)
- `home-manager/luce/agent.nix` - Luce-specific config

Agent users are provisioned on the workstation host via `keystone.os.agents.<name>` which sets up SSH keys, email, and agent workspace ("space") repos.

### Remote Rebuild and Deploy

Agents auto-connect to headscale on boot. Update via Tailscale:

```bash
nixos-rebuild switch --flake .#agent-drago --target-host drago@agent-drago --build-host localhost
nixos-rebuild switch --flake .#agent-luce --target-host luce@agent-luce --build-host localhost
```

### Building Agent Images

```bash
# Build base qcow2 image
nix build .#nixosConfigurations.agent-base.config.system.build.qcow2
cp result/nixos.qcow2 ~/.agentvms/agent-drago.qcow2

# Define and start VM
virsh --connect qemu:///session define hosts/agent-drago/vm.xml
virsh --connect qemu:///session start agent-drago
```

See [docs/agentvms.md](docs/agentvms.md) for full documentation.

## Headscale ACL Management

ACL configuration is in `modules/nixos/headscale/acl.hujson`. See the file header for deployment instructions.

**IMPORTANT**: After modifying ACLs, you must:
1. Deploy to mercury: `nixos-rebuild switch --flake .#mercury`
2. Restart headscale: `sudo systemctl restart headscale`
3. Restart tailscaled on affected nodes to pick up the new network map

**Applying tags to nodes:**
```bash
headscale nodes list -t  # Show current tags
headscale nodes tag -i <node-id> -t tag:name1,tag:name2
```

**Key tags:**
- `tag:agent` - Agent VMs (allows access to ocean services)
- `tag:server` - Server nodes
- `tag:ocean-ingress` - Ocean node ingress (ports 80, 443, 2222)
- `tag:ocean-email` - Ocean node email (ports 993, 465, 25)

## Stalwart Mail Server

Stalwart is configured on ocean via `keystone.os.mail`. The keystone module handles the NixOS service setup; host-specific config (TLS certs, admin auth, allowed IPs) is in `hosts/ocean/default.nix`.

### Service Name

```bash
systemctl status stalwart
journalctl -u stalwart --since "10 min ago"
```

### Stalwart TOML Custom Syntax

Stalwart uses a custom TOML parser with set notation:

| Setting | Stalwart Syntax | Standard TOML (WRONG) |
|---------|----------------|----------------------|
| IP allowlist | `allowed-ip = { "10.0.0.0/8" }` | `allowed-ip = ["10.0.0.0/8"]` |
| Multiple values | `{ "a", "b", "c" }` | `["a", "b", "c"]` |

### Debugging IP Blocking

If Himalaya/IMAP clients get "TLS handshake EOF" errors:
1. Check Stalwart logs: `journalctl -u stalwart --since "10 min ago" | grep -i block`
2. Look for `security.ip-blocked` messages
3. Tailscale IPs are allowlisted via `keystone.os.mail.allowedIps`
4. Clear existing blocks via admin UI or API:
   ```bash
   curl -X DELETE -u admin:$(sudo cat /run/agenix/stalwart-admin-password) \
     "http://localhost:8082/api/blocked?ip=100.64.0.7"
   ```

## Himalaya Email Client

Himalaya is configured via a shared module at `home-manager/common/features/cli/himalaya.nix` with per-user overrides.

### Per-User Configuration

- Drago: `home-manager/drago/himalaya.nix`
- ncrmro: `home-manager/ncrmro/base.nix`

### Stalwart Folder Names

The module auto-maps Himalaya defaults to Stalwart names:

| Himalaya Default | Stalwart Name |
|------------------|---------------|
| Sent | Sent Items |
| Drafts | Drafts |
| Trash | Deleted Items |

### Sending Raw Emails

Always include the `Date:` header (without it, emails show as 1970-01-01):

```bash
echo "From: user@ncrmro.com
To: recipient@ncrmro.com
Subject: Test
Date: $(date -R)
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8

Body here" | himalaya message send
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
  ../common/optional/tailscale.node.nix
  ../common/optional/docker-rootless.nix
];
```

### Kubernetes Resources

Kubernetes modules exist in `/hosts/common/kubernetes/` for K3s deployments using `services.k3s.autoDeployCharts`. When using chart hashes, start with `hash = "";` (empty string) and update after the first build provides the correct hash.

## Key Technologies

- **NixOS unstable** (nixpkgs follows keystone)
- **Keystone**: Self-sovereign infrastructure platform (upstream modules)
- **Disko**: Declarative disk partitioning
- **Lanzaboote**: Secure Boot support
- **ZFS**: Advanced filesystem with snapshots and replication
- **Tailscale/Headscale**: Mesh VPN networking
- **Agenix**: Secret management
- **Attic**: Nix binary cache (server on ocean, push from workstation/laptop)
- **Alloy**: Grafana Alloy for log/metric shipping

## Important Notes

- Use `nix flake check` to validate configuration before deployment
- Host-specific secrets are in `/agenix-secrets/secrets/` and require appropriate age keys
- ZFS systems require `networking.hostId` to be set uniquely per host
- Secure Boot systems use TPM for automatic disk unlock
- `agenix-secrets` is only accessible via Tailscale (git.ncrmro.com resolves to a Tailscale IP)
