# Migration Guide: Upgrading to GNOME Keyring Integration

This guide helps migrate existing NixOS configurations to use the comprehensive GNOME Keyring integration.

## Pre-Migration Checklist

### Backup Current Configuration
- [ ] Backup current NixOS configuration: `cp -r /etc/nixos /etc/nixos.backup`
- [ ] Backup Home Manager configuration
- [ ] Backup existing SSH keys: `cp -r ~/.ssh ~/.ssh.backup`
- [ ] Document current authentication workflows

### Inventory Current Setup
- [ ] List current SSH keys: `ssh-add -l`
- [ ] Note current Docker registry logins: `cat ~/.docker/config.json`
- [ ] Document 1Password/Bitwarden setup if any
- [ ] Check current SSH agent: `echo $SSH_AUTH_SOCK`

## Migration Steps

### Step 1: Update System Configuration

#### For hosts with existing GNOME Keyring
If your host already has basic GNOME Keyring (like `ncrmro-laptop`):

```nix
# In hosts/your-host/default.nix
{
  imports = [
    # ... existing imports
    ../common/optional/gnome-keyring-full.nix  # Add this line
  ];

  # Replace the basic configuration:
  # services.gnome.gnome-keyring.enable = true;
  # security.pam.services.greetd.enableGnomeKeyring = true;
  
  # With the enhanced configuration:
  services.gnome-keyring-full.enable = true;
}
```

#### For hosts without GNOME Keyring
Add the complete configuration:

```nix
# In hosts/your-host/default.nix
{
  imports = [
    # ... existing imports
    ../common/optional/gnome-keyring-full.nix
  ];

  services.gnome-keyring-full.enable = true;
}
```

### Step 2: Update Home Manager Configuration

#### Basic Integration
```nix
# In your Home Manager configuration
{
  imports = [
    # ... existing imports
    ../common/features/security.nix  # Add this line
  ];

  programs.gnome-keyring-integration = {
    enable = true;
    # ssh.enable = true;     # Default: true
    # docker.enable = true;  # Default: true
  };
}
```

#### Full Integration with Password Managers
```nix
programs.gnome-keyring-integration = {
  enable = true;
  passwordManagers = {
    onePassword = true;   # Enable if you use 1Password
    bitwarden = true;     # Enable if you use Bitwarden
  };
};
```

### Step 3: Update SSH Configuration

#### Migrate from existing SSH config
If you have existing SSH configuration:

```nix
# OLD configuration
programs.ssh = {
  enable = true;
  # extraConfig = ''
  #   Host *
  #     IdentityAgent ~/.1password/agent.sock
  # '';
};

# NEW configuration - the module handles this automatically
# Just ensure the integration is enabled
programs.gnome-keyring-integration.ssh.enable = true;
```

#### Keep 1Password SSH agent as option
If you want to keep 1Password SSH agent as an alternative:

```nix
programs.ssh.extraConfig = ''
  # Uncomment to use 1Password SSH agent instead of gnome-keyring
  # Host *
  #   IdentityAgent ~/.1password/agent.sock
'';
```

### Step 4: Migrate Docker Credentials

#### Remove existing credential helpers
```bash
# Backup current config
cp ~/.docker/config.json ~/.docker/config.json.backup

# Remove old credential helpers if any
```

The new configuration will automatically set up `secretservice` as the credential store.

### Step 5: Rebuild and Test

#### Rebuild system
```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

#### Update Home Manager
```bash
home-manager switch --flake .#user@hostname
```

#### Reboot for full initialization
```bash
sudo reboot
```

## Post-Migration Validation

### Verify Services
```bash
# Check GNOME Keyring is running
ps aux | grep gnome-keyring

# Check user services
systemctl --user list-units | grep keyring

# Verify SSH agent
echo $SSH_AUTH_SOCK
ssh-add -l
```

### Re-add SSH Keys
```bash
# Add your SSH keys to the new agent
ssh-add ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_rsa

# Test SSH authentication
ssh -T git@github.com
```

### Migrate Docker Credentials
```bash
# Re-login to Docker registries
docker login
docker login gcr.io
# ... for each registry you use
```

### Setup Password Managers
```bash
# For Bitwarden
bw-keyring-login

# For 1Password
op-keyring-login
```

## Troubleshooting Common Issues

### SSH Agent Not Working
```bash
# Check if SSH_AUTH_SOCK is set correctly
echo $SSH_AUTH_SOCK

# Should be something like: /run/user/1000/keyring/ssh
# If not, logout and login again

# Verify keyring SSH component is enabled
systemctl --user status gnome-keyring-ssh
```

### Docker Credentials Not Saving
```bash
# Check docker config
cat ~/.docker/config.json

# Should contain: "credsStore": "secretservice"

# Test credential helper directly
echo "test" | docker-credential-secretservice store <<< '{"ServerURL":"test.com","Username":"test","Secret":"test"}'
```

### Keyring Not Unlocking Automatically
```bash
# Check PAM configuration
grep -r enableGnomeKeyring /etc/pam.d/

# Verify display manager integration
systemctl status your-display-manager
```

### Password Manager Sessions Not Restoring
```bash
# Check service status
systemctl --user status bitwarden-session-restore
systemctl --user status onepassword-session-restore

# Check service logs
journalctl --user -u bitwarden-session-restore
```

## Rollback Procedure

If you need to rollback:

### Quick Rollback
```bash
# Rollback NixOS configuration
sudo nixos-rebuild switch --rollback

# Rollback Home Manager
home-manager generations
home-manager switch --generation PREVIOUS_GENERATION_NUMBER
```

### Complete Rollback
```bash
# Restore configuration files
sudo cp -r /etc/nixos.backup/* /etc/nixos/

# Restore SSH keys
cp -r ~/.ssh.backup/* ~/.ssh/

# Rebuild with old configuration
sudo nixos-rebuild switch
home-manager switch
```

## Best Practices After Migration

### Security
1. **Change keyring password** to be different from login password
2. **Test recovery procedures** for password managers
3. **Rotate SSH keys** if they were compromised during migration
4. **Review stored secrets** and remove unnecessary ones

### Maintenance
1. **Monitor keyring usage** with `keyring-status`
2. **Regularly update password manager sessions**
3. **Keep backup access methods** for critical services
4. **Document the new workflow** for team members

### Performance
1. **Monitor system startup time** after migration
2. **Check for any authentication delays**
3. **Optimize service startup order** if needed

## Advanced Configuration

### Custom Keyring Settings
```nix
# For specific keyring timeout settings
services.gnome-keyring = {
  enable = true;
  components = [ "pkcs11" "secrets" "ssh" ];
};

# Custom environment in home configuration
home.sessionVariables = {
  # Custom SSH_AUTH_SOCK if needed
  SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
  
  # Keyring-specific settings
  GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
};
```

### Multiple SSH Agents
```nix
# Configure to use different agents for different hosts
programs.ssh.matchBlocks = {
  "work-*" = {
    identityAgent = "~/.1password/agent.sock";
  };
  "*" = {
    identityAgent = "$XDG_RUNTIME_DIR/keyring/ssh";
  };
};
```

## Support and Resources

- **Documentation**: See main README.md in this spike
- **Testing**: Use testing-checklist.md for verification
- **Examples**: Reference example configurations in this directory
- **Community**: NixOS community forums and IRC channels