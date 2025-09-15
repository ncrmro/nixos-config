# Agenix K3s Secret Implementation Spike

## Objective

Implement agenix secret management for the ocean host K3s cluster, specifically managing the K3s server token securely to avoid storing secrets in the Nix store.

## Current State

Ocean is currently configured as a K3s server with:
- Role: server
- No explicit token configuration (using default/generated token)
- Running on Tailscale IP 100.64.0.6

## Problem

K3s tokens should be:
1. Consistent across cluster restarts
2. Secure (not stored in Nix store)
3. Shareable with joining nodes

The `services.k3s.tokenFile` option allows us to provide a token from a file that won't be stored in the Nix store.

## Implementation Plan

1. Generate age keys for secret encryption
2. Get ocean host SSH public key for secret access
3. Create a secrets.nix configuration
4. Generate a secure K3s token
5. Encrypt the token using agenix
6. Configure ocean to use the tokenFile option
7. Test the implementation

## Security Considerations

- Token will be encrypted with age using ocean's SSH host key
- Token file will be owned by root with 0400 permissions
- Agenix will decrypt the secret at runtime, not build time

## Files to Create/Modify

- `secrets/secrets.nix` - Define secret access permissions
- `secrets/k3s-server-token.age` - Encrypted K3s token
- `hosts/ocean/k3s.nix` - Add tokenFile configuration
- `hosts/ocean/default.nix` - Import agenix module

## Implementation Steps

See the files in this spike directory for the complete implementation.