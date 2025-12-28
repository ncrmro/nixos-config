# Rook Ceph Operator and Cluster
# https://artifacthub.io/packages/helm/rook/rook-ceph
# https://artifacthub.io/packages/helm/rook/rook-ceph-cluster
{
  pkgs,
  config,
  lib,
  ...
}:
{
  # Install Ceph client tools for Rook Ceph
  environment.systemPackages = [
    pkgs.ceph-client # For Rook Ceph cluster management
  ];

  # Load kernel modules for Rook Ceph
  boot.kernelModules = [
    "rbd"
    "nbd"
    "ceph"
  ];

  # Fix containerd LimitNOFILE for Rook Ceph
  systemd.services.containerd.serviceConfig = {
    LimitNOFILE = lib.mkForce null;
  };

  # Only deploy Helm charts on K3s server nodes
  services.k3s.autoDeployCharts =
    lib.mkIf (config.services.k3s.enable && config.services.k3s.role == "server")
      {
        # Rook Ceph Operator
        rook-ceph-operator = {
          name = "rook-ceph";
          repo = "https://charts.rook.io/release";
          version = "v1.18.2";
          hash = "sha256-+zsKqkzW4bnInWKHvCwLuMb08lJf3Q/g009/JV//mDM=";
          targetNamespace = "rook-ceph";
          createNamespace = true;
          values = {
            # Enable monitoring
            monitoring = {
              enabled = true;
            };

            # Configure node affinity for the operator
            nodeSelector = { };

            # Configure tolerations for the main operator
            tolerations = [ ];

            # Resource requests and limits for the operator
            resources = {
              limits = {
                memory = "512Mi";
              };
              requests = {
                cpu = "100m";
                memory = "128Mi";
              };
            };

            # Enable admission controller
            admissionController = {
              tolerations = [ ];
            };

            # Configure CSI settings
            csi = {
              enableCSIHostNetwork = true;
              pluginTolerations = [ ];
              provisionerTolerations = [ ];

              # NixOS-specific volume mounts for kernel modules and nix store
              csiRBDPluginVolume = [
                {
                  name = "lib-modules";
                  hostPath = {
                    path = "/run/booted-system/kernel-modules/lib/modules/";
                  };
                }
                {
                  name = "host-nix";
                  hostPath = {
                    path = "/nix";
                  };
                }
              ];

              csiRBDPluginVolumeMount = [
                {
                  name = "host-nix";
                  mountPath = "/nix";
                  readOnly = true;
                }
              ];

              csiCephFSPluginVolume = [
                {
                  name = "lib-modules";
                  hostPath = {
                    path = "/run/booted-system/kernel-modules/lib/modules/";
                  };
                }
                {
                  name = "host-nix";
                  hostPath = {
                    path = "/nix";
                  };
                }
              ];

              csiCephFSPluginVolumeMount = [
                {
                  name = "host-nix";
                  mountPath = "/nix";
                  readOnly = true;
                }
              ];
            };
          };
        };

        # Rook Ceph Cluster
        rook-ceph-cluster = {
          name = "rook-ceph-cluster";
          repo = "https://charts.rook.io/release";
          version = "v1.18.2";
          hash = "sha256-jP2EQatEbtL7R+16Fx31WYwMqKAiq9b5KStD8zxsaTo=";
          targetNamespace = "rook-ceph";
          createNamespace = false;
          values = {
            operatorNamespace = "rook-ceph";

            # Ceph Cluster Configuration
            cephClusterSpec = {
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

              # Configure placement for all components
              placement = {
                all = {
                  tolerations = [ ];
                };
              };

              # Storage configuration using ZFS backend
              storage = {
                useAllNodes = true;
                useAllDevices = false;
                storageClassDeviceSets = [
                  {
                    name = "zfs-nvme-set";
                    count = 1;
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
                          accessModes = [ "ReadWriteOnce" ];
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
            };

            # Enable CephBlockPools and StorageClasses
            cephBlockPools = [
              {
                name = "ceph-blockpool";
                spec = {
                  failureDomain = "host";
                  replicated = {
                    size = 2;
                  };
                };
                storageClass = {
                  enabled = true;
                  name = "ceph-block";
                  isDefault = false;
                  reclaimPolicy = "Delete";
                  allowVolumeExpansion = true;
                  volumeBindingMode = "Immediate";
                  parameters = {
                    imageFormat = "2";
                    imageFeatures = "layering";
                    "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-rbd-provisioner";
                    "csi.storage.k8s.io/provisioner-secret-namespace" = "rook-ceph";
                    "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-rbd-provisioner";
                    "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph";
                    "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-rbd-node";
                    "csi.storage.k8s.io/node-stage-secret-namespace" = "rook-ceph";
                  };
                };
              }
            ];

            # Enable CephFileSystems and StorageClasses
            cephFileSystems = [
              {
                name = "ceph-filesystem";
                spec = {
                  metadataPool = {
                    replicated = {
                      size = 2;
                    };
                  };
                  dataPools = [
                    {
                      failureDomain = "host";
                      replicated = {
                        size = 2;
                      };
                    }
                  ];
                  metadataServer = {
                    activeCount = 1;
                    activeStandby = true;
                  };
                };
                storageClass = {
                  enabled = true;
                  name = "ceph-filesystem";
                  isDefault = false;
                  reclaimPolicy = "Delete";
                  allowVolumeExpansion = true;
                  volumeBindingMode = "Immediate";
                  parameters = {
                    "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-cephfs-provisioner";
                    "csi.storage.k8s.io/provisioner-secret-namespace" = "rook-ceph";
                    "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-cephfs-provisioner";
                    "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph";
                    "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-cephfs-node";
                    "csi.storage.k8s.io/node-stage-secret-namespace" = "rook-ceph";
                  };
                };
              }
            ];
          };
        };
      };
}
