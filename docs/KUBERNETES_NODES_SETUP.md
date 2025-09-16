# Kubernetes Nodes Setup with K3s and Agenix

This document explains how to set up K3s cluster nodes using NixOS with encrypted token management via agenix.

## Overview

Our K3s cluster uses a server/agent architecture with secure token management:
- **Server nodes**: Run the K3s control plane (API server, etcd, scheduler, controller-manager)
- **Agent nodes**: Run kubelet and workloads, connect to server nodes
- **Token security**: Server and agent tokens are separately encrypted and only accessible by appropriate nodes

## Token Architecture

```
┌─────────────────────┐     ┌─────────────────────┐
│   Ocean (Server)    │     │   Maia (Agent)      │
│                     │     │                     │
│ ┌─────────────────┐ │     │ ┌─────────────────┐ │
│ │ Server Token    │ │     │ │ Agent Token     │ │
│ │ (encrypted)     │ │     │ │ (copied from    │ │
│ │                 │ │────▶│ │ ocean server)   │ │
│ └─────────────────┘ │     │ └─────────────────┘ │
└─────────────────────┘     └─────────────────────┘
```

## Secrets Configuration

File: `secrets.nix`

The secrets configuration separates access control between server and agent tokens:

```nix
let
  users = {
    ncrmro = "ssh-ed25519 AAAAC3..."; # Admin SSH key
  };
  
  systems = {
    ocean = "ssh-ed25519 AAAAC3..."; # Server node SSH key
    maia = "ssh-ed25519 AAAAC3...";  # Agent node SSH key
  };

  adminKeys = [users.ncrmro];
  k3sServers = [systems.ocean];  # Only server nodes
  k3sAgents = [systems.maia];    # Only agent nodes
in {
  # Server token - only servers can decrypt
  "secrets/k3s-server-token.age".publicKeys = adminKeys ++ k3sServers;
  
  # Agent token - only agents can decrypt
  "secrets/k3s-agent-token.age".publicKeys = adminKeys ++ k3sAgents;
}
```

## Token Management

### Server Token Setup

The server token is pulled from the first master node after initial setup:

1. **Initial setup** with a custom token:
```bash
# Generate secure server token
openssl rand -hex 32

# Encrypt with agenix (format: K3S10::server:<token>)
echo "K3S10::server:<generated-token>" | agenix -e secrets/k3s-server-token.age
```

2. **Or copy from running server**:
```bash
# Copy server token from ocean
ssh root@ocean.mercury "cat /var/lib/rancher/k3s/server/token" | agenix -e secrets/k3s-server-token.age
```

### Agent Token Setup

Agent tokens are always copied from the server node:

```bash
# Copy agent token directly from ocean server
ssh root@ocean.mercury "cat /var/lib/rancher/k3s/server/agent-token" | agenix -e secrets/k3s-agent-token.age
```

### Re-encrypting Secrets

When adding new nodes or updating access:

```bash
# Update secrets.nix with new node keys
# Then re-encrypt all secrets
agenix -r
```

## Server Node Configuration

File: `hosts/ocean/k3s.nix`

```nix
{pkgs, config, ...}: {
  # Server token secret (only server nodes can decrypt)
  age.secrets.k3s-server-token = {
    file = ../../secrets/k3s-server-token.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.k3s-server-token.path;
    extraFlags = toString [
      "--disable=traefik"
      "--disable=local-storage"
      "--container-runtime-endpoint=/run/containerd/containerd.sock"
      "--tls-san=ocean.mercury"
      "--tls-san=100.64.0.6"  # Headscale IP
      "--node-ip=100.64.0.6"
    ];
  };
}
```

## Agent Node Configuration

File: `hosts/maia/k3s.nix`

```nix
{pkgs, config, ...}: {
  # Agent token secret (only agent nodes can decrypt)
  age.secrets.k3s-agent-token = {
    file = ../../secrets/k3s-agent-token.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.age.secrets.k3s-agent-token.path;
    serverAddr = "https://100.64.0.6:6443";  # Connect to ocean
    extraFlags = toString [
      "--container-runtime-endpoint=/run/containerd/containerd.sock"
      "--node-ip=100.64.0.5"  # Agent's Headscale IP
      "--node-taint=ncrmro.com/region=us-south-2:NoSchedule"
    ];
  };
}
```

## Host Configuration

Both server and agent nodes must import the agenix module:

```nix
# In hosts/{hostname}/default.nix
imports = [
  ../common/optional/agenix.nix
  ./k3s.nix
  # other imports...
];
```

## Adding New Nodes

