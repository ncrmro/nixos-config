# Raspberry Pi Cluster with Keystone Primer

This document outlines setting up a three-node Raspberry Pi cluster using Keystone's operating system module with U-Boot, ZFS root filesystem, and SSH-based remote disk unlock.

## Overview

### Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │             Headscale VPN Mesh              │
                    │         (pi-cluster.ncrmro.com)             │
                    └─────────────────────────────────────────────┘
                              │           │           │
                    ┌─────────┴───┐ ┌─────┴─────┐ ┌───┴─────────┐
                    │   pi-alpha  │ │  pi-beta  │ │  pi-gamma   │
                    │ 100.64.1.1  │ │ 100.64.1.2│ │ 100.64.1.3  │
                    │   (master)  │ │  (worker) │ │  (worker)   │
                    └─────────────┘ └───────────┘ └─────────────┘
                         │               │               │
                    ┌────┴────┐    ┌─────┴────┐   ┌──────┴────┐
                    │ USB SSD │    │ USB SSD  │   │  USB SSD  │
                    │  ZFS    │    │   ZFS    │   │   ZFS     │
                    │ LUKS    │    │  LUKS    │   │  LUKS     │
                    └─────────┘    └──────────┘   └───────────┘
```

### Components

| Component | Description |
|-----------|-------------|
| **Hardware** | 3x Raspberry Pi 4/5 (8GB recommended) |
| **Boot** | U-Boot with UEFI firmware |
| **Filesystem** | ZFS on LUKS-encrypted USB SSDs |
| **Networking** | Headscale mesh VPN (self-hosted) |
| **Remote Unlock** | SSH access in initrd for disk unlock |

### Node Naming Convention

| Hostname | Role | Headscale IP |
|----------|------|--------------|
| pi-alpha | Master (Headscale server) | 100.64.1.1 |
| pi-beta | Worker | 100.64.1.2 |
| pi-gamma | Worker | 100.64.1.3 |

## Prerequisites

### Hardware Requirements

Per Raspberry Pi node:
- Raspberry Pi 4 (4GB+) or Pi 5 (recommended)
- USB 3.0 SSD (128GB+ recommended for ZFS)
- microSD card (for initial boot/firmware only)
- Ethernet connection (for reliable initrd networking)
- Power supply (official Pi PSU recommended)

### Development Machine

- NixOS with `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` for cross-compilation
- SSH key pair for remote access
- Age key for secret encryption

## Flake Configuration

### Adding Pi Hosts to flake.nix

Add the following to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Raspberry Pi support
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # U-Boot and UEFI firmware
    raspberry-pi-nix = {
      url = "github:nix-community/raspberry-pi-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    keystone = {
      url = "github:ncrmro/keystone";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, nixos-hardware, raspberry-pi-nix, disko, keystone, agenix, ... }@inputs:
  let
    # Cross-compilation helper for aarch64
    mkPiSystem = hostname: nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        raspberry-pi-nix.nixosModules.raspberry-pi
        disko.nixosModules.disko
        agenix.nixosModules.default
        keystone.nixosModules.operating-system
        ./hosts/${hostname}
      ];
      specialArgs = { inherit inputs self; outputs = self; };
    };
  in {
    nixosConfigurations = {
      # Pi cluster nodes
      pi-alpha = mkPiSystem "pi-alpha";
      pi-beta = mkPiSystem "pi-beta";
      pi-gamma = mkPiSystem "pi-gamma";

      # Existing hosts...
    };
  };
}
```

## Host Configuration

### Directory Structure

```
hosts/
├── pi-alpha/
│   ├── default.nix
│   ├── disk-config.nix
│   ├── hardware-configuration.nix
│   └── headscale.nix          # Master runs Headscale server
├── pi-beta/
│   ├── default.nix
│   ├── disk-config.nix
│   └── hardware-configuration.nix
├── pi-gamma/
│   ├── default.nix
│   ├── disk-config.nix
│   └── hardware-configuration.nix
└── common/
    └── optional/
        └── pi-common.nix       # Shared Pi configuration
```

### Common Pi Configuration

