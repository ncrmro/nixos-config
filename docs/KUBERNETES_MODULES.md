# Kubernetes Modules Documentation

This document explains how the Kubernetes modules are structured and work within the NixOS configuration.

## Overview

The Kubernetes configuration is organized using NixOS modules that leverage k3s's `autoDeployCharts` feature to automatically deploy Helm charts during system boot/rebuild.

## Structure

```
hosts/common/kubernetes/
├── default.nix              # Main module that imports all components
├── cert-manager.nix          # Certificate management
├── ingress-nginx.nix         # Ingress controller (kube-system namespace)
├── kube-prometheus-stack.nix # Monitoring stack (monitoring namespace)
├── loki.nix                  # Log aggregation
├── longhorn.nix              # Distributed storage system (longhorn-system namespace)
└── zfs-localpv.nix          # ZFS storage provisioner (kube-system namespace)
```

## How it Works

### k3s autoDeployCharts

The modules use NixOS's `services.k3s.autoDeployCharts` option to declaratively manage Helm chart deployments. Each chart configuration includes:

- `name`: Chart name
- `repo`: Helm repository URL
- `version`: Specific chart version
- `hash`: Nix hash for reproducible builds
- `targetNamespace`: Kubernetes namespace for deployment
- `createNamespace`: Whether to create the namespace if it doesn't exist
- `values`: Helm values for customization

### Example Configuration

```nix
services.k3s.autoDeployCharts = {
  ingress-nginx = {
    name = "ingress-nginx";
    repo = "https://kubernetes.github.io/ingress-nginx";
    version = "4.13.2";
    hash = "sha256-5rZUCUQ1AF6GBa+vUbko3vMhinZ7tsnJC5p/JiKllTo=";
    targetNamespace = "kube-system";
    createNamespace = false;
    values = {
      controller = {
        service = {
          type = "LoadBalancer";
        };
        watchIngressWithoutClass = true;
        ingressClassResource = {
          name = "nginx";
          enabled = true;
          default = true;
        };
      };
    };
  };
};
```

## Deployed Components

### Core Infrastructure (kube-system namespace)
- **ingress-nginx**: HTTP/HTTPS ingress controller with LoadBalancer service
- **zfs-localpv**: ZFS-based local persistent volume provisioner

### Monitoring (monitoring namespace)
- **kube-prometheus-stack**: Complete monitoring solution including:
  - Prometheus server with 90-day retention
  - Grafana with persistent storage
  - Alertmanager with persistent storage
  - All using `ocean-nvme` storage class

### Certificate Management
- **cert-manager**: Automated TLS certificate management

### Logging
- **loki**: Log aggregation and storage

### Distributed Storage (longhorn-system namespace)
- **longhorn**: Distributed block storage for Kubernetes
  - Provides ReadWriteMany (RWX) and ReadWriteOnce (RWO) storage classes
  - Web UI accessible at `longhorn.ncrmro.com`
  - Multiple storage classes:
    - `longhorn-rwx`: Multi-node read/write access with 3 replicas
    - `longhorn-rwo`: Single-node access with 3 replicas
    - `longhorn-fast`: Single-replica for non-critical workloads

## Storage Classes

The configuration uses custom storage classes:
- `ocean-nvme`: High-performance storage for monitoring components
- `longhorn-rwx`: ReadWriteMany storage using Longhorn distributed storage
- `longhorn-rwo`: ReadWriteOnce storage using Longhorn distributed storage  
- `longhorn-fast`: High-performance single-replica storage for non-critical data
- ZFS LocalPV provides additional storage options

## Host Integration

To use these Kubernetes modules on a host:

1. Import the kubernetes module in your host configuration:
   ```nix
   imports = [
     ../common/kubernetes
     # other imports...
   ];
   ```

2. Ensure k3s is properly configured with containerd and ZFS support (see `hosts/ocean/k3s.nix`)

## Customization

Each component can be customized by modifying the `values` section in their respective `.nix` files. The values follow the same structure as Helm values files.

## Update Process

When running `bin/updateOcean` (or similar update scripts), the process:

1. Rebuilds the NixOS configuration
2. k3s automatically deploys/updates the configured charts
3. Downloads and configures the kubeconfig for local access

## Registry Mirroring

K3s is configured with distributed OCI registry mirroring using the `--embedded-registry` flag and wildcard mirroring configuration. This enables:

- Peer-to-peer image sharing between cluster nodes
- Reduced bandwidth usage for image pulls
- Improved deployment speed for frequently used images

**Known Issue**: Registry mirroring may fail with kernel module warnings:
```
time="2025-09-16T01:32:11-05:00" level=warning msg="Failed to load kernel module nft-expr-counter with modprobe"
```
This indicates missing netfilter kernel modules but typically doesn't prevent functionality.

**Configuration**: 
- TCP port 5001 opened for peer-to-peer communication
- TCP port 6443 for API server access
- Wildcard registry mirror (`"*"`) configured in `/etc/rancher/k3s/registries.yaml`

## TLS Configuration

k3s is configured with TLS SANs for both hostname and IP access:
- `--tls-san=ocean.mercury`
- `--tls-san=100.64.0.6`

This ensures the API server certificate is valid for both local and remote access.