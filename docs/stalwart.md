# Stalwart Mail Server

This document covers the Stalwart mail server configuration on NixOS, including admin password management and troubleshooting.

## Architecture Overview

Stalwart is configured via the `keystone.os.mail` module (`.submodules/keystone/modules/os/mail.nix`) with host-specific overrides in `hosts/ocean/default.nix`.

Key components:
- **JMAP API**: `127.0.0.1:8082` (local only, proxied via nginx)
- **IMAP**: Port 993 (IMAPS with TLS)
- **SMTP**: Ports 25, 465 (SMTPS), 587 (submission)
- **Storage**: RocksDB at `/var/lib/stalwart-mail/`
- **Credentials**: Managed via agenix secrets

## Admin Password Configuration

### How It Works

1. **Agenix secret** (`secrets/stalwart-admin-password.age`) contains the **plaintext** password
2. **Agenix decrypts** it at boot to `/run/agenix/stalwart-admin-password`
3. **Stalwart config** references it via `%{file:/run/agenix/stalwart-admin-password}%`

**Important**: Despite what some documentation suggests, the `fallback-admin.secret` expects a **plaintext password**, not a SHA-512 hash. Stalwart reads the file content and compares it directly against the password provided during authentication.

### Configuration in `hosts/ocean/default.nix`

```nix
age.secrets.stalwart-admin-password = {
  file = ../../secrets/stalwart-admin-password.age;
  owner = "stalwart-mail";
  group = "stalwart-mail";
  mode = "0400";
};

services.stalwart-mail = {
  settings = {
    authentication.fallback-admin = {
      user = "admin";
      secret = "%{file:/run/agenix/stalwart-admin-password}%";
    };
  };
};
```

### Key Points

1. **Owner must be `stalwart-mail`**: The Stalwart service runs as this user and needs read access to the secret file
2. **Use agenix path directly**: `/run/agenix/stalwart-admin-password` instead of systemd LoadCredential
3. **Plaintext password**: Store the actual password, not a hash

## Password Reset Procedures

### Method 1: Update the Agenix Secret (Recommended)

Store the plaintext password in the secret:

```bash
# Store the plaintext password in the agenix secret
echo -n 'your-new-password' | sudo agenix -e secrets/stalwart-admin-password.age -i /etc/ssh/ssh_host_ed25519_key

# Rebuild and restart
sudo nixos-rebuild switch --flake .#ocean
sudo systemctl restart stalwart
```

### Method 2: Reset Database (Nuclear Option)

If the database has an existing admin account that overrides `fallback-admin`:

**Warning: This deletes ALL mail data and accounts!**

```bash
sudo systemctl stop stalwart
sudo rm -rf /var/lib/stalwart-mail/*
sudo systemctl start stalwart
```

The `fallback-admin` will then work since there's no database to override it.

## Testing Authentication

```bash
# Test API access
curl -s -u admin:'your-password' http://127.0.0.1:8082/api/principal/admin

# Check HTTP status
curl -s -u admin:'your-password' http://127.0.0.1:8082/api/principal/admin -w "\nHTTP Status: %{http_code}\n"

# Expected: 200 with JSON response on success, 401 on auth failure
```

## Troubleshooting

### Check Service Status

```bash
systemctl status stalwart --no-pager
journalctl -u stalwart --no-pager -n 50
```

### Verify Credential Files Exist

```bash
# Agenix decrypted secret (should be owned by stalwart-mail)
ls -la /run/agenix/stalwart-admin-password
```

### Check Active Config

```bash
# Find the config path from the running process
ps aux | grep stalwart

# View the fallback-admin config
cat /nix/store/XXX-stalwart.toml | grep -A5 "fallback-admin"
```

### Common Issues

1. **Secret not readable**: Ensure `owner = "stalwart-mail"` in the agenix secret config
2. **Using hash instead of plaintext**: The `fallback-admin.secret` expects plaintext, not SHA-512
3. **Database admin overrides fallback**: An admin created via web UI takes precedence over `fallback-admin`
4. **Service not restarted**: After secret changes, run `sudo systemctl restart stalwart`
5. **Wrong service name**: The NixOS service is `stalwart.service` (not `stalwart-mail.service`)

## API Account Management

Once admin auth is working, you can manage accounts via the JMAP API.

### List All Accounts

```bash
curl -s -u admin:'your-password' http://127.0.0.1:8082/api/principal | jq
```

### Create a User Account

```bash
curl -s -u admin:'your-password' http://127.0.0.1:8082/api/principal \
  -H "Content-Type: application/json" \
  -d '{
    "type": "individual",
    "name": "username",
    "secrets": ["user-password"],
    "emails": ["user@example.com"]
  }' | jq
```

### Get a Specific Account

```bash
curl -s -u admin:'your-password' http://127.0.0.1:8082/api/principal/username | jq
```

### Update Account Password

```bash
curl -s -u admin:'your-password' http://127.0.0.1:8082/api/principal/username \
  -X PATCH \
  -H "Content-Type: application/json" \
  -d '{"secrets": ["new-password"]}' | jq
```

### Delete an Account

```bash
curl -s -u admin:'your-password' http://127.0.0.1:8082/api/principal/username -X DELETE
```

### Create a Domain

```bash
curl -s -u admin:'your-password' http://127.0.0.1:8082/api/principal \
  -H "Content-Type: application/json" \
  -d '{
    "type": "domain",
    "name": "example.com"
  }' | jq
```

## User Mail Passwords (Himalaya Client)

Separate secrets exist for mail client authentication:

- `secrets/stalwart-mail-ncrmro-password.age` - for ncrmro user on desktops
- `secrets/stalwart-mail-drago-password.age` - for drago user on agent-drago VM

These are plaintext passwords used by the Himalaya email client.

Configuration in Home Manager:
```nix
programs.himalaya.accounts.<name>.backend.auth.command = "cat /run/agenix/stalwart-mail-<user>-password";
```

## References

- [Stalwart Administrators Documentation](https://stalw.art/docs/auth/authorization/administrator/)
- [NixOS Wiki - Stalwart](https://wiki.nixos.org/wiki/Stalwart)
- [GitHub Discussion: Reset Admin Password](https://github.com/stalwartlabs/stalwart/discussions/338)
- [How to Reset Stalwart Admin Password](https://wayneoutthere.com/2024/10/12/how-to-reset-your-stalwart-mail-admin-password/)
- [MyNixOS: services.stalwart-mail.credentials](https://mynixos.com/nixpkgs/option/services.stalwart-mail.credentials)
