# macOS Home Manager Setup

This document explains how to set up and use home-manager on macOS with this Nix configuration.

## Overview

The macOS home-manager configuration provides a declarative way to manage your user environment on macOS using Nix. This configuration includes CLI tools, development utilities, and MCP (Model Context Protocol) servers.

## Prerequisites

### 1. Install Nix

Install Nix on macOS using the Determinate Systems installer (recommended):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Or use the official installer:

```bash
sh <(curl -L https://nixos.org/nix/install)
```

After installation, restart your terminal or source the Nix profile:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 2. Enable Flakes

Nix flakes should be enabled by default with the Determinate Systems installer. If using the official installer, enable flakes by creating/editing `~/.config/nix/nix.conf`:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 3. Install Home Manager

Home Manager is managed through this flake configuration, so no separate installation is required. The first run will bootstrap home-manager automatically.

## Configuration Structure

The macOS configuration is located at `home-manager/ncrmro/macos.nix` and includes:

- **Base Configuration**: Common settings from `home-manager/common/global`
- **CLI Tools**: Terminal utilities, shell configuration, and development tools from `home-manager/common/features/cli`
- **MCP Servers**: Model Context Protocol servers for enhanced development:
  - GitHub MCP for repository integration
  - Kubernetes MCP for cluster management
  - Playwright MCP for browser automation

## Usage

### Initial Setup

Clone this repository and navigate to it:

```bash
cd ~/code/ncrmro/nixos-config
```

### Apply Configuration

To apply the home-manager configuration for the first time:

```bash
nix run home-manager/master -- switch --flake .#nicholas@macos
```

After the initial setup, you can use the convenient update script:

```bash
./bin/updateMacos
```

### Updating Configuration

1. Make changes to `home-manager/ncrmro/macos.nix` or any imported modules
2. Run the update script:

```bash
./bin/updateMacos
```

This will rebuild and activate the new configuration.

### Updating Flake Inputs

To update all flake inputs (nixpkgs, home-manager, etc.):

```bash
nix flake update
./bin/updateMacos
```

To update a specific input:

```bash
nix flake lock --update-input nixpkgs
./bin/updateMacos
```

## Included Features

### CLI Tools

The configuration includes various command-line tools and utilities:

- **Helix**: Modern modal text editor
- **Git**: Version control with pre-configured settings
- **Shell utilities**: Enhanced shell experience with modern alternatives
- **Development tools**: Language-specific toolchains and utilities

### MCP Servers

The following MCP servers are configured:

- **GitHub MCP**: Integration with GitHub repositories and APIs
- **Kubernetes MCP**: Kubernetes cluster interaction and management
- **Playwright MCP**: Browser automation and testing capabilities

## Customization

### Adding Packages

To add additional packages, edit `home-manager/ncrmro/macos.nix`:

```nix
{
  home.packages = with pkgs; [
    # Add your packages here
    ripgrep
    fd
    bat
  ];
}
```

### Importing Additional Modules

To enable more features, import them in `home-manager/ncrmro/macos.nix`:

```nix
{
  imports = [
    ../common/global
    ../common/features/cli
    ../common/optional/mcp/github-mcp.nix
    # Add more imports here
    ../common/features/desktop/obs.nix
  ];
}
```

### macOS-Specific Configuration

For macOS-specific settings, you can add them directly to `macos.nix`:

```nix
{
  # macOS-specific packages
  home.packages = with pkgs; [
    darwin.apple_sdk.frameworks.Security
  ];

  # macOS-specific programs
  programs.alacritty.settings.font.size = lib.mkForce 14.0;
}
```

## Troubleshooting

### Command Not Found

After switching configurations, you may need to restart your shell or source the home-manager session:

```bash
source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
```

### Conflicting Files

If home-manager complains about existing files, you can:

1. Backup the existing files
2. Remove them
3. Re-run the switch command

Or use the `--backup` option:

```bash
home-manager switch --flake .#ncrmro@macos --backup backup
```

### Nix Store Issues

If you encounter issues with the Nix store, try running garbage collection:

```bash
nix-collect-garbage -d
```

### Build Failures

If a build fails, check:

1. Your flake inputs are up-to-date: `nix flake update`
2. No syntax errors in your configuration files
3. The error message for specific package or module issues

You can also try building without switching to see errors:

```bash
nix build .#homeConfigurations.nicholas@macos.activationPackage
```

## Additional Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/packages)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [Nix Darwin](https://github.com/LnL7/nix-darwin) - For system-level macOS configuration

## Notes

- This configuration uses `aarch64-darwin` architecture for Apple Silicon Macs
- The configuration is user-level only (no system-level changes)
- For system-level macOS configuration, consider using nix-darwin alongside home-manager
