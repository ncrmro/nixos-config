{ ... }:
{
  services.k3s.manifests = {
    "ceph-filesystem".content = {
      apiVersion = "ceph.rook.io/v1";
      kind = "CephFilesystem";
      metadata = {
        name = "myfs";
        namespace = "rook-ceph";
      };
      spec = {
        metadataPool = {
          failureDomain = "host";
          replicated = {
            size = 2;
          };
        };
        dataPools = [
          {
            name = "replicated";
            failureDomain = "host";
            replicated = {
              size = 2;
            };
          }
        ];
        preserveFilesystemOnDelete = true;
        metadataServer = {
          activeCount = 1;
          activeStandby = true;
          placement = { };
          resources = { };
        };
      };
    };
  };
}
