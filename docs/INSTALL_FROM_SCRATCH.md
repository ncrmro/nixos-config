# Installing NixOS from Scratch with nixos-anywhere

**This guide is for installing NixOS on a remote machine when you DON'T have Nix installed on your local system.** We'll use the NixOS live ISO on the target machine to bootstrap the configuration, copy it back to your local machine, then run nixos-anywhere to perform the installation.

## Overview

The workflow:
1. Boot target machine with NixOS live ISO (which has Nix)
2. On the target, create a basic flake configuration
3. Generate hardware config on the target
4. Determine disk IDs and create disko config on the target
5. Commit everything to git on the target
6. Copy the entire repo back to your local machine
7. Run nixos-anywhere from your local machine to install NixOS on the target

**Your local machine does NOT need Nix installed** - nixos-anywhere will run in a container or use the Nix from the live ISO.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Step 1: Prepare the Target Machine](#step-1-prepare-the-target-machine)
- [Step 2: Bootstrap Configuration on Target](#step-2-bootstrap-configuration-on-target)
- [Step 3: Create Disko Disk Configuration](#step-3-create-disko-disk-configuration)
- [Step 4: Create Host Configuration](#step-4-create-host-configuration)
- [Step 5: Commit and Copy to Local Machine](#step-5-commit-and-copy-to-local-machine)
- [Step 6: Install with nixos-anywhere](#step-6-install-with-nixos-anywhere)
- [Step 7: Post-Installation](#step-7-post-installation)

## Prerequisites

### On Your Local Machine
- **SSH client** (ssh command)
- **SSH key pair** generated (`ssh-keygen -t ed25519` if you don't have one)
- **Git** (optional, for managing the repo after copying)
- **NO Nix required!**

### For the Target Machine
- **NixOS minimal ISO** downloaded and bootable USB created
- **Network connectivity** for the target machine
- **Physical or remote access** to boot from USB

## Step 1: Prepare the Target Machine

### Download NixOS Minimal ISO

On any machine with internet access:

```bash
# Download the latest minimal ISO
# Visit https://nixos.org/download.html or use:
curl -L https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-x86_64-linux.iso -o nixos-minimal.iso
```

### Create Bootable USB

On Linux or macOS:
```bash
# Find your USB device (be careful!)
lsblk  # or 'diskutil list' on macOS

# Write ISO to USB (replace /dev/sdX with your USB device)
sudo dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progress
sync
```

On Windows, use [Rufus](https://rufus.ie/) or [balenaEtcher](https://www.balena.io/etcher/).

### Boot Target Machine from USB

1. Insert the USB drive into the target machine
2. Boot from USB (usually F12, F2, or DEL during startup to access boot menu)
3. Select "NixOS Installer" from the boot menu
4. Wait for the system to boot to a root prompt

### Configure Network on Target

Once booted into the NixOS live environment:

```bash
# If using WiFi, connect first
wpa_passphrase "YOUR-SSID" "YOUR-PASSWORD" > /etc/wpa_supplicant.conf
systemctl start wpa_supplicant

# For ethernet, network should auto-configure via DHCP
# Check network connectivity
ping -c 3 nixos.org

# Find IP address
ip addr show
# Note the IP address (e.g., 192.168.1.100)

# Set a root password for SSH access
passwd
# Enter a temporary password

# Enable and start SSH
systemctl start sshd
```

### Connect from Your Local Machine

From your local machine:

```bash
# Copy your SSH key to the target
ssh-copy-id root@192.168.1.100

# SSH into the target
ssh root@192.168.1.100
```

**All remaining steps in Step 2-4 are executed on the target machine via SSH.**

## Step 2: Bootstrap Configuration on Target

Now, working ON the target machine (via SSH):

### Generate SSH Host Keys (for your config)

```bash
# Generate an SSH key on the target to use in your config
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# Display your public key - you'll need this for the config
cat ~/.ssh/id_ed25519.pub
# Copy this key, you'll use it in the configuration
```

### Create Repository Structure

```bash
# Create the config directory
mkdir -p ~/nixos-config
cd ~/nixos-config

# Create directory structure
mkdir -p hosts/test-nuc
mkdir -p modules/nixos
mkdir -p modules/home-manager
mkdir -p bin
mkdir -p secrets

# Initialize git
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### Create Basic flake.nix

```bash
cat > flake.nix <<'EOF'
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, ... }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations = {
      test-nuc = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/test-nuc
        ];
      };
    };
  };
}
EOF
```

### Create .gitignore

```bash
cat > .gitignore <<'EOF'
result
result-*
secrets/*.key
!secrets/*.age
.direnv/
EOF
```

## Step 3: Create Disko Disk Configuration

Still on the target machine:

### Find Your Disk ID

```bash
# List all disks by ID
ls -la /dev/disk/by-id/

# Look for your target disk (usually nvme-* or ata-*)
# Example output:
# nvme-SAMSUNG_MZVL2512HCJQ-00B00_S677NE0R426162 -> ../../nvme0n1
# ata-WDC_WD10EZEX-08WN4A0_WD-WCC6Y7KH8J2V -> ../../sda

# Copy the full disk ID (the part BEFORE the arrow)
```

### Generate Networking Host ID

```bash
# Generate a unique host ID for ZFS
head -c 8 /dev/urandom | od -A n -t x4 | tr -d ' '
# Example output: a1b2c3d4
# Save this, you'll use it in the config
```

### Create disk-config.nix

Replace `YOUR-DISK-ID-HERE` with your actual disk ID from above:

```bash
cat > hosts/test-nuc/disk-config.nix <<'EOF'
{
  lib,
  config,
  ...
}: {
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      # REPLACE THIS with your disk ID from: ls -la /dev/disk/by-id/
      device = "/dev/disk/by-id/YOUR-DISK-ID-HERE";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          zfs = {
            end = "-16G";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
          encryptedSwap = {
            size = "100%";
            content = {
              type = "swap";
              randomEncryption = true;
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

          crypt = {
            type = "zfs_fs";
            options.mountpoint = "none";
            options.encryption = "aes-256-gcm";
            options.keyformat = "raw";
            options.keylocation = "file:///etc/credstore/zfs-sysroot.mount";
            preCreateHook = "mount -o X-mount.mkdir /dev/mapper/credstore /etc/credstore && head -c 32 /dev/urandom > /etc/credstore/zfs-sysroot.mount";
            postCreateHook = "umount /etc/credstore && cryptsetup luksClose /dev/mapper/credstore";
          };

          "crypt/system" = {
            type = "zfs_fs";
            mountpoint = "/";
          };

          "crypt/system/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              "com.sun:auto-snapshot" = "false";
            };
          };

          "crypt/system/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
          };
        };
      };
    };
  };
}
EOF

# NOW EDIT THE FILE to replace YOUR-DISK-ID-HERE with your actual disk ID
# Use vim, nano, or any editor:
vim hosts/test-nuc/disk-config.nix
# or
nano hosts/test-nuc/disk-config.nix
```

## Step 4: Create Host Configuration

### Generate Hardware Configuration

```bash
# Generate hardware config (without filesystems since disko handles that)
nixos-generate-config --no-filesystems --root /mnt --show-hardware-config > hosts/test-nuc/hardware-configuration.nix
```

### Create default.nix

Replace placeholders with your values:

```bash
cat > hosts/test-nuc/default.nix <<'EOF'
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking.hostName = "test-nuc";
  networking.hostId = "YOUR-HOST-ID-HERE";  # Replace with ID from: head -c 8 /dev/urandom | od -A n -t x4 | tr -d ' '
  networking.networkmanager.enable = true;

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  # Add your SSH public key here
  users.users.root.openssh.authorizedKeys.keys = [
    "YOUR-SSH-PUBLIC-KEY-HERE"  # Replace with your key
  ];

  # Create a regular user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "YOUR-SSH-PUBLIC-KEY-HERE"  # Replace with your key
    ];
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    wget
    curl
  ];

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  system.stateVersion = "25.05";
}
EOF

# NOW EDIT THE FILE to add your SSH key and host ID
vim hosts/test-nuc/default.nix
# or
nano hosts/test-nuc/default.nix
```

## Step 5: Commit and Copy to Local Machine

Still on the target machine:

### Lock and Commit the Configuration

```bash
# Lock the flake (this downloads all dependencies)
nix flake lock

# Add all files to git
git add .

# Commit
git commit -m "Initial NixOS configuration for test-nuc"

# Verify everything is committed
git status
git log
```

### Copy Configuration to Your Local Machine

On your **local machine**, pull the configuration from the target:

```bash
# Create a directory for your NixOS configs
mkdir -p ~/nixos-config
cd ~/nixos-config

# Copy the entire repo from the target
scp -r root@192.168.1.100:~/nixos-config/* .

# Or use rsync for a cleaner copy
rsync -avz --progress root@192.168.1.100:~/nixos-config/ .

# Initialize git if needed
git init
git add .
git commit -m "Initial configuration from target bootstrap"
```

You now have the complete configuration on your local machine!

## Step 6: Install with nixos-anywhere

From your **local machine** (without Nix installed):

### Using Docker (Recommended - No Nix Required)

If you have Docker installed:

```bash
cd ~/nixos-config

# Run nixos-anywhere in a container
docker run -it --rm \
  -v $(pwd):/config \
  -v ~/.ssh:/root/.ssh:ro \
  ghcr.io/nix-community/nixos-anywhere:latest \
  --flake /config#test-nuc \
  root@192.168.1.100
```

### Using Nix (If You Install It)

If you want to install Nix on your local machine:

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Restart your shell
exec $SHELL

# Run nixos-anywhere
cd ~/nixos-config
nix run github:nix-community/nixos-anywhere -- \
  --flake .#test-nuc \
  root@192.168.1.100
```

### What Happens During Installation

nixos-anywhere will:
1. Connect to the target machine via SSH
2. Partition and format disks according to your `disk-config.nix`
3. Install NixOS based on your configuration
4. Set up the bootloader
5. Reboot the system

### Post-Install Cleanup

After installation completes, it may hang. On the **target machine** console or via SSH (if still connected):

```bash
# Close the credstore LUKS device
cryptsetup luksClose /dev/mapper/credstore

# Reboot
reboot
```

## Step 7: Post-Installation

### First Boot

After reboot:
1. Remove the USB drive
2. The system will prompt for the LUKS disk encryption password
3. System boots to login prompt
4. SSH keys have changed

### Update Known Hosts

On your local machine:

```bash
# Remove old SSH key
ssh-keygen -R 192.168.1.100

# Connect to verify
ssh root@192.168.1.100
```

### Push Configuration to GitHub

```bash
cd ~/nixos-config

# Create a repo on GitHub, then:
git remote add origin https://github.com/yourusername/nixos-config.git
git branch -M main
git push -u origin main
```

### Make Future Updates

Create a deployment script `bin/updateTestNuc`:

```bash
mkdir -p bin
cat > bin/updateTestNuc <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Rebuild and deploy to test-nuc
nix run github:nix-community/nixos-anywhere -- \
  --flake .#test-nuc \
  --build-on-remote \
  root@192.168.1.100
EOF

chmod +x bin/updateTestNuc
```

Or if you have Nix installed locally:

```bash
cat > bin/updateTestNuc <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

nixos-rebuild switch \
  --flake .#test-nuc \
  --target-host root@192.168.1.100 \
  --use-remote-sudo
EOF

chmod +x bin/updateTestNuc
```

To deploy changes:

```bash
# Edit your config
vim hosts/test-nuc/default.nix

# Deploy
./bin/updateTestNuc
```

## Example: test-nuc Configuration

See the complete example in the repository at `hosts/test-nuc/`:

```
hosts/test-nuc/
├── default.nix              # Main host configuration
├── disk-config.nix          # Disko disk layout
└── hardware-configuration.nix  # Generated hardware config
```

## Alternative: Simpler Disk Layout (ext4)

If you don't want ZFS encryption, here's a simpler `disk-config.nix`:

```nix
{
  lib,
  config,
  ...
}: {
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      device = "/dev/disk/by-id/YOUR-DISK-ID";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
```

## Troubleshooting

### Can't SSH to Target After Boot

- Verify network connectivity: `ping 192.168.1.100`
- Check if SSH is running: `systemctl status sshd` (on target console)
- Verify your SSH key is in the configuration

### Wrong Disk ID

- Boot back into live ISO
- Run `ls -la /dev/disk/by-id/` to get the correct ID
- Update `disk-config.nix` locally
- Re-run nixos-anywhere

### Hardware Config Changes

If you need to regenerate the hardware config:

```bash
# Boot live ISO on target
# Generate config
nixos-generate-config --no-filesystems --show-hardware-config

# Copy output to your local hosts/test-nuc/hardware-configuration.nix
# Commit and redeploy
```

### Flake Lock Issues

If `nix flake lock` fails on the target:

```bash
# Update flake
nix flake update

# Try locking again
nix flake lock --refresh
```

## Next Steps

1. **Disable root SSH**: Change `PermitRootLogin` to `"no"`
2. **Set up secrets management**: Use [agenix](./AGENIX_SECRET_MANAGEMENT.md)
3. **Configure Home Manager**: Manage user dotfiles
4. **Join Tailscale network**: [Headscale setup](./HEADSCALE_SETUP.md)
5. **Enable Secure Boot**: [TPM and Secure Boot](./ROOT_DISK_TPM_SECURE_BOOT_UNLOCK.md)
6. **Set up ZFS snapshots**: [ZFS remote replication](./ZFS_REMOTE_REPLICATION.md)

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [Disko](https://github.com/nix-community/disko)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
