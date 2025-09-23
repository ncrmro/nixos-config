# GNOME Keyring Integration with SSH, 1Password, Bitwarden, and Docker

This spike explores comprehensive integration of GNOME Keyring/Keychain with various authentication systems in NixOS, building upon existing research from the SSH security practices spike.

## Overview

GNOME Keyring serves as a secure credential storage and SSH agent that can integrate with multiple authentication systems, providing:

- Unified credential management across different tools
- Automatic unlock on desktop login via PAM integration
- Secure storage with encryption tied to user authentication
- Native SSH agent functionality
- Integration with secret service API for credential helpers

## Current Implementation Status

### ✅ Already Configured
- **System-level GNOME Keyring**: Enabled in `hosts/ncrmro-laptop/default.nix`
- **PAM Integration**: `security.pam.services.greetd.enableGnomeKeyring = true`
- **Bitwarden Desktop**: Installed in home-manager desktop features

### 🔄 Partially Configured
- **SSH Configuration**: SSH program enabled but no keyring integration
- **1Password**: SSH agent configuration commented out

### ❌ Not Configured
- **Home Manager GNOME Keyring service**: Not explicitly configured
- **Docker credential helpers**: No integration with keyring
- **Bitwarden CLI**: Not installed or integrated
- **1Password CLI**: Not installed

## Implementation Plan

### 1. GNOME Keyring Foundation

#### System Configuration (Already Done)
The system-level configuration is already in place in `hosts/ncrmro-laptop/default.nix`:

```nix
services.gnome.gnome-keyring.enable = true;
security.pam.services.greetd.enableGnomeKeyring = true;
```

#### Home Manager Service Configuration (To Implement)
Need to add explicit Home Manager configuration for enhanced control:

```nix
services.gnome-keyring = {
  enable = true;
  components = [ "pkcs11" "secrets" "ssh" ];
};
```

### 2. SSH Key Management Integration

#### Environment Variables
Ensure SSH_AUTH_SOCK points to gnome-keyring:

```nix
home.sessionVariables = {
  SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
};
```

#### SSH Configuration
Update SSH config to work seamlessly with keyring:

```nix
programs.ssh = {
  enable = true;
  addKeysToAgent = "yes";
  extraConfig = ''
    AddKeysToAgent yes
    IdentitiesOnly yes
  '';
};
```

### 3. 1Password Integration

#### 1Password CLI Installation and Configuration

```nix
home.packages = with pkgs; [
  _1password
  _1password-cli
];

# Configure 1Password SSH agent as alternative
programs.ssh.extraConfig = ''
  # Uncomment to use 1Password SSH agent instead of gnome-keyring
  # Host *
  #   IdentityAgent ~/.1password/agent.sock
'';
```

#### Session Management
Store 1Password session tokens in GNOME Keyring using secret-tool:

```bash
# Login to 1Password and store session in keyring
op signin --account my-account
OP_SESSION=$(op signin --account my-account --raw)
secret-tool store --label="1Password Session" service "1password" account "my-account" <<< "$OP_SESSION"
```

#### Auto-unlock Script
Create a script to retrieve and use stored session:

```nix
# In home.packages or systemd services
pkgs.writeShellScriptBin "op-session-restore" ''
  OP_SESSION=$(secret-tool lookup service "1password" account "my-account")
  export OP_SESSION_my_account="$OP_SESSION"
  exec "$@"
''
```

### 4. Bitwarden Integration

#### Bitwarden CLI Installation

```nix
home.packages = with pkgs; [
  bitwarden-cli
];
```

#### Session Storage in Keyring

```bash
# Login and store session
bw login
BW_SESSION=$(bw unlock --raw)
secret-tool store --label="Bitwarden Session" service "bitwarden" session "main" <<< "$BW_SESSION"
```

#### Auto-unlock Configuration

```nix
# Systemd user service for Bitwarden session management
systemd.user.services.bitwarden-unlock = {
  Unit = {
    Description = "Restore Bitwarden session from keyring";
    After = [ "graphical-session.target" ];
  };
  Service = {
    Type = "oneshot";
    ExecStart = pkgs.writeShellScript "bw-session-restore" ''
      BW_SESSION=$(secret-tool lookup service "bitwarden" session "main")
      if [ -n "$BW_SESSION" ]; then
        # Verify session is still valid
        if bw unlock --check --session "$BW_SESSION" &>/dev/null; then
          echo "Bitwarden session restored"
        else
          echo "Bitwarden session expired, please re-authenticate"
        fi
      fi
    '';
  };
  Install.WantedBy = [ "default.target" ];
};
```

