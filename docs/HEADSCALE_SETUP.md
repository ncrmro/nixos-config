# Headscale Server and Tailscale Client Setup

This document explains how to set up and manage a Headscale server (self-hosted Tailscale control server) and connect Tailscale clients to it.

## Mercury Headscale Server

The `mercury` host is configured as a Headscale server, providing a self-hosted alternative to the Tailscale control server.

### Server Management

#### Updating Mercury Server

Use the `bin/updateMercury` script to:
1. Deploy the latest configuration to the Mercury server
2. Automatically create the `ncrmro` user in Headscale (if it doesn't exist)

```bash
# Run from the root of the repository
./bin/updateMercury
```

#### Manual Server Management

You can also manage the Headscale server directly:

```bash
# SSH to Mercury server
ssh root@mercury.ncrmro.com

# List users
headscale users list

# Create a new user
headscale users create <username>

# List nodes (machines)
headscale nodes list

# List pre-auth keys
headscale preauthkeys list --user <username>
```

## Connecting Tailscale Clients

### Creating Auth Keys

To connect a new client, you need to create a pre-authentication key:

```bash
# On Mercury server
headscale preauthkeys create --user ncrmro --reusable --expiration 24h
```

### Connecting a Client

On the client machine, install Tailscale and connect to your Headscale server:

```bash
# Install tailscale (example for NixOS)
# Add to your configuration.nix:
services.tailscale.enable = true;

# Connect to Headscale server
tailscale up --login-server https://mercury.ncrmro.com \
  --authkey <your-pre-auth-key>
```

### Using the NixOS Tailscale Module

For NixOS hosts, you can automate the Tailscale setup by adding to your host configuration:

```nix
services.tailscale = {
  enable = true;
  authKeyFile = "/path/to/tailscale/authkey";
  extraUpFlags = [
    "--login-server=https://mercury.ncrmro.com"
  ];
};
```

## Troubleshooting

### Server Issues

If the Headscale service isn't working properly:

```bash
# Check service status
systemctl status headscale

# View logs
journalctl -u headscale -f

# Restart service
systemctl restart headscale
```

### Client Issues

If a client cannot connect:

```bash
# Check tailscale status
tailscale status

# View logs
tailscale netcheck

# Restart tailscale
systemctl restart tailscaled
```