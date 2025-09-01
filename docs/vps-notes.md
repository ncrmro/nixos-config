# Virtual Private Server (VPS) NixOS Install on Vultr

This document provides instructions for installing NixOS on a Vultr VPS using `nixos-infect`.

## Prerequisites

- Vultr account
- SSH key added to your Vultr account
- Backup any important data if converting an existing server

## Vultr Installation Steps

1. Create a new server on Vultr:
   - Select Ubuntu 22.04 x64 as the operating system
   - Choose your preferred server size and location
   - Make sure to select your SSH key for authentication
   - In the "Startup Script" or "Cloud-Init User-Data" section, add:

```sh
#!/bin/sh

curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-23.05 bash
```

2. Deploy the server and wait. The installation will take a few minutes longer than a standard Ubuntu deployment as NixOS needs to download and install itself.

3. Once the server is ready, you can SSH in using your key:

```bash
ssh root@<vultr-ip-address>
```

## Post-Installation Configuration Workflow

After installation, copy the auto-generated NixOS configuration from the server to integrate it with your repository:

```bash
# Create the host directory if it doesn't exist
mkdir -p hosts/mercury

# Copy the configuration files from the server
scp root@<vultr-ip-address>:/etc/nixos/hardware-configuration.nix hosts/mercury/
scp root@<vultr-ip-address>:/etc/nixos/configuration.nix hosts/mercury/generated-config.nix
```

Next, create or update your `default.nix` for this host:

```bash
# Create a default.nix that imports the hardware-configuration and your other modules
# Edit this file to incorporate settings from the generated-config.nix as needed
```

Commit the changes to your repository:

```bash
git add hosts/mercury
git commit -m "Add Vultr VPS configuration for mercury host"
```

Finally, push your custom configuration to the server:

```bash
scp -r hosts/mercury root@<vultr-ip-address>:/etc/nixos/host-config
ssh root@<vultr-ip-address> 'cd /etc/nixos && nixos-rebuild switch -I nixos-config=/etc/nixos/host-config/default.nix'
```

## Configuration Notes

- The `networking.hostId` must be a valid 8-character hexadecimal string
- Make sure to preserve important auto-generated settings from the server's configuration
- Integrate the configuration with your existing NixOS modules and common settings

## Common Issues

- If the installation fails, the system might be left in an inconsistent state
- Always ensure you have a backup or snapshot before converting an existing server
- Vultr-specific network configuration may need to be preserved from the generated config