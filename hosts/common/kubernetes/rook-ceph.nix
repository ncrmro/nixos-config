# Rook Ceph Operator
# https://artifacthub.io/packages/helm/rook/rook-ceph
{...}: {
  services.k3s.autoDeployCharts = {
    rook-ceph = {
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
        nodeSelector = {};

        # Configure tolerations for the main operator
        tolerations = [
          # {
          #   key = "ncrmro.com/region";
          #   operator = "Equal";
          #   value = "us-south-2";
          #   effect = "NoSchedule";
          # }
        ];

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
          tolerations = [
            # {
            #   key = "ncrmro.com/region";
            #   operator = "Equal";
            #   value = "us-south-2";
            #   effect = "NoSchedule";
            # }
          ];
        };

        # Configure CSI settings
        csi = {
          enableCSIHostNetwork = true;
          pluginTolerations = [
            {
              key = "ncrmro.com/region";
              operator = "Equal";
              value = "us-south-2";
              effect = "NoSchedule";
            }
          ];
          provisionerTolerations = [
            {
              key = "ncrmro.com/region";
              operator = "Equal";
              value = "us-south-2";
              effect = "NoSchedule";
            }
          ];

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
  };
}
