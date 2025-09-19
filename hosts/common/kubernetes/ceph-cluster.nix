{...}: {
  services.k3s.manifests = {
    "ceph-cluster".content = {
      apiVersion = "ceph.rook.io/v1";
      kind = "CephCluster";
      metadata = {
        name = "zfs-nvme";
        namespace = "rook-ceph";
      };
      spec = {
        cephVersion = {
          image = "quay.io/ceph/ceph:v18.2.4";
          allowUnsupported = false;
        };
        dataDirHostPath = "/var/lib/rook";
        skipUpgradeChecks = false;
        continueUpgradeAfterChecksEvenIfNotHealthy = false;
        waitTimeoutForHealthyOSDInMinutes = 10;

        mon = {
          count = 2;
          allowMultiplePerNode = false;
        };

        mgr = {
          count = 2;
          allowMultiplePerNode = false;
        };

        dashboard = {
          enabled = true;
          ssl = true;
        };

        monitoring = {
          enabled = true;
          createPrometheusRules = true;
        };

        network = {
          connections = {
            encryption = {
              enabled = false;
            };
            compression = {
              enabled = false;
            };
          };
        };

        crashCollector = {
          disable = false;
        };

        logCollector = {
          enabled = true;
          periodicity = "daily";
          maxLogSize = "500M";
        };

        cleanupPolicy = {
          confirmation = "";
          sanitizeDisks = {
            method = "quick";
            dataSource = "zero";
            iteration = 1;
          };
          allowUninstallWithVolumes = false;
        };

        # Configure tolerations for maia node taint
        placement = {
          all = {
            tolerations = [
              {
                key = "ncrmro.com/region";
                operator = "Equal";
                value = "us-south-2";
                effect = "NoSchedule";
              }
            ];
          };
        };

        # Object Storage Daemon (OSD) Configuration
        #
        # An OSD is a Ceph daemon that:
        # 1. Stores actual data on physical storage devices (disks, PVs, etc.)
        # 2. Handles data replication across the cluster for redundancy
        # 3. Performs data recovery and rebalancing when nodes join/leave
        # 4. Manages object placement and retrieval operations
        #
        # In our setup:
        # - Each OSD gets a PVC from the zfs-nvme StorageClass
        # - OSDs run as pods on Kubernetes nodes (ocean, maia)
        # - Starting with 1 OSD per node for initial setup
        # - Ceph automatically distributes data across all available OSDs
        storage = {
          useAllNodes = true;
          useAllDevices = false;
          storageClassDeviceSets = [
            {
              name = "zfs-nvme-set";
              count = 1; # One OSD per node
              portable = false;
              tuneDeviceClass = true;
              tuneFastDeviceClass = false;
              encrypted = false;
              volumeClaimTemplates = [
                {
                  metadata = {
                    name = "data";
                  };
                  spec = {
                    accessModes = ["ReadWriteOnce"];
                    storageClassName = "zfs-nvme-block";
                    volumeMode = "Block";
                    resources = {
                      requests = {
                        storage = "100Gi";
                      };
                    };
                  };
                }
              ];
            }
          ];
        };

        # disruptionManagement = {
        #   managePodBudgets = true;
        #   osdMaintenanceTimeout = 30;
        #   pgHealthCheckTimeout = 0;
        # };

        # healthCheck = {
        #   daemonHealth = {
        #     mon = {
        #       interval = "45s";
        #     };
        #     osd = {
        #       interval = "60s";
        #     };
        #     status = {
        #       interval = "60s";
        #     };
        #   };
        # };
      };
    };
  };
}
