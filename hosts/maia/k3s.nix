{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../common/optional/k8s-node-storage.nix
  ];
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

  };

}