File: `hosts/common/optional/pi-common.nix`

```nix
{ lib, pkgs, config, ... }:

{
  # Raspberry Pi specific settings
  raspberry-pi-nix = {
    board = "bcm2711";  # Pi 4, use "bcm2712" for Pi 5
    uboot.enable = true;
  };

  # Enable UEFI boot via U-Boot
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # Kernel modules for USB SSD and network
  boot.initrd.availableKernelModules = [
    "uas"           # USB Attached SCSI
    "usbhid"        # USB HID
    "usb_storage"   # USB storage
    "xhci_pci"      # USB 3.0
    "genet"         # Pi Ethernet
  ];

  # Disable GPU memory (headless)
  hardware.raspberry-pi."4".fkms-3d.enable = false;

  # Power management
  powerManagement.cpuFreqGovernor = "ondemand";

  # Serial console for debugging
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty1"
  ];
}
```

### Pi-Alpha (Master Node with Headscale)

File: `hosts/pi-alpha/default.nix`

```nix
{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./headscale.nix
    ../common/global
    ../common/optional/pi-common.nix
    ../common/optional/agenix.nix
    ../../modules/users/ncrmro.nix
  ];

  networking.hostName = "pi-alpha";
  networking.hostId = "a1b2c3d4";  # Generate: head -c 4 /dev/urandom | od -A none -t x4

  # Static IP for reliable initrd SSH
  networking.interfaces.eth0 = {
    useDHCP = false;
    ipv4.addresses = [{
      address = "192.168.1.50";
      prefixLength = 24;
    }];
  };
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Keystone OS with remote unlock
  keystone.os = {
    enable = true;
    remoteUnlock = {
      enable = true;
      port = 2222;
      dhcp = false;  # Using static IP
      networkModule = "genet";  # Pi Ethernet driver
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... ncrmro@workstation"
      ];
    };
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... ncrmro@workstation"
  ];

  system.stateVersion = "25.05";
}
```

File: `hosts/pi-alpha/headscale.nix`

```nix
{ config, pkgs, ... }:

{
  # Headscale VPN coordinator for Pi cluster
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 8080;
    settings = {
      server_url = "https://pi-cluster.ncrmro.com";
      dns = {
        base_domain = "pi";
        magic_dns = true;
        nameservers.global = [ "1.1.1.1" "8.8.8.8" ];
      };
      derp = {
        server = {
          enabled = true;
          region_id = 900;
          region_code = "pi-cluster";
          stun_listen_addr = "0.0.0.0:3478";
        };
      };
      prefixes = {
        v4 = "100.64.1.0/24";  # Pi cluster subnet
        v6 = "fd7a:115c:a1e0:ab12:4843:cd96:6200::/112";
      };
    };
  };

  # Open firewall for Headscale
  networking.firewall.allowedTCPPorts = [ 80 443 8080 ];
  networking.firewall.allowedUDPPorts = [ 3478 ];

  # Nginx reverse proxy for Headscale
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."pi-cluster.ncrmro.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "your-email@example.com";
  };
}
```

### Disk Configuration with ZFS and LUKS

File: `hosts/pi-alpha/disk-config.nix`

```nix
{ lib, config, ... }:

{
  disko.devices = {
    disk = {
      # Boot SD card (firmware only)
      sdcard = {
        type = "disk";
        device = "/dev/disk/by-id/mmc-SD_CARD_ID";  # Replace with actual ID
        content = {
          type = "gpt";
          partitions = {
            firmware = {
              name = "FIRMWARE";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/firmware";
              };
            };
          };
        };
      };

      # USB SSD for root filesystem
      usb-ssd = {
        type = "disk";
        device = "/dev/disk/by-id/usb-Samsung_T7_SERIAL";  # Replace with actual ID
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "BOOT";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
        };
        options.ashift = "12";

        datasets = {
          # LUKS-encrypted credstore for ZFS keys
          credstore = {
            type = "zfs_volume";
            size = "100M";
            content = {
              type = "luks";
              name = "credstore";
              content = {
                type = "filesystem";
                format = "ext4";
              };
            };
          };

          # Encrypted root dataset
          crypt = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              encryption = "aes-256-gcm";
              keyformat = "raw";
              keylocation = "file:///etc/credstore/zfs-sysroot.mount";
            };
            preCreateHook = ''
              mount -o X-mount.mkdir /dev/mapper/credstore /etc/credstore
              head -c 32 /dev/urandom > /etc/credstore/zfs-sysroot.mount
            '';
            postCreateHook = ''
              umount /etc/credstore
              cryptsetup luksClose /dev/mapper/credstore
            '';
          };

          "crypt/system" = {
            type = "zfs_fs";
            mountpoint = "/";
          };

          "crypt/system/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false";
          };

          "crypt/system/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
          };

          "crypt/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
        };
      };
    };
  };
}
```

