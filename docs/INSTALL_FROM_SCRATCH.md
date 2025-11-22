# Installing NixOS from Scratch with nixos-anywhere

This guide walks you through installing NixOS on a remote machine over SSH using nixos-anywhere, starting from scratch without NixOS installed on your local machine.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Step 1: Set Up Your Local Environment](#step-1-set-up-your-local-environment)
- [Step 2: Create a New NixOS Configuration Repository](#step-2-create-a-new-nixos-configuration-repository)
- [Step 3: Create Your First Host Configuration](#step-3-create-your-first-host-configuration)
- [Step 4: Prepare the Target Machine](#step-4-prepare-the-target-machine)
- [Step 5: Install NixOS with nixos-anywhere](#step-5-install-nixos-with-nixos-anywhere)
- [Step 6: Post-Installation](#step-6-post-installation)
- [Example: test-nuc Configuration](#example-test-nuc-configuration)

## Prerequisites

### On Your Local Machine
- **Nix package manager** installed with flakes enabled
- **SSH key pair** generated (`ssh-keygen -t ed25519`)
- **Git** for version control

### On the Target Machine
- **Network connectivity** and ability to boot from a live USB/ISO
- **SSH access** as root (typically via NixOS minimal ISO or another Linux live environment)
- **Known disk device ID** (we'll determine this during setup)

### Installing Nix on Non-NixOS Systems

If you don't have Nix installed yet:

```bash
# Install Nix (multi-user installation recommended)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Enable flakes by adding to ~/.config/nix/nix.conf or /etc/nix/nix.conf
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

## Step 1: Set Up Your Local Environment

First, ensure Nix flakes are enabled and install necessary tools:

```bash
# Verify Nix installation
nix --version

# Test flakes are enabled
nix flake --version

# Install helpful tools
nix profile install nixpkgs#alejandra  # Nix code formatter
nix profile install nixpkgs#git
```

## Step 2: Create a New NixOS Configuration Repository

Create a new Git repository to manage your NixOS configurations:

```bash
# Create and navigate to your config directory
mkdir -p ~/nixos-config
cd ~/nixos-config

# Initialize git repository
git init

# Create directory structure
mkdir -p hosts/test-nuc
mkdir -p modules/nixos
mkdir -p modules/home-manager
mkdir -p secrets
```

### Create the Basic flake.nix

Create a `flake.nix` file at the root of your repository:

```nix
{
  description = "My NixOS configurations";

  inputs = {
    # Main package source
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # Disko for declarative disk management
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager for user environment management
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, ... }: {
    # Code formatter
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    # NixOS system configurations
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
```

### Create .gitignore

```bash
cat > .gitignore <<'EOF'
# Build results
result
result-*

# Hardware configs (generated, but we'll track them)
# Uncomment if you prefer not to track hardware-configuration.nix
# hardware-configuration.nix

# Secrets (use agenix for encrypted secrets)
secrets/*.key
!secrets/*.age

# Nix
.direnv/
EOF
```

## Step 3: Create Your First Host Configuration

### Understanding Disko

Disko is a declarative disk partitioning tool for NixOS. Instead of manually partitioning disks, you describe the desired layout in Nix, and Disko handles the rest.

### Create disk-config.nix

This example uses ZFS with LUKS encryption. Create `hosts/test-nuc/disk-config.nix`:

```nix
{
  lib,
  config,
  ...
}: {
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      # NOTE: Update this with your actual disk ID (we'll find this later)
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HCJQ-00B00_S677NE0R426162";
      content = {
        type = "gpt";
        partitions = {
          # EFI System Partition for bootloader
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
          # Main ZFS partition (leaving space for swap)
          zfs = {
            end = "-16G";  # Reserve 16GB for swap
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
          # Encrypted swap partition
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

    # ZFS pool configuration
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
          # Credential store for ZFS encryption key
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
            options.mountpoint = "none";
            options.encryption = "aes-256-gcm";
            options.keyformat = "raw";
            options.keylocation = "file:///etc/credstore/zfs-sysroot.mount";
            preCreateHook = "mount -o X-mount.mkdir /dev/mapper/credstore /etc/credstore && head -c 32 /dev/urandom > /etc/credstore/zfs-sysroot.mount";
            postCreateHook = "umount /etc/credstore && cryptsetup luksClose /dev/mapper/credstore";
          };

          # System root
          "crypt/system" = {
            type = "zfs_fs";
            mountpoint = "/";
          };

          # Nix store (no snapshots needed)
          "crypt/system/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              "com.sun:auto-snapshot" = "false";
            };
          };

          # System state
          "crypt/system/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
          };
        };
      };
    };
  };
}
```

#### Simpler Disk Configuration (Without ZFS Encryption)

If you want a simpler setup without ZFS encryption, use this instead:

```nix
{
  lib,
  config,
  ...
}: {
  disko.devices = {
    disk.disk1 = {
      type = "disk";
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

### Create default.nix

Create `hosts/test-nuc/default.nix`:

```nix
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
  networking.hostId = "a1b2c3d4";  # Generate with: head -c 8 /etc/machine-id
  networking.networkmanager.enable = true;

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";  # Change to "no" after initial setup
      PasswordAuthentication = false;
    };
  };

  # Add your SSH public key
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3Nza... your-public-key-here"
  ];

  # Create a regular user
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3Nza... your-public-key-here"
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of your initial installation.
  system.stateVersion = "25.05";
}
```

### Create a Placeholder hardware-configuration.nix

Create `hosts/test-nuc/hardware-configuration.nix` (this will be replaced during installation):

```nix
# This is a placeholder that will be automatically generated by nixos-anywhere
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
```

## Step 4: Prepare the Target Machine

### Boot the Target Machine

1. Download the [NixOS minimal ISO](https://nixos.org/download.html)
2. Create a bootable USB drive:
   ```bash
   dd if=nixos-minimal-xx.xx.iso of=/dev/sdX bs=4M status=progress
   ```
3. Boot the target machine from the USB drive

### Configure Network and SSH on Target

Once booted into the NixOS live environment on the target machine:

```bash
# Set a root password for SSH access
passwd

# Start SSH service
systemctl start sshd

# Find the IP address
ip addr show

# Note the IP address (e.g., 192.168.1.100)
```

### Determine Disk ID

On the target machine, find your disk's ID:

```bash
# List all disks by ID
ls -la /dev/disk/by-id/

# Look for your primary disk (usually nvme-* or ata-*)
# Example output:
# nvme-SAMSUNG_MZVL2512HCJQ-00B00_S677NE0R426162 -> ../../nvme0n1
```

Copy the full disk ID (without the `-> ../../nvme0n1` part) and update your `disk-config.nix` accordingly.

### Test SSH Access from Local Machine

From your local machine:

```bash
# Copy your SSH key to the target
ssh-copy-id root@192.168.1.100

# Test SSH connection
ssh root@192.168.1.100

# If connection works, exit
exit
```

## Step 5: Install NixOS with nixos-anywhere

### Update Your Configuration

Before installing, make sure to:

1. Update `disk-config.nix` with the correct disk ID
2. Update `default.nix` with your SSH public key
3. Generate a unique host ID:
   ```bash
   head -c 8 /dev/urandom | od -A n -t x4 | tr -d ' '
   # Example output: a1b2c3d4
   ```
   Update `networking.hostId` in `default.nix`

### Lock and Check Your Flake

```bash
# Lock the flake inputs
nix flake lock

# Check the flake configuration
nix flake check

# Format the code
alejandra .
```

### Run nixos-anywhere

```bash
# Test with VM first (optional but recommended)
nix run github:nix-community/nixos-anywhere -- --flake .#test-nuc --vm-test

# Install to the real target machine
nix run github:nix-community/nixos-anywhere -- \
  --flake .#test-nuc \
  --generate-hardware-config nixos-generate-config ./hosts/test-nuc/hardware-configuration.nix \
  root@192.168.1.100
```

### What nixos-anywhere Does

1. Connects to the target machine via SSH
2. Partitions and formats the disks according to your `disk-config.nix`
3. Generates a hardware configuration
4. Copies your configuration to the target
5. Installs NixOS
6. Sets up the bootloader

### Important: Post-Install Cleanup

After installation completes, the installer might hang. On the **target machine**, run:

```bash
cryptsetup luksClose /dev/mapper/credstore
```

Then reboot the target machine:

```bash
reboot
```

## Step 6: Post-Installation

### First Boot

After the machine reboots:

1. You'll be prompted for the LUKS disk encryption password (if using ZFS encryption)
2. The system should boot to a login prompt
3. The SSH host keys will have changed

### Update SSH Known Hosts

On your local machine:

```bash
# Remove old host key
ssh-keygen -R 192.168.1.100

# Connect to the new system
ssh root@192.168.1.100
```

### Commit Your Configuration

Back on your local machine:

```bash
cd ~/nixos-config

# Add all files
git add .

# Commit
git commit -m "Initial NixOS configuration for test-nuc"

# Optional: push to a remote repository
git remote add origin https://github.com/yourusername/nixos-config.git
git push -u origin main
```

### Make Future Updates

To update the system configuration:

```bash
# Make changes to your config
vim hosts/test-nuc/default.nix

# Format and check
alejandra .
nix flake check

# Deploy to the remote host
nixos-rebuild switch --flake .#test-nuc --target-host root@192.168.1.100

# Or create a convenience script
echo '#!/usr/bin/env bash
nixos-rebuild switch --flake .#test-nuc --target-host root@192.168.1.100' > bin/updateTestNuc
chmod +x bin/updateTestNuc
```

### Recommended Next Steps

1. **Disable root SSH login**: Change `PermitRootLogin` to `"no"` in your config
2. **Set up secrets management**: Install and configure [agenix](../AGENIX_SECRET_MANAGEMENT.md)
3. **Configure Home Manager**: Set up user environments
4. **Enable automatic updates**: Configure `system.autoUpgrade`
5. **Set up backups**: Configure ZFS snapshots and remote replication
6. **Harden security**:
   - [Set up Secure Boot with lanzaboote](./ROOT_DISK_TPM_SECURE_BOOT_UNLOCK.md)
   - [Configure TPM for automatic disk unlock](./ROOT_DISK_TPM_SECURE_BOOT_UNLOCK.md)
   - Enable firewall rules
7. **Join your Tailscale/Headscale network**: [See Tailscale setup](./HEADSCALE_SETUP.md)

## Example: test-nuc Configuration

See the complete example in this repository at `hosts/test-nuc/`. This provides a working reference implementation you can copy and modify.

## Troubleshooting

### SSH Connection Issues
- Ensure the target machine is on the network: `ping 192.168.1.100`
- Verify SSH service is running: `systemctl status sshd` (on target)
- Check firewall rules

### Disk Not Found
- Verify disk ID: `ls -la /dev/disk/by-id/`
- Ensure the disk ID in `disk-config.nix` matches exactly

### Installation Hangs
- Check `dmesg` on the target machine for errors
- Verify network connectivity is stable
- Try the `--vm-test` flag first to test configuration

### LUKS Password Not Working
- The credstore LUKS password is set during installation
- Make sure you're entering it correctly at boot
- Check kernel command line for any issues: `cat /proc/cmdline`

### Hardware Config Generation Fails
- Manually generate on target: `nixos-generate-config --no-filesystems --root /mnt`
- Copy from target: `scp root@192.168.1.100:/etc/nixos/hardware-configuration.nix ./hosts/test-nuc/`

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-anywhere Documentation](https://github.com/nix-community/nixos-anywhere)
- [Disko Documentation](https://github.com/nix-community/disko)
- [Nix Flakes Guide](https://nixos.wiki/wiki/Flakes)
