---
repo: ncrmro/keystone
branch: main
agent: gemini
priority: 1
status: assigned
created: 2026-03-04
---

# Replace Harmonia with atticd (Attic Binary Cache)

## Description

Replace the read-only Harmonia binary cache with atticd (Attic) to enable push support from all hosts. Currently only ocean serves the cache; other hosts (laptop, workstation) cannot push their builds. With atticd, all hosts can both pull and push via `attic watch-store`.

This task spans two repos:
- **keystone** (`.repos/ncrmro/keystone/`) — NixOS modules
- **nixos-config** (`.repos/ncrmro/nixos-config/`) — host configurations

**IMPORTANT**: Work directly on `main` branch in both repos. Do NOT create worktrees or feature branches.

Tech stack: NixOS modules (Nix language), flakes, agenix secrets, systemd services.

Read `AGENTS.md` / `CLAUDE.md` in both repos for conventions.

## What Changes

### Keystone (`.repos/ncrmro/keystone/`)

**1. New: `modules/server/services/attic.nix`**
- Follow the `mkServiceOptions` pattern from `modules/server/lib.nix`
- Options: `keystone.server.services.attic` with subdomain `cache`, port `8199`, access `tailscale`, maxBodySize `4G`
- Extend with additional options: `environmentFile` (path to env file with `ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64`), `publicKey` (nullable, for nix substituter verification)
- Enable `services.atticd` with local storage backend (SQLite default is fine)
- Configure listen address to `127.0.0.1:<port>` (nginx fronts it)
- Add garbage-collection settings (interval: 12 hours, retention: 6 months)
- Register in `_enabledServices` for auto nginx + DNS
- When publicKey is set and keystone.domain is set, server self-configures as substituter client

**2. Update: `modules/binary-cache-client.nix`**
- Add `keystone.binaryCache.push` options:
  - `push.enable` — mkEnableOption for push support
  - `push.cacheName` — string, default "main"
  - `push.tokenFile` — nullable path to auth token file
- When push enabled: create systemd service `attic-watch-store` that:
  - Uses `LoadCredential` to securely pass the token
  - Runs `attic login` then `exec attic watch-store cache:<cacheName>`
  - Uses `DynamicUser = true`, `StateDirectory = "attic-watch-store"`
  - Sets `XDG_CONFIG_HOME` to state directory
- Make `publicKey` option nullable (type: `types.nullOr types.str`, default: null) for phased rollout
- Only add to `trusted-public-keys` when publicKey is non-null
- Add `pkgs.attic-client` to system packages when push is enabled
- Update comments from "Harmonia" to "Attic"

**3. Delete: `modules/server/services/harmonia.nix`**

**4. Delete: `modules/server/binary-cache.nix`**

**5. Update: `modules/server/default.nix`**
- Remove import of `./binary-cache.nix`
- Remove import of `./services/harmonia.nix`
- Add import of `./services/attic.nix`
- Update port allocation registry comment: replace `5000 | harmonia` with `8199 | attic | Binary cache`
- Remove the `binaryCache` legacy option from `options.keystone.server`

**6. Update: `flake.nix`**
- Update comment for `binaryCacheClient` module: "Attic" instead of "Harmonia"

### nixos-config (`.repos/ncrmro/nixos-config/`)

**7. Update: `hosts/ocean/default.nix`**
- Remove the `keystone.server.binaryCache = { ... }` block
- Remove the `age.secrets.harmonia-signing-key` block
- Add `keystone.server.services.attic` config:
  ```nix
  keystone.server.services.attic = {
    enable = true;
    environmentFile = config.age.secrets.attic-server-token-key.path;
    # publicKey = null; -- set after creating the cache with atticd-atticadm
  };
  ```
- Add agenix secret for attic server JWT key:
  ```nix
  age.secrets.attic-server-token-key = {
    file = "${inputs.agenix-secrets}/secrets/attic-server-token-key.age";
    # Root-owned because atticd uses DynamicUser
  };
  ```

**8. Update: `hosts/ocean/nginx.nix`**
- Remove the `services.nginx.virtualHosts."harmonia.ncrmro.com"` block (attic is auto-proxied via the service module)

**9. Update: `hosts/common/global/default.nix`**
- Change URL from `https://harmonia.ncrmro.com` to `https://cache.ncrmro.com`
- Make publicKey null (or keep existing key temporarily) with a TODO comment
- Update comment from "Harmonia" to "Attic"

**10. Update: `hosts/workstation/default.nix`**
- Add push configuration:
  ```nix
  keystone.binaryCache.push = {
    enable = true;
    tokenFile = config.age.secrets.attic-push-token.path;
  };
  ```
- Add agenix secret:
  ```nix
  age.secrets.attic-push-token = {
    file = "${inputs.agenix-secrets}/secrets/attic-push-token.age";
  };
  ```

**11. Update: `hosts/ncrmro-laptop/default.nix`**
- Same push config as workstation

**12. Update: `agenix-secrets/secrets.nix`**
- Add `attic-server-token-key.age` with publicKeys: adminKeys ++ [systems.ocean]
- Add `attic-push-token.age` with publicKeys: adminKeys ++ desktops ++ [systems.ocean]
- Keep `harmonia-signing-key.age` for now (can remove after verifying attic works)

## Reference: Keystone Service Module Pattern

```nix
{ lib, config, ... }:
let
  serverLib = import ../lib.nix { inherit lib; };
  serverCfg = config.keystone.server;
  cfg = serverCfg.services.<name>;
in {
  options.keystone.server.services.<name> = serverLib.mkServiceOptions {
    description = "Service description";
    subdomain = "myservice";
    port = 8080;
    access = "tailscale";
  };

  config = lib.mkIf (serverCfg.enable && cfg.enable) {
    keystone.server._enabledServices.<name> = {
      inherit (cfg) subdomain port access maxBodySize websockets registerDNS;
    };
  };
}
```

## Reference: Port Allocation

Harmonia uses port 5000. Attic should use port 8199.

## Acceptance Criteria

- [ ] `modules/server/services/attic.nix` exists in keystone, follows mkServiceOptions pattern with extended options
- [ ] `services.atticd` is configured when the service is enabled (listen on localhost, local storage, GC settings)
- [ ] `modules/binary-cache-client.nix` has push options and systemd `attic-watch-store` service
- [ ] `modules/server/services/harmonia.nix` is deleted
- [ ] `modules/server/binary-cache.nix` is deleted
- [ ] `modules/server/default.nix` imports attic, no longer imports harmonia/binary-cache
- [ ] `binaryCache` legacy option removed from server default.nix
- [ ] Ocean host enables attic service with environmentFile
- [ ] Harmonia nginx vhost removed from `hosts/ocean/nginx.nix`
- [ ] Global client config points to `https://cache.ncrmro.com`
- [ ] Workstation and laptop have push config enabled
- [ ] `agenix-secrets/secrets.nix` has attic-server-token-key and attic-push-token entries
- [ ] `nix flake check` passes in keystone repo
- [ ] `nixos-rebuild build --flake .#ocean` succeeds in nixos-config
- [ ] `nixos-rebuild build --flake .#ncrmro-workstation` succeeds in nixos-config
- [ ] `nixos-rebuild build --flake .#ncrmro-laptop` succeeds in nixos-config
