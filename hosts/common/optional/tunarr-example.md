# Tunarr NixOS Module

This module provides a declarative way to run [Tunarr](https://tunarr.com/) on NixOS using Docker containers.

Tunarr allows you to create and configure live TV channels using media from your Plex, Jellyfin, or Emby servers. It spoofs an HDHomerun tuner that can be added to your media server.

## Basic Usage

Add to your host configuration:

```nix
imports = [
  ../common/optional/tunarr.nix
];

services.tunarr = {
  enable = true;
  openFirewall = true;  # Opens port on tailscale interface
  extraGroups = [ "media" ];  # Access to media files
};
```

## Advanced Configuration

```nix
services.tunarr = {
  enable = true;
  port = 8000;
  dataDir = "/var/lib/tunarr";
  imageTag = "latest";  # or "edge" for development builds
  timezone = "America/New_York";
  logLevel = "info";  # debug, info, warn, error
  user = "tunarr";
  group = "tunarr";
  extraGroups = [
    "media"  # Access to media files
    "video"  # Hardware encoding support (enables /dev/dri access)
  ];
  openFirewall = true;
};
```

## Hardware Encoding

To enable hardware encoding (e.g., Intel QuickSync, VAAPI):

1. Add the `video` group to `extraGroups`
2. Ensure your user has access to `/dev/dri`
3. The module will automatically mount `/dev/dri` into the container

```nix
services.tunarr = {
  enable = true;
  extraGroups = [ "video" "media" ];
};
```

## Accessing Tunarr

After enabling the service, Tunarr will be available at:
- `http://localhost:8000` (or your configured port)
- `http://<tailscale-ip>:8000` (if openFirewall is enabled)

## Media Server Integration

1. Configure your Plex/Jellyfin/Emby server in Tunarr's web UI
2. Create channels and add programs
3. Tunarr spoofs an HDHomerun device that can be added to your media server
4. The HDHomerun device will be discoverable on your network

## Data Persistence

All configuration and data is stored in `/var/lib/tunarr` by default. This includes:
- Channel configurations
- Program schedules
- Database files
- Logs

## Notes

- Requires Docker to be enabled (automatically enabled by this module)
- Default port is 8000
- Firewall is opened only on the tailscale interface by default
- Uses the official Docker image from `chrisbenincasa/tunarr`
