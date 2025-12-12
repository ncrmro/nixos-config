# Claude Code Connection Timeout with Headscale/Tailscale Enabled

## Problem

Claude Code times out on all requests when Tailscale is connected to a self-hosted Headscale server. The CLI hangs and retries repeatedly.

## Root Cause

IPv6 connectivity is broken through the Tailscale tunnel, but DNS still returns AAAA (IPv6) records. Claude Code (Node.js) tries IPv6 first by default, waits for timeout, then fails.

### Diagnosis Steps

1. **Check DNS resolution** - Both A and AAAA records resolve quickly:
   ```bash
   dig api.anthropic.com @100.100.100.100      # Works, ~8ms
   dig AAAA api.anthropic.com @100.100.100.100 # Works, ~7ms
   ```

2. **Test IPv6 vs IPv4 connectivity** (with Tailscale up):
   ```bash
   curl -6 -sI --connect-timeout 5 https://api.anthropic.com  # Times out/empty
   curl -4 -sI --connect-timeout 5 https://api.anthropic.com  # Works (HTTP 404)
   ```

3. If IPv6 times out but IPv4 works, this confirms the issue.

## Solutions

### Option 1: Disable IPv6 AAAA Responses in AdGuard Home (Recommended)

If using AdGuard Home as your Headscale DNS server:

1. Go to AdGuard Home web UI (e.g., `adguard.ncrmro.com`)
2. Navigate to Settings → DNS settings
3. Enable "Disable resolving of IPv6 addresses"

This returns empty AAAA responses, forcing all apps to use IPv4 without disabling IPv6 system-wide.

### Option 2: Disable IPv6 on Workstation

Add to your NixOS host configuration:

```nix
networking.enableIPv6 = false;
```

### Option 3: Temporary Fix for Testing

```bash
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
```

## Related Configuration

- Headscale config: `modules/nixos/headscale/default.nix`
- AdGuard Home config: `hosts/mercury/adguard-home.nix`
- Tailscale node config: `hosts/common/optional/tailscale.node.nix`

## Environment

- Self-hosted Headscale at `mercury.ncrmro.com`
- DNS via AdGuard Home at `100.64.0.38`
- MagicDNS enabled with `override_local_dns = true`
