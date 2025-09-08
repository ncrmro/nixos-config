# Migrating Ocean from TrueNAS to Nix

## Overview
This spike explores migrating the ocean host from TrueNAS to a NixOS-based configuration.

## Current State
- ocean is currently running TrueNAS
- Need to assess current services and data storage requirements

## Migration Goals
- [ ] Inventory current TrueNAS services and configurations
- [ ] Design NixOS equivalent configuration
- [ ] Plan data migration strategy
- [ ] Test migration process
- [ ] Execute migration

## Service Architecture Considerations

### LAN-Specific Services
Services that are only relevant to the local home network and can remain on the physical ocean host:
- Home Assistant
- AdGuard Home
- Radarr
- Lidarr
- Other local media/automation services

### High Availability Services
Services that should be moved to a highly available Kubernetes setup for digital nomad flexibility (when ocean host may be offline for extended periods):
- Bitwarden
- Personal website
- Git services
- Other externally accessible services that need 24/7 uptime

## Implementation Notes

### K3s Integration
Can use `services.k3s.manifests` to define Kubernetes resources declaratively in NixOS before final switchover:

```nix
services.k3s = {
  enable = true;
  manifests.nginx.content = {
    apiVersion = "helm.cattle.io/v1";
    kind = "HelmChart";
    metadata = {
      name = "nginx";
      namespace = "kube-system"; # Or your target namespace
    };
    spec = {
      targetNamespace = "test"; # Or your target namespace
      createNamespace = true;
      repo = "https://charts.bitnami.com/bitnami";
      chart = "nginx";
      version = "18.3.5"; # Specify the chart version
      # values = { ... }; # Optionally, configure chart values here
    };
  };
};
```

### ZFS PVC
For persistent storage using ZFS:

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: zfs-localpv
  namespace: kube-system
spec:
  repo: https://openebs.github.io/zfs-localpv
  chart: zfs-localpv
  targetNamespace: kube-system
  valuesContent: |-
    analytics:
      enabled: false
    tolerateAllTaints: true
```

Storage classes for different storage tiers on ocean node:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocean-nvme
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
allowVolumeExpansion: true
parameters:
  thinprovision: "no"
  fstype: "zfs"
  poolname: "rpool/kube"
  shared: "yes"
provisioner: zfs.csi.openebs.io
allowedTopologies:
  - matchLabelExpressions:
    - key: kubernetes.io/hostname
      values:
        - ocean
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ocean-hdd
allowVolumeExpansion: true
parameters:
  thinprovision: "no"
  fstype: "zfs"
  poolname: "tank/kube"
  shared: "yes"
provisioner: zfs.csi.openebs.io
allowedTopologies:
  - matchLabelExpressions:
    - key: kubernetes.io/hostname
      values:
        - ocean
```

### Servarr Helm Manifest
Example configuration for installing servarr services with existing PVCs, ingress, and node selector:

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: servarr
  namespace: kube-system
spec:
  repo: https://kubitodev.github.io/helm/
  chart: servarr
  targetNamespace: media
  createNamespace: true
  valuesContent: |-
    # Global node selector for all services
    nodeSelector:
      kubernetes.io/hostname: ocean
    
    # Sonarr Configuration
    sonarr:
      enabled: true
      persistence:
        enabled: true
        existingClaim: sonarr-pvc
        accessMode: ReadWriteOnce
      ingress:
        enabled: true
        className: nginx
        hosts:
          - host: sonarr.local.example.com
            paths:
              - path: /
                pathType: Prefix
      nodeSelector:
        kubernetes.io/hostname: ocean
    
    # Radarr Configuration
    radarr:
      enabled: true
      persistence:
        enabled: true
        existingClaim: radarr-pvc
        accessMode: ReadWriteOnce
      ingress:
        enabled: true
        className: nginx
        hosts:
          - host: radarr.local.example.com

                pathType: Prefix
      nodeSelector:
        kubernetes.io/hostname: ocean
    
    # Lidarr Configuration
    lidarr:
      enabled: true
      persistence:
        enabled: true
        existingClaim: lidarr-pvc
        accessMode: ReadWriteOnce
      ingress:
        enabled: true
        className: nginx
        hosts:
          - host: lidarr.local.example.com
            paths:
              - path: /
                pathType: Prefix
      nodeSelector:
        kubernetes.io/hostname: ocean
    
    # qBittorrent Configuration
    qbittorrent:
      enabled: true
      persistence:
        enabled: true
        existingClaim: qbittorrent-pvc
        accessMode: ReadWriteOnce
      ingress:
        enabled: true
        className: nginx
        hosts:
          - host: qbittorrent.local.example.com
            paths:
              - path: /
                pathType: Prefix
      nodeSelector:
        kubernetes.io/hostname: ocean
    
    # Jellyfin Configuration
    jellyfin:
      enabled: true
      persistence:
        enabled: true
        existingClaim: jellyfin-pvc
        accessMode: ReadWriteOnce
      ingress:
        enabled: true
        className: nginx
        hosts:
          - host: jellyfin.local.example.com
            paths:
              - path: /
                pathType: Prefix
      nodeSelector:
        kubernetes.io/hostname: ocean
```

## Notes
<!-- Add migration notes and findings here -->