### Hardware Configuration

File: `hosts/pi-alpha/hardware-configuration.nix`

```nix
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Pi 4 specifics
  hardware.enableRedistributableFirmware = true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "uas"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
```

## ZFS Boot Integration

### SystemD Initrd for Remote Unlock

File: `hosts/common/optional/zfs.luks.root.pi.nix`

This extends the standard ZFS LUKS root configuration for Pi-specific needs:

```nix
{ lib, config, pkgs, ... }:

{
  # ZFS services
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  # SystemD initrd for complex boot orchestration
  boot.initrd.systemd.enable = true;

  # Import pool and unlock credstore
  boot.initrd.systemd.services.import-rpool-bare = {
    description = "Import rpool without mounting";
    after = [ "modprobe@zfs.service" "systemd-udev-settle.service" ];
    before = [ "cryptsetup-pre.target" ];
    wantedBy = [ "cryptsetup-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for USB SSD
      for i in $(seq 1 30); do
        if [ -e /dev/disk/by-id/usb-Samsung_T7_* ]; then
          break
        fi
        sleep 1
      done

      # Import pool without mounting
      zpool import -N -d /dev/disk/by-id rpool || true
    '';
  };

  # LUKS credstore unlock
  boot.initrd.luks.devices.credstore = {
    device = "/dev/zvol/rpool/credstore";
    preLVM = false;
  };

  # Load ZFS encryption key from credstore
  boot.initrd.systemd.services.rpool-load-key = {
    description = "Load ZFS encryption key";
    after = [ "import-rpool-bare.service" "systemd-cryptsetup@credstore.service" ];
    before = [ "zfs-import-rpool.service" ];
    wantedBy = [ "zfs-import-rpool.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mount /dev/mapper/credstore /etc/credstore
      zfs load-key -L file:///etc/credstore/zfs-sysroot.mount rpool/crypt
      umount /etc/credstore
    '';
  };
}
```

### Initrd SSH for Remote Unlock

The Keystone `remoteUnlock` module provides SSH access during boot for entering the LUKS passphrase remotely:

```nix
# In hosts/pi-alpha/default.nix
keystone.os = {
  enable = true;
  remoteUnlock = {
    enable = true;
    port = 2222;               # SSH port in initrd
    dhcp = false;              # Use static IP
    networkModule = "genet";   # Raspberry Pi Ethernet driver
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... ncrmro@workstation"
    ];
  };
};

# Static IP for reliable boot
boot.kernelParams = [
  "ip=192.168.1.50::192.168.1.1:255.255.255.0:pi-alpha:eth0:off"
];
```

## Secrets Configuration

### Adding Pi Nodes to secrets.nix

```nix
let
  users = {
    ncrmro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...";
  };

  systems = {
    # Existing hosts
    ocean = "ssh-ed25519 ...";
    maia = "ssh-ed25519 ...";

    # Pi cluster nodes
    pi-alpha = "ssh-ed25519 ...";  # Get after first boot
    pi-beta = "ssh-ed25519 ...";
    pi-gamma = "ssh-ed25519 ...";
  };

  adminKeys = [ users.ncrmro ];
  piCluster = [ systems.pi-alpha systems.pi-beta systems.pi-gamma ];
in {
  # Headscale auth key for Pi cluster
  "secrets/pi-headscale-authkey.age".publicKeys = adminKeys ++ piCluster;

  # Per-node LUKS passphrases (optional, for automated unlock)
  "secrets/pi-alpha-luks.age".publicKeys = adminKeys ++ [ systems.pi-alpha ];
  "secrets/pi-beta-luks.age".publicKeys = adminKeys ++ [ systems.pi-beta ];
  "secrets/pi-gamma-luks.age".publicKeys = adminKeys ++ [ systems.pi-gamma ];
}
```

