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
- `/agenix-secrets/` - Private submodule containing encrypted agenix secrets

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
2. Test using the local override mechanism:
   - **Recommended**: Use `bin/keystone-dev --build` to verify changes build correctly without needing `sudo`.
   - Alternative: `nixos-rebuild switch ... --override-input keystone "path:.submodules/keystone"`
3. Commit and push changes from the submodule directory:
   ```bash
   cd .submodules/keystone
   git add -A && git commit -m "feat(server): description" && git push
   cd ../..
   ```
4. **IMPORTANT**: Update flake input AND stage submodule together in ONE commit:
   ```bash
   nix flake update keystone
   git add .submodules/keystone flake.lock
   git commit -m "feat: update keystone with description"
   # Or amend if updating an existing commit:
   # git commit --amend
   ```

**Why both together?** The flake.lock pins the GitHub version while `.submodules/keystone` tracks the local checkout. Both must point to the same commit for consistency. Committing them separately can cause confusion about which version is active.

**Handling flake.lock Conflicts During Rebase:**
When rebasing and encountering `flake.lock` conflicts, always accept upstream changes then re-lock:
```bash
git checkout --theirs flake.lock
nix flake update keystone  # or whatever input was updated
git add flake.lock
git rebase --continue
```

**Adding External Nix Package Sources:**
When adding external Nix package sources (e.g., `numtide/llm-agents.nix` for AI coding tools), add them as **flake inputs**, NOT as git submodules. Choose the appropriate flake based on scope:
- **nixos-config flake.nix**: For packages/modules specific to this configuration
- **keystone flake.nix**: For packages/modules that should be part of the upstream Keystone platform

Example flake input:
```nix
llm-agents = {
  url = "github:numtide/llm-agents.nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Agenix Secrets Flake Input

The `agenix-secrets` input is a private Git repository containing encrypted secrets. It's fetched as a flake input rather than a submodule to ensure secrets are properly included in nix store paths.

**Repository:** `ssh://forgejo@git.ncrmro.com:2222/ncrmro/agenix-secrets.git`

**Important:** This repository is only accessible via Tailscale (git.ncrmro.com resolves to a Tailscale IP). Builds will fail without Tailscale connection.

**Contents:**
- `secrets.nix` - Defines which SSH keys can decrypt which secrets
- `secrets/` - Directory containing all `.age` encrypted secret files

**Update Workflow:**
When updating secrets, always commit the submodule and flake.lock together:
```bash
# 1. Edit secrets in submodule
cd agenix-secrets
agenix -e secrets/new-secret.age  # or edit secrets.nix
git add -A && git commit -m "Add new secret" && git push
cd ..

# 2. IMPORTANT: Update flake input AND stage submodule together in ONE commit
nix flake update agenix-secrets
git add agenix-secrets flake.lock
git commit -m "chore: update agenix-secrets"
```

**Why both together?** The flake.lock pins the Git version while `agenix-secrets/` tracks the local checkout. Both must point to the same commit for consistency. Committing them separately can cause confusion about which version is active.

**Handling flake.lock Conflicts During Rebase:**
When rebasing and encountering `flake.lock` conflicts, always accept upstream changes then re-lock:
```bash
git checkout --theirs flake.lock
nix flake update agenix-secrets  # or whatever input was updated
git add flake.lock
git rebase --continue
```

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

# Verify local keystone changes (without sudo)
./bin/keystone-dev --build

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

## Agent VMs

Agent VMs are isolated NixOS virtual machines for autonomous AI agents. Each agent has its own identity, credentials, and environment.

### Available Agents

| Agent | Purpose | SSH Port | SPICE Port | Headscale User |
|-------|---------|----------|------------|----------------|
| drago | Primary coding agent | 2230 | 5900 | drago |
| luce | Secondary agent | 2224 | 5901 | luce |

### Agent VM Configuration

Key configuration files:
- `hosts/common/optional/agent-base.nix` - System-level config (GNOME, SSH, DNS, browser policies)
- `home-manager/common/agents/base.nix` - User packages (Claude Code, Gemini CLI, browsers)
- `home-manager/drago/agent.nix` - Agent-specific overrides

### DNS Resolution (Tailscale MagicDNS)

