# MicroVM Configuration Guide

This document covers setting up NixOS MicroVMs with graphical display access over SPICE, particularly for remote access via Tailscale.

## Overview

The `agent-drago` VM runs on the `ocean` host using the microvm.nix framework with QEMU as the hypervisor. It provides a graphical GNOME desktop accessible remotely via SPICE protocol.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ ocean (host)                                            │
│  ├── microvm@agent-drago.service                        │
│  │    └── QEMU with virtio-gpu-gl + egl-headless        │
│  │         └── SPICE server on 100.64.0.6:5900          │
│  └── /dev/dri/renderD128 (GPU render node)              │
└─────────────────────────────────────────────────────────┘
         │
         │ Tailscale (100.64.0.6)
         ▼
┌─────────────────────────────────────────────────────────┐
│ Client                                                  │
│  └── remote-viewer spice://ocean:5900                   │
└─────────────────────────────────────────────────────────┘
```

## Key Configuration

### Host Configuration (ocean)

The host imports the microvm host module and defines the VM:

```nix
# hosts/ocean/default.nix
imports = [
  inputs.microvm.nixosModules.host
];

microvm.vms."agent-drago" = {
  flake = outputs;
  restartIfChanged = true;
};

# Open SPICE port on firewall
networking.firewall.allowedTCPPorts = [ 5900 ];
```

### Guest Configuration (agent-drago)

```nix
# hosts/agent-drago/default.nix
microvm = {
  hypervisor = "qemu";

  # CRITICAL: Disable optimization to preserve full QEMU features
  # The optimize.enable option applies nixosTestRunner which strips SPICE/virgl
  optimize.enable = false;

  # Use full QEMU with virgl/OpenGL support
  qemu.package = pkgs.qemu_full;

  qemu.extraArgs = [
    # GPU Device (virtio-gpu with GL acceleration)
    "-device" "virtio-gpu-gl-pci"
    # Render server (headless EGL on host GPU)
    "-display" "egl-headless,rendernode=/dev/dri/renderD128"
    # SPICE output with GL enabled (bind to Tailscale IP only)
    "-spice" "port=5900,addr=100.64.0.6,disable-ticketing=on,gl=on"
    # SPICE tools for clipboard/mouse
    "-device" "virtio-serial-pci"
    # Networking
    "-netdev" "user,id=net0,hostfwd=tcp::2223-:22"
    "-device" "virtio-net-pci,netdev=net0"
  ];
};

# Guest-side SPICE integration
services.spice-vdagentd.enable = true;
services.qemuGuest.enable = true;

# Display manager with auto-login
services.xserver.enable = true;
services.xserver.desktopManager.gnome.enable = true;
services.displayManager.autoLogin.enable = true;
services.displayManager.autoLogin.user = "drago";
```

## QEMU Package Selection

MicroVM applies transformations to the QEMU package that can strip features:

| Package | Description | SPICE | Virgl |
|---------|-------------|-------|-------|
| `pkgs.qemu_kvm` | Alias for `qemu-host-cpu-only` (minimal) | No | No |
| `pkgs.qemu` | Standard QEMU | Yes | Depends |
| `pkgs.qemu_full` | Full QEMU with all features | Yes | Yes |

**Important**: Even with `qemu_full`, if `microvm.optimize.enable = true` (default), microvm applies `nixosTestRunner = true` which creates a minimal test build that strips SPICE and virgl support.

**Solution**: Always set `optimize.enable = false` when using SPICE/virgl.

## Display Options

### Option 1: QXL + SPICE (2D, recommended for remote)

Best for network connections - sends 2D draw commands rather than streaming rendered bitmaps:

```nix
qemu.extraArgs = [
  "-vga" "qxl"
  "-device" "virtio-serial-pci"
  "-spice" "port=5900,addr=100.64.0.6,disable-ticketing=on"
  "-display" "none"
];
```

### Option 2: virtio-gpu-gl + egl-headless (3D accelerated)

For 3D acceleration with headless host rendering:

```nix
qemu.extraArgs = [
  "-device" "virtio-gpu-gl-pci"
  "-display" "egl-headless,rendernode=/dev/dri/renderD128"
  "-spice" "port=5900,addr=100.64.0.6,disable-ticketing=on,gl=on"
  "-device" "virtio-serial-pci"
];
```

**Prerequisites**:
- Host must have `/dev/dri/renderD128` (GPU with render node)
- `qemu.package = pkgs.qemu_full`
- `optimize.enable = false`

### Option 3: VNC (fallback)

If SPICE doesn't work, VNC is simpler:

```nix
qemu.extraArgs = [
  "-vga" "std"
  "-vnc" "0.0.0.0:0"  # Port 5900
  "-display" "none"
];
```

Connect with: `remote-viewer vnc://ocean:5900`

## Connecting

```bash
# Using remote-viewer (recommended)
remote-viewer spice://ocean:5900

# Or with explicit Tailscale IP
remote-viewer spice://100.64.0.6:5900

# For VNC
remote-viewer vnc://ocean:5900
```

## Troubleshooting

### Check VM Status

```bash
ssh ocean "systemctl status microvm@agent-drago.service"
ssh ocean "journalctl -u microvm@agent-drago.service -n 50"
```

### Check SPICE Port

```bash
ssh ocean "ss -tlnp | grep 5900"
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `-spice: invalid option` | QEMU built without SPICE | Use `qemu_full` + `optimize.enable = false` |
| `QXL VGA not available` | QEMU built without QXL | Use `qemu_full` + `optimize.enable = false` |
| `virtio-gpu-pci.virgl not found` | Old virgl syntax | Use `virtio-gpu-gl-pci` device instead |
| `Connection refused` | VM not running or wrong port | Check VM status and firewall |

### Verify QEMU Features

```bash
# Check what QEMU package is being used
nix path-info '.#nixosConfigurations.agent-drago.config.microvm.qemu.package'

# Check available devices
ssh ocean "/nix/store/<qemu-path>/bin/qemu-system-x86_64 -device help | grep -i gpu"
```

## Remaining Tasks

- [ ] Test virtio-gpu-gl-pci + egl-headless configuration
- [ ] Verify clipboard sharing works with spice-vdagentd
- [ ] Consider increasing VM memory (512MB is minimal for GNOME)
- [ ] Add SPICE password authentication if needed:
  ```nix
  "-spice" "port=5900,addr=100.64.0.6,password=secret"
  ```
- [ ] Test display resize/resolution changes
- [ ] Document USB passthrough if needed

## References

- [microvm.nix Documentation](https://microvm-nix.github.io/microvm.nix/)
- [microvm.nix Options Reference](https://microvm-nix.github.io/microvm.nix/microvm-options.html)
- [QEMU SPICE Documentation](https://www.spice-space.org/)
- [NixOS SPICE VDAgent](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/spice-vdagentd.nix)
