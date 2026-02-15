{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ../common/kubernetes/rook-ceph.nix
    ../common/kubernetes/zfs-localpv.nix
    ../common/kubernetes/longhorn.nix
  ];
  # Define the K3s agent token secret
  age.secrets.k3s-agent-token = {
    file = ../../agenix-secrets/secrets/k3s-agent-token.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # containerd configuration
  virtualisation.containerd = {
    enable = true;
    settings =
      let
        fullCNIPlugins = pkgs.buildEnv {
          name = "full-cni";
          paths = with pkgs; [
            cni-plugins
            cni-plugin-flannel
          ];
        };
      in
      {
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
  networking.firewall = {
    # Open K3s cluster ports only on Tailscale interface
    interfaces.tailscale0 = {
      allowedTCPPorts = [
        10250 # k3s: kubelet API
        5001 # k3s: distributed registry mirror peer-to-peer communication
      ];
      allowedUDPPorts = [
        8472 # k3s: flannel VXLAN
      ];
    };
  };

  services.k3s = {
    enable = true;
    role = "agent";
    tokenFile = config.age.secrets.k3s-agent-token.path;
    serverAddr = "https://100.64.0.6:6443"; # Ocean server address on headscale
    extraFlags = toString [
      "--container-runtime-endpoint=/run/containerd/containerd.sock"
      "--node-ip=100.64.0.5" # Maia's headscale IP
      "--flannel-iface=tailscale0"
      #"--node-taint=ncrmro.com/region=us-south-2:NoSchedule"
      #"--embedded-registry" # Enable distributed OCI registry mirror
    ];
  };

  # K3s registry mirror configuration
  environment.etc."rancher/k3s/registries.yaml" = {
    text = ''
      mirrors:
        "*":
    '';
  };
}