## Burning Disks

### Step 1: Prepare the SD Card (Firmware Only)

The SD card contains U-Boot and UEFI firmware. The actual OS lives on the USB SSD.

```bash
# Download Raspberry Pi UEFI firmware
wget https://github.com/pftf/RPi4/releases/download/v1.36/RPi4_UEFI_Firmware_v1.36.zip
unzip RPi4_UEFI_Firmware_v1.36.zip -d firmware/

# Format SD card and copy firmware
sudo mkfs.vfat -F32 /dev/sdX1
sudo mount /dev/sdX1 /mnt
sudo cp -r firmware/* /mnt/
sudo umount /mnt
```

### Step 2: Build Installation Image

Build an aarch64 installation image with ZFS support:

```bash
# Build custom installer ISO
nix build .#nixosConfigurations.pi-installer.config.system.build.sdImage

# Or use existing NixOS aarch64 installer
wget https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-aarch64-linux.iso
```

### Step 3: Flash USB SSD with nixos-anywhere

```bash
# Boot Pi from SD card + USB installer
# Connect via SSH to the installer environment

# From your workstation, deploy with nixos-anywhere
nix run github:nix-community/nixos-anywhere -- \
  --flake .#pi-alpha \
  --target-host root@192.168.1.50 \
  --build-on-remote

# During installation, you'll be prompted to set the LUKS passphrase
```

### Step 4: Generate and Store Initrd SSH Host Key

After first boot, generate the initrd SSH host key:

```bash
# SSH into the Pi
ssh root@192.168.1.50

# Generate initrd SSH key
ssh-keygen -t ed25519 -N '' -f /etc/ssh/initrd_ssh_host_ed25519_key

# Get the system SSH public key for secrets.nix
cat /etc/ssh/ssh_host_ed25519_key.pub
```

### Step 5: Enroll TPM for Automatic Unlock (Optional)

If your Pi has a TPM module attached:

```bash
# Enroll LUKS key in TPM
systemd-cryptenroll --tpm2-device=auto /dev/zvol/rpool/credstore

# Update LUKS configuration
boot.initrd.luks.devices.credstore = {
  device = "/dev/zvol/rpool/credstore";
  crypttabExtraOpts = [
    "tpm2-device=auto"
    "tpm2-measure-pcr=yes"
  ];
};
```

## Remote Unlock Procedure

When a Pi node reboots, it will wait at the initrd for disk unlock:

```bash
# Connect to initrd SSH (different port and host key!)
ssh -p 2222 -o "UserKnownHostsFile=~/.ssh/known_hosts_initrd" root@192.168.1.50

# Inside initrd, use systemd password agent
systemd-tty-ask-password-agent

# Enter LUKS passphrase when prompted
# System will continue booting after unlock
```

### Unlock Script

Create a convenience script `bin/unlock-pi`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PI_HOST="${1:-pi-alpha}"
PI_IP="${2:-192.168.1.50}"
INITRD_PORT=2222

echo "Unlocking ${PI_HOST} at ${PI_IP}..."

# Use separate known_hosts for initrd
ssh -p ${INITRD_PORT} \
    -o "UserKnownHostsFile=~/.ssh/known_hosts_pi_initrd" \
    -o "StrictHostKeyChecking=accept-new" \
    root@${PI_IP} \
    "systemd-tty-ask-password-agent --query"
```

## Deployment

### Initial Deployment

```bash
# 1. Prepare SD cards with UEFI firmware for all Pis
./bin/prepare-pi-sdcard /dev/sdX

# 2. Boot each Pi and get installer IP

