# Working Examples for GNOME Keyring Integration

This directory contains working examples and configuration templates for integrating GNOME Keyring with various authentication systems.

## Files

- `example-host-config.nix` - Complete host configuration example
- `example-home-config.nix` - Home Manager configuration example  
- `migration-guide.md` - Guide for migrating existing configurations
- `testing-checklist.md` - Comprehensive testing checklist

## Quick Start

### For a new host with full integration:

```nix
# In your host configuration (e.g., hosts/my-laptop/default.nix)
{
  imports = [
    ../common/optional/gnome-keyring-full.nix
    # ... other imports
  ];
  
  services.gnome-keyring-full.enable = true;
}
```

### For Home Manager with all features:

```nix
# In your Home Manager configuration
{
  imports = [
    ../common/features/security.nix
    # ... other imports
  ];
  
  programs.gnome-keyring-integration = {
    enable = true;
    passwordManagers = {
      onePassword = true;
      bitwarden = true;
    };
  };
}
```

## Security Recommendations

1. **Test in a VM first** before deploying to production systems
2. **Back up existing SSH keys** before migrating
3. **Use different keyring passwords** for sensitive environments
4. **Verify all integrations work** before relying on them