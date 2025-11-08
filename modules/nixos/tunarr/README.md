# Tunarr NixOS Module

This module provides a declarative way to run [Tunarr](https://tunarr.com/) on NixOS using the standalone binary.

Tunarr allows you to create and configure live TV channels using media from your Plex, Jellyfin, or Emby servers. It spoofs an HDHomerun tuner that can be added to your media server.

## Features

- Standalone binary (no Docker required)
- Bundled with ffmpeg for transcoding
- Systemd service with hardening
- Configurable user/group management
- Optional firewall configuration

## Basic Usage

Import the module and enable the service:

```nix
{
  imports = [
    ./modules/nixos/tunarr
  ];

  services.tunarr = {
    enable = true;
    openFirewall = true;
  };
}
```

## Configuration Options

### `services.tunarr.enable`
- Type: `boolean`
- Default: `false`
- Description: Enable the Tunarr service

### `services.tunarr.package`
- Type: `package`
- Default: `pkgs.tunarr`
- Description: The Tunarr package to use

### `services.tunarr.dataDir`
- Type: `string`
- Default: `"/var/lib/tunarr"`
- Description: Directory where Tunarr stores its data files

### `services.tunarr.port`
- Type: `port`
- Default: `8000`
- Description: Port on which Tunarr will listen

### `services.tunarr.openFirewall`
- Type: `boolean`
- Default: `false`
- Description: Open firewall port for Tunarr

### `services.tunarr.user`
- Type: `string`
- Default: `"tunarr"`
- Description: User account under which Tunarr runs

### `services.tunarr.group`
- Type: `string`
- Default: `"tunarr"`
- Description: Group under which Tunarr runs

### `services.tunarr.extraGroups`
- Type: `list of strings`
- Default: `[]`
- Example: `["media" "video"]`
- Description: Additional groups for the Tunarr user (useful for accessing media files)

## Advanced Configuration

```nix
services.tunarr = {
  enable = true;
  port = 8000;
  dataDir = "/var/lib/tunarr";
  user = "tunarr";
  group = "tunarr";
  extraGroups = [
    "media"  # Access to media files
  ];
  openFirewall = false;  # Use tailscale interface instead
};

# Open port on tailscale interface only
networking.firewall.interfaces.tailscale0 = {
  allowedTCPPorts = [ 8000 ];
};
```

## Using the Optional Module

For convenience, use the pre-configured optional module:

```nix
{
  imports = [
    ./hosts/common/optional/tunarr.nix
  ];
}
```

This automatically:
- Enables Tunarr
- Opens port 8000 on the tailscale interface only
- Uses default settings

## Accessing Tunarr

After enabling the service, Tunarr will be available at:
- `http://localhost:8000` (or your configured port)
- `http://<tailscale-ip>:8000` (if using tailscale)

## Media Server Integration

1. Access the Tunarr web UI
2. Configure your Plex/Jellyfin/Emby server connection
3. Create channels and add programs
4. Tunarr will spoof an HDHomerun device
5. Add the HDHomerun tuner to your media server
6. The device will be automatically discoverable on your network

## Data Persistence

All configuration and data is stored in `/var/lib/tunarr` by default. This includes:
- Channel configurations
- Program schedules
- Database files
- Logs

## Systemd Service

The service is managed by systemd and includes:
- Automatic restart on failure
- Security hardening (NoNewPrivileges, PrivateTmp, etc.)
- Runs as unprivileged user
- Working directory set to data directory

Check service status:
```bash
systemctl status tunarr
```

View logs:
```bash
journalctl -u tunarr -f
```

## Package Details

The Tunarr package:
- Downloads the official standalone Linux binary from GitHub releases
- Wraps the binary with ffmpeg in PATH
- Uses autoPatchelfHook for dynamic library dependencies
- Currently supports x86_64-linux only

## Notes

- Default port is 8000
- FFmpeg is bundled for transcoding support
- The binary includes Node.js runtime (no separate Node.js installation needed)
- Service includes systemd hardening for security
