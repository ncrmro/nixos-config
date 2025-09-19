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

## Disaster Recovery

This section covers disaster recovery scenarios and procedures for Longhorn storage.

### Node Removal/Failure

When a node hosting Longhorn storage needs to be removed or fails completely:

#### Planned Node Removal
1. **Drain the node** to move workloads to other nodes:
   ```bash
   kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
   ```

2. **Wait for replica rebuilding** - Longhorn automatically rebuilds replicas on remaining healthy nodes. Monitor progress in the Longhorn UI under "Volume" → "Replica" tab.

3. **Verify volume health** - Ensure all volumes show "Healthy" status before proceeding:
   ```bash
   kubectl get volumes -n longhorn-system
   ```

4. **Remove node from cluster**:
   ```bash
   kubectl delete node <node-name>
   ```

#### Unplanned Node Failure
1. **Longhorn automatically detects** node failure and marks replicas as "Failed"
2. **Volume remains accessible** if sufficient healthy replicas exist (typically 2 out of 3)
3. **Automatic rebuild** starts on available nodes with sufficient space
4. **Monitor rebuild progress** in Longhorn UI or via CLI:
   ```bash
   kubectl get replicas -n longhorn-system -o wide
   ```

#### Recovery Time Objectives
- **RTO (Recovery Time Objective)**: Volume access typically restored within 2-5 minutes
- **RPO (Recovery Point Objective)**: Zero data loss with healthy replicas
- **Rebuild time**: Varies by volume size and network bandwidth (typically 1-10GB per hour)

### Data Recovery Procedures

#### Volume Recovery from Snapshots
1. **Create volume from snapshot**:
   - Navigate to Longhorn UI → "Snapshot" tab
   - Select desired snapshot and click "Create Volume"
   - Specify new volume name and size

2. **Restore data to existing volume**:
   ```bash
   # Create PVC from restored volume
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: restored-pvc
     namespace: default
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 20Gi
     storageClassName: longhorn-rwo
     volumeName: <restored-volume-name>
   EOF
   ```

#### Cross-Cluster Recovery
1. **Configure backup target** in Longhorn settings (S3-compatible storage)
2. **Create backup from source cluster**:
   - Longhorn UI → "Volume" → "Create Backup"
3. **Restore in destination cluster**:
   - Longhorn UI → "Backup" → "Restore Latest Backup"

#### Data Integrity Verification
- **Volume health checks**: Longhorn performs automatic integrity checks
- **Manual verification**:
  ```bash
  # Check volume status
  kubectl get volumes -n longhorn-system <volume-name> -o yaml
  
  # Verify replica consistency
  kubectl get replicas -n longhorn-system -l longhornvolume=<volume-name>
  ```

### Replica Management

#### Best Practices for Planned Maintenance
1. **Increase replica count** before maintenance:
   ```bash
   # Temporarily increase to 4 replicas
   kubectl patch volume <volume-name> -n longhorn-system --type='merge' -p='{"spec":{"numberOfReplicas":4}}'
   ```

2. **Wait for new replica** to become healthy
3. **Perform maintenance** on target node
4. **Restore original replica count** after maintenance

#### Handling Replica Failures
1. **Automatic detection** - Longhorn monitors replica health continuously
2. **Failed replica replacement**:
   - Longhorn automatically creates new replicas on healthy nodes
   - Old failed replicas are marked for cleanup
3. **Manual intervention** may be required if:
   - Insufficient nodes available for replica placement
   - Storage space constraints on remaining nodes

#### Replica Placement Rules
- **Anti-affinity**: Replicas are distributed across different nodes by default
- **Zone awareness**: Configure node labels for rack/zone awareness:
  ```bash
  kubectl label nodes <node-name> topology.kubernetes.io/zone=<zone-name>
  ```
- **Storage class settings**: Specify replica placement in storage class parameters

### Backup and Restore Strategies

#### Automated Backup Configuration
1. **Configure S3-compatible backup target**:
   ```yaml
   # In longhorn.nix values section
   defaultSettings = {
     backupTarget = "s3://bucket-name@region/backup-folder/";
     backupTargetCredentialSecret = "longhorn-backup-secret";
   };
   ```

2. **Create backup credentials secret**:
   ```bash
   kubectl create secret generic longhorn-backup-secret \
     -n longhorn-system \
     --from-literal=AWS_ACCESS_KEY_ID=<access-key> \
     --from-literal=AWS_SECRET_ACCESS_KEY=<secret-key>
   ```

3. **Schedule recurring backups**:
   ```yaml
   # Create recurring job
   apiVersion: longhorn.io/v1beta2
   kind: RecurringJob
   metadata:
     name: daily-backup
     namespace: longhorn-system
   spec:
     cron: "0 2 * * *"  # Daily at 2 AM
     task: "backup"
     groups: ["default"]
     retain: 7  # Keep 7 days of backups
   ```

#### Recovery Procedures
1. **List available backups**:
   ```bash
   kubectl get backups -n longhorn-system
   ```

2. **Restore from backup**:
   - Longhorn UI → "Backup" tab → Select backup → "Restore"
   - Specify new volume name and storage class

3. **Cross-cluster disaster recovery**:
   - Install Longhorn on destination cluster
   - Configure same backup target
   - Restore volumes from backup repository

#### Backup Verification
- **Automated testing**: Schedule test restores to verify backup integrity
- **Backup monitoring**: Set up alerts for failed backup operations
- **Storage usage**: Monitor backup storage consumption and retention policies

### Emergency Procedures

#### Complete Cluster Failure
1. **Rebuild cluster** with same node names and Longhorn configuration
2. **Restore from backups**:
   - Configure backup target in new cluster
   - Restore critical volumes first (databases, persistent data)
   - Restore application volumes as needed

#### Split-Brain Scenarios
- **Prevention**: Ensure odd number of replicas (3, 5, etc.)
- **Detection**: Monitor for volumes with conflicting replica states
- **Resolution**: Use Longhorn UI to select authoritative replica and rebuild others

#### Data Corruption
1. **Identify corruption** through application errors or health checks
2. **Stop affected workloads** immediately
3. **Restore from latest known-good snapshot or backup**
4. **Investigate root cause** (hardware, network, or software issues)

### Testing and Validation

#### Disaster Recovery Testing
- **Monthly node failure simulation**: Deliberately drain and remove nodes
- **Quarterly backup restore testing**: Restore volumes in isolated environment
- **Annual full DR exercise**: Complete cluster rebuild from backups

#### Monitoring and Alerting
- **Volume health alerts**: Configure Prometheus alerts for degraded volumes
- **Backup failure alerts**: Monitor backup job success/failure
- **Node capacity alerts**: Alert when nodes approach storage limits
- **Replica placement alerts**: Notify when replicas cannot be placed optimally

### Documentation and Runbooks
- **Maintain incident response procedures** for common failure scenarios
- **Document cluster-specific configurations** (node topology, storage layout)
- **Keep backup credentials and access procedures** in secure, accessible location
- **Regular review and update** of disaster recovery procedures