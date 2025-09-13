{pkgs, ...}: {
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
      # Optionally set private registry credentials here instead of using /etc/rancher/k3s/registries.yaml
      # plugins."io.containerd.grpc.v1.cri".registry.configs."registry.example.com".auth = {
      #   username = "";
      #   password = "";
      # };
    };
  };

  # k3s configuration
  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  ];
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    "--disable=traefik" # Disable traefik to use ingress nginx instead
    "--disable=local-storage"
    "--container-runtime-endpoint=/run/containerd/containerd.sock"
    "--tls-san=ocean.mercury"
    "--tls-san=100.64.0.6"
    "--node-ip=100.64.0.6"
    # "--debug" # Optionally add additional args to k3s
  ];

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