Agent VMs require systemd-resolved for Tailscale MagicDNS to work. Without this, internal DNS names (grafana.ncrmro.com, git.ncrmro.com) won't resolve.

Configuration in `hosts/common/optional/agent-base.nix`:
```nix
networking.networkmanager.dns = "systemd-resolved";
services.resolved = {
  enable = true;
  settings.Resolve = {
    DNSSEC = "allow-downgrade";
    FallbackDNS = [ "1.1.1.1" "8.8.8.8" ];
  };
};
```

### Browser Extension Policies

Chrome/Chromium extensions are auto-installed via system policy in `agent-base.nix`:
```nix
programs.chromium = {
  enable = true;
  extraOpts = {
    ExtensionInstallForcelist = [
      "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx" # Bitwarden
      "hpbjkfadkecgpnpjnfflahhdcfboimek;https://clients2.google.com/service/update2/crx" # Claude
    ];
  };
};
```

### Remote Rebuild and Deploy

Agents auto-connect to headscale on boot. Update agents by building locally and deploying remotely via Tailscale:

```bash
# Build and deploy via Tailscale (recommended)
nix build .#nixosConfigurations.agent-drago.config.system.build.toplevel --print-out-paths
nix copy --to ssh://drago@agent-drago /nix/store/<hash>-nixos-system-agent-drago-...
ssh drago@agent-drago "sudo /nix/store/<hash>-nixos-system-agent-drago-.../bin/switch-to-configuration switch"

# Alternative: nixos-rebuild via Tailscale
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

## Headscale DNS

Internal DNS for Tailscale-only services is managed via Headscale extra records in `modules/nixos/headscale/default.nix`. These records resolve `*.ncrmro.com` subdomains to Tailscale IPs for clients on the tailnet.

**Configuration location:** `modules/nixos/headscale/default.nix` → `settings.dns.extra_records`

**Adding a new DNS record:**

1. Add an entry to the `extra_records` list:
   ```nix
   {
     name = "myservice.ncrmro.com";
     type = "A";
     value = "100.64.0.6"; # ocean's Tailscale IP
   }
   ```
2. Add an nginx virtual host in the target host's nginx config (e.g., `hosts/ocean/nginx.nix`)
3. Rebuild mercury to apply DNS: `./bin/updateMercury`
4. Rebuild the target host to apply nginx: `./bin/updateOcean`

**Key Tailscale IPs:**
- `100.64.0.6` — ocean (homelab server, most services)
- `100.64.0.38` — mercury (headscale/DERP server, AdGuard)

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

**Agent-relevant tags:**
- `tag:agent` - Applied to agent VMs (allows access to ocean services)
- `tag:ocean-ingress` - Ocean node ingress (ports 80, 443, 2222)
- `tag:ocean-email` - Ocean node email (ports 993, 465, 25)

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
- Host-specific secrets are in `/agenix-secrets/secrets/` and require appropriate age keys
- ZFS systems require `networking.hostId` to be set uniquely per host
- Secure Boot systems use TPM for automatic disk unlock

## Stalwart Mail Server

### Service Name

The NixOS service is `stalwart.service` (not `stalwart-mail.service`):
```bash
systemctl status stalwart
journalctl -u stalwart --since "10 min ago"
```

### Stalwart TOML Custom Syntax

Stalwart uses a custom TOML parser with glob/set notation. Key differences from standard TOML:

| Setting | Stalwart Syntax | Standard TOML (WRONG) |
|---------|----------------|----------------------|
| IP allowlist | `allowed-ip = { "10.0.0.0/8" }` | `allowed-ip = ["10.0.0.0/8"]` |
| Multiple values | `{ "a", "b", "c" }` | `["a", "b", "c"]` |

### Configuring `server.allowed-ip` in NixOS

The `server.allowed-ip` setting whitelists IPs from Stalwart's automatic fail2ban-style blocking. Stalwart's default syntax uses set notation `{ "ip" }` which NixOS can't generate, but there's an alternative **table syntax**:

```nix
services.stalwart-mail.settings = {
  # Table syntax - NixOS generates [server.allowed-ip] section
  server."allowed-ip" = {
    "100.64.0.0/10" = "";      # Tailscale IPv4 CGNAT range
    "fd7a:115c:a1e0::/48" = ""; # Tailscale IPv6 range
  };
};
```

This generates valid TOML that Stalwart accepts:
```toml
[server.allowed-ip]
"100.64.0.0/10" = ""
"fd7a:115c:a1e0::/48" = ""
```

**Important**: This prevents future blocking only. To clear existing blocked IPs, use the Stalwart admin UI (Settings → Allowed IP addresses) or API:
```bash
curl -X DELETE -u admin:$(sudo cat /run/agenix/stalwart-admin-password) \
  "http://localhost:8082/api/blocked?ip=100.64.0.7"
