# SSH Private Key Security Best Practices

This spike explores secure methods for managing SSH private keys using various secret management solutions including GNOME Keyring, 1Password, and Bitwarden.

## Overview

Traditional SSH key management often involves storing private keys directly on the filesystem (`~/.ssh/id_rsa`), which presents security risks:
- Keys are accessible to any process running as the user
- Keys may be accidentally committed to version control
- No centralized management across multiple devices
- Limited audit trail for key usage

Modern secret management solutions provide better security through:
- Encrypted storage with master password/biometric unlock
- Integration with SSH agent for seamless authentication
- Centralized management across devices
- Audit logs and access controls

## GNOME Keyring Integration

GNOME Keyring provides native SSH agent functionality on Linux desktop environments.

### Setup

```bash
# Ensure GNOME Keyring is installed and running
sudo pacman -S gnome-keyring  # Arch Linux
sudo apt install gnome-keyring  # Debian/Ubuntu

# Enable SSH agent component
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"
```

### Adding SSH Keys

```bash
# Add key to keyring (will prompt for passphrase once)
ssh-add ~/.ssh/id_rsa

# Add key with timeout (in seconds)
ssh-add -t 3600 ~/.ssh/id_rsa

# List keys in agent
ssh-add -l
```

### NixOS Configuration

```nix
# In your NixOS configuration
services.gnome.gnome-keyring.enable = true;
programs.seahorse.enable = true;  # GUI for keyring management

# For Home Manager
services.gnome-keyring = {
  enable = true;
  components = [ "pkcs11" "secrets" "ssh" ];
};
```

### Security Features

- Keys encrypted with user password/keyring password
- Automatic unlock on desktop login
- Keys remain in memory only while unlocked
- GUI management through Seahorse

## 1Password SSH Agent

1Password provides a built-in SSH agent that stores keys securely in your vault.

### Setup

```bash
# Enable SSH agent in 1Password settings
# Go to Settings > Developer > SSH Agent > Enable

# Configure SSH to use 1Password agent
echo 'Host *
    IdentityAgent ~/.1password/agent.sock' >> ~/.ssh/config
```

### Adding SSH Keys

1. Generate key pair in 1Password:
   - Open 1Password
   - Create new item > SSH Key
   - Generate or import existing key

2. Or import existing key:
   ```bash
   # Import existing private key
   op item create --category="SSH Key" --title="My SSH Key" \
     --ssh-key-private-key="$(cat ~/.ssh/id_rsa)" \
     --ssh-key-public-key="$(cat ~/.ssh/id_rsa.pub)"
   ```

### Configuration

```bash
# Set SSH_AUTH_SOCK environment variable
export SSH_AUTH_SOCK=~/.1password/agent.sock

# Add to shell profile
echo 'export SSH_AUTH_SOCK=~/.1password/agent.sock' >> ~/.bashrc
```

### Security Features

- Keys encrypted in 1Password vault
- Biometric unlock support
- Cross-device synchronization
- Detailed usage logs
- Integration with 1Password security model

## Bitwarden SSH Key Management

While Bitwarden doesn't provide a native SSH agent, it can securely store SSH keys and integrate with external agents.

### Setup with Bitwarden CLI

```bash
# Install Bitwarden CLI
npm install -g @bitwarden/cli

# Login to Bitwarden
bw login
export BW_SESSION="$(bw unlock --raw)"
```

### Storing SSH Keys

```bash
# Store private key in Bitwarden
bw create item '{
  "type": 2,
  "name": "SSH Key - GitHub",
  "notes": "SSH private key for GitHub",
  "secureNote": {
    "type": 0
  },
  "fields": [
    {
      "name": "private_key",
      "value": "'$(cat ~/.ssh/id_rsa | base64 -w 0)'",
      "type": 1
    },
    {
      "name": "public_key", 
      "value": "'$(cat ~/.ssh/id_rsa.pub)'",
      "type": 0
    }
  ]
}'
```

### Retrieval Script

```bash
#!/bin/bash
# retrieve-ssh-key.sh

KEY_NAME="$1"
if [ -z "$KEY_NAME" ]; then
    echo "Usage: $0 <key-name>"
    exit 1
fi

# Ensure Bitwarden session is active
if [ -z "$BW_SESSION" ]; then
    export BW_SESSION="$(bw unlock --raw)"
fi

# Retrieve and decode private key
ITEM_ID=$(bw list items --search "$KEY_NAME" | jq -r '.[0].id')
PRIVATE_KEY=$(bw get item "$ITEM_ID" | jq -r '.fields[] | select(.name=="private_key") | .value' | base64 -d)

# Write to temporary file and add to SSH agent
TEMP_KEY=$(mktemp)
echo "$PRIVATE_KEY" > "$TEMP_KEY"
chmod 600 "$TEMP_KEY"
ssh-add "$TEMP_KEY"
rm "$TEMP_KEY"
```

### Integration with System SSH Agent

```bash
# Create systemd service for key loading
cat > ~/.config/systemd/user/bitwarden-ssh.service << EOF
[Unit]
Description=Load SSH keys from Bitwarden
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/path/to/retrieve-ssh-key.sh "GitHub"
Environment="BW_SESSION=%i"

[Install]
WantedBy=default.target
EOF

systemctl --user enable bitwarden-ssh.service
```

## Security Comparison

| Feature | GNOME Keyring | 1Password | Bitwarden |
|---------|---------------|-----------|-----------|
| Native SSH Agent | ✅ | ✅ | ❌ |
| Cross-device Sync | ❌ | ✅ | ✅ |
| Biometric Unlock | ✅ | ✅ | ❌ |
| Audit Logs | Basic | Detailed | Basic |
| Cost | Free | Paid | Free/Paid |
| Offline Access | ✅ | ✅ | Limited |
| Integration Complexity | Low | Low | Medium |

## Best Practices

1. **Use Strong Passphrases**: Even with secure storage, use strong passphrases for SSH keys
2. **Regular Key Rotation**: Implement regular key rotation policies
3. **Separate Keys by Purpose**: Use different keys for different services/environments
4. **Enable MFA**: Use multi-factor authentication on secret managers
5. **Monitor Usage**: Regularly review SSH key usage logs
6. **Backup Strategy**: Ensure keys are properly backed up and recoverable
7. **Principle of Least Privilege**: Limit key access to necessary systems only

## Implementation Recommendations

- **Desktop Users**: GNOME Keyring for simplicity and native integration
- **Cross-platform Users**: 1Password for seamless experience across devices
- **Budget-conscious**: Bitwarden with custom scripts for SSH integration
- **Enterprise**: Consider dedicated SSH certificate authorities with short-lived certificates

## Additional Security Measures

### SSH Certificate Authentication

```bash
# Generate SSH certificate (requires CA setup)
ssh-keygen -s ca_key -I "user@company" -n user -V +1d ~/.ssh/id_rsa.pub
```

### Hardware Security Keys

```bash
# Generate key on hardware token
ssh-keygen -t ed25519-sk -C "user@company"
```

### Conditional SSH Configuration

```bash
# ~/.ssh/config with conditional includes
Include config.d/work
Include config.d/personal

Match host *.corp.com
    IdentityAgent ~/.1password/agent.sock
    
Match host github.com
    IdentitiesOnly yes
    IdentityFile ~/.ssh/github_ed25519
```

This spike provides a comprehensive overview of modern SSH private key security practices using various secret management solutions.