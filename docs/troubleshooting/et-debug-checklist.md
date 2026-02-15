# Eternal Terminal Debugging Checklist

## Issue Description
Double letters, wrong line positioning, typing errors when connected to ocean via ET.

## Step 1: Check ET Version (CRITICAL)

GitHub Issue #120 showed that ET versions before 5.0.7 had keepalive timeout bugs causing latency and input issues.

```bash
# On your client machine
et --version

# Check what version NixOS is using
nix-shell -p eternalterminal --run "et --version"
```

**Expected**: Version 6.0.0+ (NixOS 25.05 should have recent version)
**Action**: If version is old, update nixpkgs or override package version

## Step 2: Test Without Multiplexer

Zellij/tmux can cause terminal rendering issues due to TERM variable handling.

```bash
# Connect with ET, DON'T launch zellij
et ncrmro@ocean

# Check TERM in plain session
echo $TERM

# Try typing - does issue persist?
```

**If issue goes away**: Problem is zellij/tmux interaction with ET
**If issue persists**: Problem is ET or network layer

## Step 3: Compare with Regular SSH

```bash
# SSH session
ssh ncrmro@ocean
echo $TERM
# Try typing - any issues?

# ET session (side by side)
et ncrmro@ocean
echo $TERM
# Try typing - any issues?
```

**If SSH is fine but ET has issues**: ET-specific problem
**If both have issues**: Server-side configuration or network problem

## Step 4: Check Network Quality

ET is designed for unreliable networks but can have issues with packet loss.

```bash
# From client to ocean (via tailscale)
ping -c 100 ocean
# Look for packet loss percentage

# Check latency stability
mtr ocean --report --report-cycles 30
```

**Expected**: <1% packet loss, stable latency
**If high packet loss**: Network issue causing ET problems

## Step 5: Monitor ET Connection

```bash
# Connect with verbose logging
et -v ncrmro@ocean

# Watch for errors like:
# - "Got EAGAIN, waiting 100ms"
# - "Missed a keepalive"
# - "Invalid size"
# - "Broken pipe"
```

**These errors indicate**: Version-specific bugs (upgrade needed)

## Step 6: Test TERM Variable Override

```bash
# Try connecting with explicit TERM
TERM=xterm-256color et ncrmro@ocean

# Or try simpler TERM
TERM=xterm et ncrmro@ocean

# Or screen-256color (what tmux/zellij use)
TERM=screen-256color et ncrmro@ocean
```

**If specific TERM fixes it**: TERM mismatch issue

## Step 7: Check Stty Settings

While flow control shouldn't affect PTYs, check anyway:

```bash
# In ET session
stty -a | grep -E "ixon|ixoff"

# Disable flow control
stty -ixon

# Test typing again
```

**If this helps**: Add to shell RC as workaround

## Step 8: Test Without Tailscale

If ocean is accessible via LAN:

```bash
# Direct connection (not through tailscale)
et ncrmro@192.168.1.10

# Does issue persist?
```

**If issue goes away**: Tailscale interaction problem
**If issue persists**: Not network-related

## Step 9: Check Server-Side Logs

```bash
# On ocean, check systemd logs
sudo journalctl -u eternal-terminal -f

# Connect from client, watch for errors
```

Look for:
- Connection errors
- Keepalive failures
- Socket errors

## Quick Test Matrix

| Test | Command | Expected Result |
|------|---------|----------------|
| ET version | `et --version` | 6.0.0+ |
| SSH works fine | `ssh ncrmro@ocean` | No typing issues |
| ET without zellij | `et ncrmro@ocean` (don't start zellij) | Identify if multiplexer-related |
| ET verbose | `et -v ncrmro@ocean` | Check for EAGAIN/keepalive errors |
| Network quality | `ping -c 100 ocean` | <1% packet loss |
| TERM override | `TERM=xterm et ncrmro@ocean` | May fix rendering |

## Common Root Causes

1. **Old ET version** → Upgrade to 6.0.0+
2. **Zellij TERM handling** → Use SSH + zellij instead of ET
3. **Network packet loss** → Fix tailscale/network
4. **TERM mismatch** → Set consistent TERM value
5. **Keepalive timeouts** → Update ET version

## Recommended Solutions (Priority Order)

### If ET version < 6.0.0
Update ET package in nixos-config

### If issue only happens with zellij
Use SSH instead of ET when using zellij:
```bash
ssh ncrmro@ocean -t zellij attach -c ocean
```

### If network quality is poor
Check tailscale connection:
```bash
tailscale status
tailscale ping ocean
```

### If TERM mismatch
Add to ocean's home-manager zsh config:
```nix
programs.zsh.sessionVariables = {
  TERM = "xterm-256color";
};
```

## Next Steps

After running through this checklist, report findings:
1. What step identified the issue?
2. Which workaround/fix resolved it?
3. Should we file an upstream bug?

## Sources

- [ET Issue #120: Occasional increased lag/latency](https://github.com/MisterTea/EternalTerminal/issues/120)
- [Zellij Issue #4049: TERM rendering issues](https://github.com/zellij-org/zellij/issues/4049)
- [Eternal Terminal GitHub](https://github.com/MisterTea/EternalTerminal)
- [ET User Manual](https://eternalterminal.dev/usermanual/)
