{
  config,
  lib,
  ...
}: {
  config = {
    services.k3s.manifests = {
      "ocean-nvme-storage-class".content = {
        apiVersion = "storage.k8s.io/v1";
        kind = "StorageClass";
        metadata = {
          name = "ocean-nvme";
          annotations = {
            "storageclass.kubernetes.io/is-default-class" = "false";
          };
        };
        allowVolumeExpansion = true;
        parameters = {
          thinprovision = "no";
          fstype = "zfs";
          poolname = "rpool/kube";
          shared = "yes";
        };
        provisioner = "zfs.csi.openebs.io";
        allowedTopologies = [
          {
            matchLabelExpressions = [
              {
                key = "kubernetes.io/hostname";
                values = ["ocean"];
              }
            ];
          }
        ];
      };
      "ocean-hdd-storage-class".content = {
        apiVersion = "storage.k8s.io/v1";
        kind = "StorageClass";
        metadata = {
          name = "ocean-hdd";
        };
        allowVolumeExpansion = true;
        parameters = {
          thinprovision = "no";
          fstype = "zfs";
          poolname = "tank/kube";
          shared = "yes";
        };
        provisioner = "zfs.csi.openebs.io";
        allowedTopologies = [
          {
            matchLabelExpressions = [
              {
                key = "kubernetes.io/hostname";
                values = ["ocean"];
              }
            ];
          }
        ];
      };
    };
  };
}
