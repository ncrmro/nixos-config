{...}: {
  services.k3s.autoDeployCharts = {
    # Longhorn Helm Chart: https://artifacthub.io/packages/helm/longhorn/longhorn
    longhorn = {
      name = "longhorn";
      repo = "https://charts.longhorn.io";
      version = "1.8.0";
      hash = "sha256-PLACEHOLDER"; # TODO: Add hash after first deployment
      targetNamespace = "longhorn-system";
      createNamespace = true;
      values = {
        # Longhorn configuration
        persistence = {
          defaultClass = false; # Don't make Longhorn the default storage class
          defaultClassReplicaCount = 3; # Default replica count for new volumes
        };
        
        # Ingress configuration for Longhorn UI
        ingress = {
          enabled = true;
          ingressClassName = "nginx";
          host = "longhorn.ncrmro.com";
          tls = true;
          # Using default ingress-nginx wildcard cert (*.ncrmro.com)
          annotations = {
            "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
            "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true";
          };
        };
        
        # Default settings for Longhorn
        defaultSettings = {
          backupstorePollInterval = "300";
          createDefaultDiskLabeledNodes = false;
          defaultDataPath = "/var/lib/longhorn/";
          defaultDataLocality = "disabled";
          replicaSoftAntiAffinity = false;
          storageOverProvisioningPercentage = "100";
          storageMinimalAvailablePercentage = "25";
          upgradeChecker = false;
          defaultReplicaCount = "3";
          # Resource guarantees for stable performance
          guaranteedEngineManagerCPU = "12";
          guaranteedReplicaManagerCPU = "12";
          # Enable concurrent volume rebuilding for better performance
          concurrentVolumeBackupRestorePerNodeLimit = "5";
          # Disable auto-salvage to prevent data corruption
          autoSalvage = false;
          # Set reasonable timeout for node operations
          nodeDownPodDeletionPolicy = "delete-both-statefulset-and-deployment-pod";
        };
        
        # Resource limits for Longhorn components
        longhornManager = {
          priorityClass = "";
          tolerations = [];
          ## Node selector for manager pods
          # nodeSelector = {
          #   "kubernetes.io/hostname" = "ocean";
          # };
        };
        
        longhornDriver = {
          priorityClass = "";
          tolerations = [];
          ## Node selector for driver pods  
          # nodeSelector = {
          #   "kubernetes.io/hostname" = "ocean";
          # };
        };
        
        longhornUI = {
          priorityClass = "";
          tolerations = [];
          ## Node selector for UI pods
          # nodeSelector = {
          #   "kubernetes.io/hostname" = "ocean";
          # };
        };
      };
    };
  };

  # Longhorn-based storage classes
  services.k3s.manifests = {
    # ReadWriteMany storage class using Longhorn with NFS
    "longhorn-rwx-storage-class".content = {
      apiVersion = "storage.k8s.io/v1";
      kind = "StorageClass";
      metadata = {
        name = "longhorn-rwx";
        annotations = {
          "storageclass.kubernetes.io/is-default-class" = "false";
        };
      };
      provisioner = "driver.longhorn.io";
      allowVolumeExpansion = true;
      reclaimPolicy = "Delete";
      volumeBindingMode = "Immediate";
      parameters = {
        numberOfReplicas = "3";
        staleReplicaTimeout = "2880"; # 48 hours
        fromBackup = "";
        fsType = "ext4";
        dataLocality = "disabled";
        # For RWX, Longhorn creates an NFS server pod
        migratable = "false";
        # NFS options for RWX volumes
        nfsOptions = "vers=4.1,proto=tcp,fsc";
      };
      # Allow RWX access modes
      allowedTopologies = [];
    };
    
    # ReadWriteOnce storage class using Longhorn (for comparison/alternative)
    "longhorn-rwo-storage-class".content = {
      apiVersion = "storage.k8s.io/v1";
      kind = "StorageClass";
      metadata = {
        name = "longhorn-rwo";
        annotations = {
          "storageclass.kubernetes.io/is-default-class" = "false";
        };
      };
      provisioner = "driver.longhorn.io";
      allowVolumeExpansion = true;
      reclaimPolicy = "Delete";
      volumeBindingMode = "Immediate";
      parameters = {
        numberOfReplicas = "3";
        staleReplicaTimeout = "2880"; # 48 hours
        fromBackup = "";
        fsType = "ext4";
        dataLocality = "disabled";
      };
    };
    
    # High-performance single replica storage class for non-critical data
    "longhorn-fast-storage-class".content = {
      apiVersion = "storage.k8s.io/v1";
      kind = "StorageClass";
      metadata = {
        name = "longhorn-fast";
        annotations = {
          "storageclass.kubernetes.io/is-default-class" = "false";
        };
      };
      provisioner = "driver.longhorn.io";
      allowVolumeExpansion = true;
      reclaimPolicy = "Delete";
      volumeBindingMode = "Immediate";
      parameters = {
        numberOfReplicas = "1";
        staleReplicaTimeout = "2880"; # 48 hours
        fromBackup = "";
        fsType = "ext4";
        dataLocality = "best-effort";
      };
    };
  };
}