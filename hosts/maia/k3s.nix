{
  pkgs,
  config,
  ...
}: {
  # Define the K3s agent token secret
  age.secrets.k3s-agent-token = {
    file = ../../secrets/k3s-agent-token.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # containerd configuration
  virtualisation.containerd = {
    enable = true;
    settings = let
      fullCNIPlugins = pkgs.buildEnv {
        name = "full-cni";
        paths = with pkgs; [
          cni-plugins
          cni-plugin-flannel
        ];
      };
    in {
      version = 2;
      plugins."io.containerd.grpc.v1.cri".containerd = {
        snapshotter = "zfs";
      };
      plugins."io.containerd.grpc.v1.cri".cni = {
        bin_dir = "${fullCNIPlugins}/bin";
        conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d/";
      };
    };
  };

  # k3s configuration as agent
  networking.firewall.allowedTCPPorts = [
    # K3s agent doesn't need to expose API server port
  ];

  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.age.secrets.k3s-agent-token.path;
    serverAddr = "https://100.64.0.6:6443"; # Ocean server address on headscale
    extraFlags = toString [
      "--container-runtime-endpoint=/run/containerd/containerd.sock"
      "--node-ip=100.64.0.5" # Maia's headscale IP
      "--node-taint=ncrmro.com/region=us-south-2:NoSchedule"
    ];
  };

  # The following is because local zfsebs looks for zfs binaries in default place
  environment.etc = {
    "zfs-usr-bin.conf" = {
      text = ''
        [Install]
        WantedBy=multi-user.target
      '';
    };
    "zfs-usr-bin.service" = {
      text = ''
        [Unit]
        Description=ZFS symlinks in /usr/bin

        [Service]
        Type=oneshot
        ExecStart=/run/current-system/sw/bin/mkdir -p /usr/bin
        ExecStart=/run/current-system/sw/bin/ln -sf /run/current-system/sw/bin/zfs /usr/bin/zfs
        ExecStart=/run/current-system/sw/bin/ln -sf /run/current-system/sw/bin/zpool /usr/bin/zpool
        RemainAfterExit=true

        [Install]
        WantedBy=multi-user.target
      '';
    };
  };

  systemd.services.zfs-usr-bin = {
    description = "ZFS symlinks in /usr/bin";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.coreutils}/bin/mkdir -p /usr/bin"
        "${pkgs.coreutils}/bin/ln -sf ${pkgs.zfs}/bin/zfs /usr/bin/zfs"
        "${pkgs.coreutils}/bin/ln -sf ${pkgs.zfs}/bin/zpool /usr/bin/zpool"
      ];
      RemainAfterExit = true;
    };
  };
}
