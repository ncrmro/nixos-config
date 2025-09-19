# Longhorn Storage Configuration

This document describes the Longhorn distributed storage system configuration for the Kubernetes cluster.

## Overview

Longhorn provides distributed block storage for Kubernetes with support for:
- ReadWriteMany (RWX) volumes via NFS
- ReadWriteOnce (RWO) volumes for high-performance workloads
- Volume snapshots and backups
- Web-based management UI

## Storage Classes

### longhorn-rwx
- **Access Mode**: ReadWriteMany (RWX)
- **Replicas**: 3
- **Use Case**: Shared storage for multiple pods (logs, shared files, etc.)
- **Implementation**: Creates NFS server pods for multi-node access

### longhorn-rwo  
- **Access Mode**: ReadWriteOnce (RWO)
- **Replicas**: 3
- **Use Case**: Database storage, application data
- **Implementation**: Direct block storage attachment

### longhorn-fast
- **Access Mode**: ReadWriteOnce (RWO)
- **Replicas**: 1
- **Use Case**: Cache, temporary data, non-critical workloads
- **Implementation**: Single replica for maximum performance

## Configuration

The Longhorn Helm chart is deployed via NixOS configuration in `/hosts/common/kubernetes/longhorn.nix`:

```nix
services.k3s.autoDeployCharts = {
  longhorn = {
    name = "longhorn";
    repo = "https://charts.longhorn.io";
    version = "1.8.0";
    targetNamespace = "longhorn-system";
    createNamespace = true;
    # ... values configuration
  };
};
```

## Web UI Access

The Longhorn UI is accessible at: https://longhorn.ncrmro.com

Features available in the UI:
- Volume management and monitoring
- Node and disk management  
- Backup and snapshot operations
- System settings and health status

## Example Usage

### ReadWriteMany PVC Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: longhorn-rwx
```

### ReadWriteOnce PVC Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-storage
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: longhorn-rwo
```

## Requirements

- Kubernetes cluster with multiple nodes for replication
- Sufficient disk space on cluster nodes (default path: `/var/lib/longhorn/`)
- Open ports for Longhorn communication between nodes
- NFS support for RWX volumes (automatically handled by Longhorn)

## Backup and Recovery

Longhorn supports:
- Volume snapshots for point-in-time recovery
- Cross-cluster backup to S3-compatible storage
- Volume cloning and restoration
- Disaster recovery scenarios

Configure backup targets in the Longhorn UI or via settings in the Helm values.

## Monitoring

Longhorn integrates with Prometheus for monitoring:
- Volume health and performance metrics
- Node and disk utilization
- Backup status and history
- Alert definitions for storage issues

Metrics are automatically discovered by the kube-prometheus-stack deployment.