### Adding a Server Node

1. **Get the new server's SSH public key**:
```bash
ssh-keyscan new-server.mercury | grep ssh-ed25519
```

2. **Update secrets.nix**:
```nix
systems = {
  ocean = "ssh-ed25519 ...";
  new-server = "ssh-ed25519 ...";  # Add new server
  maia = "ssh-ed25519 ...";
};

k3sServers = [systems.ocean systems.new-server];  # Add to servers
```

3. **Re-encrypt secrets**:
```bash
agenix -r
```

4. **Configure the new server** similar to ocean's setup

### Adding an Agent Node

1. **Get the new agent's SSH public key**:
```bash
ssh-keyscan new-agent.mercury | grep ssh-ed25519
```

2. **Update secrets.nix**:
```nix
systems = {
  ocean = "ssh-ed25519 ...";
  maia = "ssh-ed25519 ...";
  new-agent = "ssh-ed25519 ...";  # Add new agent
};

k3sAgents = [systems.maia systems.new-agent];  # Add to agents
```

3. **Re-encrypt secrets**:
```bash
agenix -r
```

4. **Configure the new agent** similar to maia's setup

## Network Configuration

### Headscale Network Layout

```
Ocean (Server):   100.64.0.6:6443
Maia (Agent):     100.64.0.5
Future nodes:     100.64.0.x (assign incrementally)
```

### Required Firewall Rules

**Server nodes**:
- Port 6443 (Kubernetes API)
- Port 10250 (kubelet API)

**Agent nodes**:
- Port 10250 (kubelet API)
- Ports 30000-32767 (NodePort services, if used)

## Node Taints and Labels

### Custom Taints

Agents can be configured with custom taints for workload isolation:

```nix
extraFlags = toString [
  "--node-taint=ncrmro.com/region=us-south-2:NoSchedule"
  "--node-taint=node-type=compute:NoSchedule"
];
```

### Custom Labels

Add labels for node selection:

```nix
extraFlags = toString [
  "--node-label=ncrmro.com/region=us-south-2"
  "--node-label=node-type=compute"
];
```

## Deployment Process

### Initial Cluster Setup

1. **Deploy server node first**:
```bash
./bin/updateOcean
```

2. **Verify server is running**:
```bash
ssh root@ocean.mercury "k3s kubectl get nodes"
```

3. **Copy agent token**:
```bash
ssh root@ocean.mercury "cat /var/lib/rancher/k3s/server/agent-token" | agenix -e secrets/k3s-agent-token.age
```

4. **Deploy agent nodes**:
```bash
./bin/updateMaia
```

### Adding Nodes to Existing Cluster

1. **Update secrets.nix** with new node's SSH key
2. **Re-encrypt secrets**: `agenix -r`
3. **Deploy new node**: `./bin/update<NodeName>`
4. **Verify node joined**: `kubectl get nodes`

## Security Model

### Token Access Control

- **Server tokens**: Only accessible by server nodes and admin
- **Agent tokens**: Only accessible by agent nodes and admin
- **Principle of least privilege**: Nodes only have access to secrets they need

### Network Security

- **Headscale mesh**: All cluster traffic over encrypted mesh network
- **TLS**: API server uses TLS with proper SANs
- **Token rotation**: Tokens can be rotated by updating secrets and deploying

## Troubleshooting

### Verify Token Access

```bash
# Check if node can decrypt its token
ssh root@maia.mercury "test -r /run/agenix/k3s-agent-token && echo 'Agent token accessible'"
ssh root@ocean.mercury "test -r /run/agenix/k3s-server-token && echo 'Server token accessible'"
```

### Check Node Status

```bash
# From any node with kubectl access
kubectl get nodes -o wide
kubectl describe node <nodename>

# Check agent connection
ssh root@maia.mercury "journalctl -u k3s-agent -f"
```

### Token Synchronization

If tokens get out of sync:

1. **Get current tokens from server**:
```bash
ssh root@ocean.mercury "cat /var/lib/rancher/k3s/server/agent-token"
```

2. **Update encrypted secret**:
```bash
ssh root@ocean.mercury "cat /var/lib/rancher/k3s/server/agent-token" | agenix -e secrets/k3s-agent-token.age
```

3. **Redeploy agent nodes**:
```bash
./bin/updateMaia
```

## See Also

- [Agenix Secret Management](./AGENIX_SECRET_MANAGEMENT.md)
- [Kubernetes Modules](./KUBERNETES_MODULES.md)
- [K3s Token Documentation](https://docs.k3s.io/cli/token)