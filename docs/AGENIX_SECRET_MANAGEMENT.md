# Agenix Secret Management

This document explains how to use agenix for secret management in this NixOS configuration.

## Overview

Agenix is a tool for managing secrets in Nix configurations using age encryption. Secrets are encrypted with age public keys and can be decrypted by systems that have the corresponding private keys.

## Setup

### 1. Generate Age Keys

First, generate your personal age key:

```bash
mkdir -p ~/.config/age
age-keygen -o ~/.config/age/keys.txt
```

Get your public key (you'll need this for `secrets/secrets.nix`):

```bash
age-keygen -y ~/.config/age/keys.txt
```

### 2. Get Host SSH Public Keys

For each host that needs access to secrets, get their SSH public key:

```bash
# For remote hosts
ssh-keyscan <hostname-or-ip> | grep ssh-ed25519

# For local host
cat /etc/ssh/ssh_host_ed25519_key.pub
```

### 3. Configure secrets.nix

Update `/secrets/secrets.nix` with your actual public keys:

```nix
let
  users = {
    ncrmro = "age1abc123..."; # Your age public key
  };
  
  systems = {
    ocean = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."; # Host SSH public key
    workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...";
  };

  adminKeys = [users.ncrmro];
  k3sNodes = [systems.ocean systems.workstation];
in
{
  "k3s-join-token.age".publicKeys = adminKeys ++ k3sNodes;
  "github-pat.age".publicKeys = adminKeys ++ [systems.workstation];
}
```

## Creating Secrets

### Method 1: Using agenix CLI

```bash
# Create/edit a secret
agenix -e secrets/k3s-join-token.age

# This opens your $EDITOR to input the secret content
```

### Method 2: Using echo and agenix

```bash
# Create secret from command line
echo "your-secret-value" | agenix -e secrets/k3s-join-token.age
```

### Method 3: Using age directly

```bash
# Encrypt a file directly with age
echo "your-secret" | age -a -R <(echo "age1abc123...") > secrets/mysecret.age
```

## Using Secrets in NixOS Configurations

### 1. Import agenix module

In your host configuration, ensure agenix is imported:

```nix
{
  imports = [
    ../common/optional/agenix.nix
  ];
}
```

### 2. Define secrets

```nix
{
  # Define the secret file location
  age.secrets.k3s-join-token = {
    file = ../../../secrets/k3s-join-token.age;
    # Optional: customize ownership and permissions
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
```

### 3. Use secrets in services

```nix
{
  services.k3s = {
    enable = true;
    # Reference the decrypted secret path
    tokenFile = config.age.secrets.k3s-join-token.path;
  };
}
```

## Common Patterns

### K3s Cluster Secrets

For K3s clusters, typically you need:

```nix
{
  age.secrets = {
    k3s-join-token.file = ../../../secrets/k3s-join-token.age;
    k3s-server-token.file = ../../../secrets/k3s-server-token.age;
  };

  services.k3s = {
    enable = true;
    role = "server"; # or "agent"
    tokenFile = config.age.secrets.k3s-join-token.path;
    serverAddr = "https://k3s-server:6443"; # for agents
  };
}
```

### Application Secrets

For applications needing API tokens:

```nix
{
  age.secrets.github-pat = {
    file = ../../../secrets/github-pat.age;
    owner = "myapp";
    group = "myapp";
  };

  systemd.services.myapp = {
    serviceConfig = {
      EnvironmentFile = config.age.secrets.github-pat.path;
    };
  };
}
```

## File Structure

```
secrets/
├── secrets.nix          # Defines which keys can decrypt which secrets
├── k3s-join-token.age   # Encrypted K3s join token
├── github-pat.age       # Encrypted GitHub personal access token
└── other-secret.age     # Other encrypted secrets
```

## Security Considerations

1. **Key Distribution**: Age private keys should never be committed to the repository
2. **Host Keys**: Use SSH host keys for system access to avoid manual key distribution
3. **Principle of Least Privilege**: Only grant access to secrets for hosts/users that need them
4. **Backup Keys**: Consider having multiple admin keys for recovery scenarios

## Troubleshooting

### Secret not accessible

If a service can't access a secret:

1. Check that the host's SSH public key is in `secrets.nix`
2. Verify the secret file exists and is properly encrypted
3. Ensure the agenix module is imported
4. Check file permissions and ownership

### Re-encrypting secrets

If you need to change which keys can access a secret:

1. Update `secrets/secrets.nix`
2. Re-encrypt the secret: `agenix -r secrets/mysecret.age`

### Viewing secret content

```bash
# Decrypt and view secret content
agenix -d secrets/k3s-join-token.age
```

## Commands Reference

```bash
# Create/edit secret
agenix -e secrets/mysecret.age

# View/decrypt secret
agenix -d secrets/mysecret.age

# Re-encrypt all secrets (after updating secrets.nix)
agenix -r

# List all secrets
ls secrets/*.age
```