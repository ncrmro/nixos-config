{ ... }:
{
  # Enable NFS server
  services.nfs.server = {
    enable = true;
    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;

    # Export directories
    exports = ''
      /guest 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
      /ocean/media 100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
    '';

    # Create mount directory if it doesn't exist
    createMountPoints = true;
  };

  # Ensure the /guest directory exists
  systemd.tmpfiles.rules = [
    "d /guest 0777 root root -"
  ];

  # Open necessary firewall ports for NFS
  networking.firewall = {
    allowedTCPPorts = [
      111 # rpcbind
      2049 # nfsd
      4000 # rpc.statd
      4001 # rpc.lockd
      4002 # rpc.mountd
    ];
    allowedUDPPorts = [
      111 # rpcbind
      2049 # nfsd
      4000 # rpc.statd
      4001 # rpc.lockd
      4002 # rpc.mountd
    ];
  };
}