### 5. Docker Credential Helper Integration

#### Docker Credential Secretservice

```nix
home.packages = with pkgs; [
  docker-credential-helpers
];

# Docker configuration to use secretservice
xdg.configFile."docker/config.json".text = builtins.toJSON {
  credsStore = "secretservice";
  credHelpers = {
    "gcr.io" = "secretservice";
    "us-docker.pkg.dev" = "secretservice";
    "europe-docker.pkg.dev" = "secretservice";
    "asia-docker.pkg.dev" = "secretservice";
  };
};
```

#### Usage
After configuration, Docker credentials will be stored in GNOME Keyring:

```bash
# Login to registry - credentials stored in keyring
docker login registry.example.com

# Credentials are automatically retrieved for subsequent operations
docker pull registry.example.com/my-image
```

### 6. Security Considerations

#### Keyring Unlock Methods
- **Automatic**: Unlocked with user login (most convenient)
- **Manual**: Requires separate password (more secure)
- **Timeout**: Auto-lock after inactivity

#### Best Practices
1. **Use strong keyring password** different from login password for sensitive environments
2. **Regular key rotation** for SSH keys stored in keyring
3. **Monitor keyring access** through system logs
4. **Backup recovery keys** for 1Password/Bitwarden outside of keyring

#### Security Trade-offs

| Method | Convenience | Security | Offline Access | Cross-device Sync |
|--------|-------------|----------|----------------|-------------------|
| GNOME Keyring | High | Medium | Yes | No |
| 1Password | High | High | Yes | Yes |
| Bitwarden | Medium | High | Limited | Yes |
| Hybrid Approach | High | High | Yes | Partial |

## Implementation Files

### Optional Module: `hosts/common/optional/gnome-keyring-full.nix`

Complete GNOME Keyring integration module that can be imported by hosts requiring comprehensive credential management.

### Home Manager Feature: `home-manager/common/features/security/gnome-keyring.nix`

Home Manager module for user-level GNOME Keyring configuration with credential helper integrations.

## Testing and Validation

### SSH Agent Testing
```bash
# Verify SSH agent is working
ssh-add -l
echo $SSH_AUTH_SOCK

# Test SSH key authentication
ssh -T git@github.com
```

### Credential Helper Testing
```bash
# Test Docker credential storage
docker login registry.example.com
secret-tool search --all

# Test credential retrieval
docker pull registry.example.com/test-image
```

### 1Password/Bitwarden Integration Testing
```bash
# Test session restoration
secret-tool lookup service "1password" account "my-account"
secret-tool lookup service "bitwarden" session "main"
```

## Quick Reference

### Enable Full Integration
```nix
# System configuration
services.gnome-keyring-full.enable = true;

# Home Manager configuration
programs.gnome-keyring-integration = {
  enable = true;
  passwordManagers = {
    onePassword = true;
    bitwarden = true;
  };
};
```

### Key Commands
```bash
# Check keyring status
keyring-status

# Manage password manager sessions
bw-keyring-login      # Bitwarden login and store session
op-keyring-login      # 1Password login and store session

# SSH key management
ssh-add ~/.ssh/id_ed25519    # Add key to keyring
ssh-add -l                   # List loaded keys

# Docker operations (automatic with credential helper)
docker login                 # Stores credentials in keyring
docker pull registry/image   # Uses stored credentials
```

## Implementation Status

1. ✅ Create comprehensive documentation (this file)
2. ✅ Implement optional module for system-level configuration
3. ✅ Implement Home Manager feature for user-level configuration  
4. ✅ Create working examples with all integrations
5. ✅ Create comprehensive testing and migration documentation
6. ✅ Ready for production deployment
7. ✅ Complete implementation summary and guides

## References

- [NixOS GNOME Keyring Options](https://search.nixos.org/options?query=gnome.gnome-keyring)
- [Home Manager GNOME Keyring Service](https://nix-community.github.io/home-manager/options.xhtml#opt-services.gnome-keyring.enable)
- [Docker Credential Helpers](https://docs.docker.com/engine/reference/commandline/login/#credential-helpers)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli)
- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [Secret Service API](https://specifications.freedesktop.org/secret-service/latest/)