```

### Debugging IP Blocking

If Himalaya/IMAP clients get "TLS handshake EOF" errors:
1. Check Stalwart logs: `journalctl -u stalwart --since "10 min ago" | grep -i block`
2. Look for `security.ip-blocked` messages
3. Verify `server.allowed-ip` is set correctly (curly braces, singular key name)
4. Clear any existing blocks via UI or API

## Himalaya Email Client

Himalaya is configured via a shared module with per-user overrides.

### Sending Raw Emails

When using `himalaya message send` with raw email format, always include the `Date:` header:

```bash
echo "From: user@ncrmro.com
To: recipient@ncrmro.com
Subject: Test
Date: $(date -R)
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8

Body here" | himalaya message send
```

**Important**: Without `Date: $(date -R)`, emails show as 1970-01-01 (Unix epoch).

### Module Location

- Module definition: `home-manager/common/features/cli/himalaya.nix`
- Defines `programs.himalaya-stalwart` options: `accountName`, `email`, `displayName`, `login`, `passwordCommand`, `host`

### Per-User Configuration

- Drago: `home-manager/drago/himalaya.nix` - enables module with drago account settings
- ncrmro: `home-manager/ncrmro/base.nix` - enables module with ncrmro account settings

### Stalwart Folder Names

Stalwart uses different folder names than Himalaya defaults. The module configures these automatically:

| Himalaya Default | Stalwart Name   |
|------------------|-----------------|
| Sent             | Sent Items      |
| Drafts           | Drafts          |
| Trash            | Deleted Items   |

### Adding a New Himalaya User

1. Create agenix secret in `agenix-secrets/`:
   ```bash
   cd agenix-secrets
   # Add entry to secrets.nix first, then:
   agenix -e secrets/stalwart-mail-USERNAME-password.age
   git add -A && git commit -m "Add USERNAME mail password" && git push
   cd ..
   # Update flake AND stage submodule together
   nix flake update agenix-secrets
   git add agenix-secrets flake.lock
   git commit -m "chore: add USERNAME mail secret"
   ```

2. Import the himalaya module and enable it:
   ```nix
   imports = [ ../common/features/cli/himalaya.nix ];

   programs.himalaya-stalwart = {
     enable = true;
     accountName = "username";
     email = "user@ncrmro.com";
     displayName = "Display Name";
     login = "username";
     passwordCommand = "cat /run/agenix/stalwart-mail-username-password";
   };
   ```

3. Add agenix secret decryption in host config (`hosts/HOSTNAME/default.nix`):
   ```nix
   age.secrets.stalwart-mail-username-password = {
     file = ../../agenix-secrets/secrets/stalwart-mail-username-password.age;
     owner = "username";
     mode = "0400";
   };
   ```

### Agenix Secrets Update Workflow

When updating secrets (e.g., mail passwords):

1. Edit secret in submodule:
   ```bash
   cd agenix-secrets
   agenix -e secrets/secret-name.age
   git add -A && git commit -m "Update secret" && git push
   cd ..
   ```

2. **IMPORTANT**: Update flake input AND stage submodule together in ONE commit:
   ```bash
   nix flake update agenix-secrets
   git add agenix-secrets flake.lock
   git commit -m "chore: update agenix-secrets"
   ```

3. Rebuild and deploy:
   ```bash
   nix build .#nixosConfigurations.<host>.config.system.build.toplevel --print-out-paths
   # Then copy and activate on target host
   ```

**Why both together?** The flake.lock pins the Git version while `agenix-secrets/` tracks the local checkout. Both must point to the same commit for consistency.