# 3. Deploy pi-alpha first (runs Headscale)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#pi-alpha \
  --target-host root@192.168.1.50

# 4. Create Headscale auth key on pi-alpha
ssh root@pi-alpha.local "headscale preauthkeys create --user pi-cluster --expiration 1h"

# 5. Deploy worker nodes
nix run github:nix-community/nixos-anywhere -- \
  --flake .#pi-beta \
  --target-host root@192.168.1.51

nix run github:nix-community/nixos-anywhere -- \
  --flake .#pi-gamma \
  --target-host root@192.168.1.52
```

### Update Scripts

File: `bin/updatePiCluster`

```bash
#!/usr/bin/env bash
set -euo pipefail

NODES=("pi-alpha:192.168.1.50" "pi-beta:192.168.1.51" "pi-gamma:192.168.1.52")

for node in "${NODES[@]}"; do
  HOST="${node%%:*}"
  IP="${node##*:}"

  echo "=== Updating ${HOST} ==="
  nixos-rebuild switch \
    --flake .#${HOST} \
    --target-host root@${IP} \
    --build-host root@${IP}
done

echo "=== All nodes updated ==="
```

## Headscale VPN Setup

### Registering Nodes

After initial deployment, register each node with Headscale:

```bash
# On pi-alpha (Headscale server)
headscale users create pi-cluster

# Generate auth keys for each node
headscale preauthkeys create --user pi-cluster --expiration 24h --reusable

# On each worker node, join the mesh
tailscale up \
  --login-server https://pi-cluster.ncrmro.com \
  --authkey <AUTH_KEY>
```

### DNS Configuration

Configure Headscale DNS for cluster-internal resolution:

```nix
# In pi-alpha/headscale.nix
services.headscale.settings.dns = {
  base_domain = "pi";
  magic_dns = true;
  extra_records = [
    { name = "pi-alpha.pi"; type = "A"; value = "100.64.1.1"; }
    { name = "pi-beta.pi"; type = "A"; value = "100.64.1.2"; }
    { name = "pi-gamma.pi"; type = "A"; value = "100.64.1.3"; }
  ];
};
```

## Troubleshooting

### Boot Issues

```bash
# Connect via serial console (USB-to-TTL adapter)
screen /dev/ttyUSB0 115200

# Check U-Boot logs
# In U-Boot console:
printenv
boot
```

### ZFS Pool Import Issues

```bash
# Boot from installer USB, then:
zpool import -f rpool
zpool status

# If pool won't import:
zpool import -fFX rpool
```

### Initrd Network Issues

```bash
# Check if network is up in initrd
ip addr show

# If using DHCP:
dhclient eth0

# Verify SSH is running
systemctl status sshd
```

### Disk ID Discovery

```bash
# List all disk IDs
ls -la /dev/disk/by-id/

# For USB drives, look for:
# usb-Samsung_T7_SERIAL -> ../../sda

# For SD cards:
# mmc-SD_CARD_SERIAL -> ../../mmcblk0
```

## See Also

- [INSTALL_FROM_SCRATCH.md](./INSTALL_FROM_SCRATCH.md) - General NixOS installation guide
- [HEADSCALE_SETUP.md](./HEADSCALE_SETUP.md) - Headscale VPN configuration
- [ZFS_REMOTE_REPLICATION.md](./ZFS_REMOTE_REPLICATION.md) - ZFS backup strategies
- [ROOT_DISK_TPM_SECURE_BOOT_UNLOCK.md](./ROOT_DISK_TPM_SECURE_BOOT_UNLOCK.md) - TPM-based unlock
- [AGENIX_SECRET_MANAGEMENT.md](./AGENIX_SECRET_MANAGEMENT.md) - Secret management

## Resources

- [NixOS on Raspberry Pi](https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi)
- [raspberry-pi-nix](https://github.com/nix-community/raspberry-pi-nix)
- [Raspberry Pi UEFI Firmware](https://github.com/pftf/RPi4)
- [Headscale Documentation](https://headscale.net/)
- [ZFS on NixOS](https://nixos.wiki/wiki/ZFS)
