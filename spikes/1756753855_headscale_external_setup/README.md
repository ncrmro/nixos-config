# Headscale External Setup Guide

This document outlines the steps required outside of the Mercury server configuration to properly set up and use Headscale.

## DNS Configuration

1. Configure an A record for `mercury.ncrmro.com` pointing to the Mercury server's public IP address.
   ```
   mercury.ncrmro.com.  IN  A  <Mercury-Server-Public-IP>
   ```

## Client Setup

### Installing Tailscale Clients

1. Install Tailscale on client devices (Linux/macOS/Windows/iOS/Android).
   - Linux: https://tailscale.com/download/linux
   - macOS: App Store or https://tailscale.com/download/mac
   - Windows: https://tailscale.com/download/windows
   - iOS: App Store
   - Android: Play Store

### Registering Clients with Headscale

1. On the Mercury server, create a new user namespace:
   ```bash
   sudo headscale users create <namespace>
   ```

2. Generate an auth key for the namespace:
   ```bash
   sudo headscale --namespace <namespace> preauthkeys create --reusable --expiration 24h
   ```

3. On the client device, connect to Headscale using the auth key:
   ```bash
   tailscale up --login-server=https://mercury.ncrmro.com --authkey=<auth-key>
   ```

### Using Node Keys (Alternative Method)

1. Start Tailscale on the client in ephemeral mode without authentication:
   ```bash
   tailscale up --login-server=https://mercury.ncrmro.com
   ```

2. Note the node key displayed in the output or retrieve with:
   ```bash
   tailscale status --json | jq -r .Self.NodeKey
   ```

3. On the Mercury server, register the node:
   ```bash
   sudo headscale nodes register --namespace <namespace> --key <node-key>
   ```

## ACL Configuration

1. Create an ACL policy file on the Mercury server (e.g., `/etc/headscale/acl.json`):
   ```json
   {
     "acls": [
       {
         "action": "accept",
         "users": ["*"],
         "ports": ["*:*"]
       }
     ],
     "ssh": [
       {
         "action": "accept",
         "users": ["*"],
         "hosts": ["*"]
       }
     ]
   }
   ```

2. Apply the ACL policy:
   ```bash
   sudo headscale acls apply -f /etc/headscale/acl.json
   ```

## Managing Nodes

1. List all nodes:
   ```bash
   sudo headscale nodes list
   ```

2. Delete a node:
   ```bash
   sudo headscale nodes delete -i <node-id>
   ```

## Troubleshooting

1. Check Headscale logs:
   ```bash
   journalctl -u headscale -f
   ```

2. Verify connectivity from clients:
   ```bash
   ping mercury.ncrmro.com
   curl -v https://mercury.ncrmro.com
   ```

3. Check client status:
   ```bash
   tailscale status
   ```

## External Monitoring (Optional)

1. Set up an external monitoring service (like Uptime Robot) to monitor `https://mercury.ncrmro.com` to ensure the service remains available.

## Backup Considerations

1. Regularly backup the Headscale database:
   ```bash
   sudo cp /var/lib/headscale/db.sqlite /backup/headscale-db-$(date +%F).sqlite
   ```

---

**Note:** This setup assumes you're using the default SQLite database. If you migrate to PostgreSQL or another database, backup procedures will differ.