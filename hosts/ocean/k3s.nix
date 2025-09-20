{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../common/optional/k8s-node-storage.nix
    #../common/kubernetes/rook-ceph.nix
    ../common/kubernetes/zfs-localpv.nix
    ../common/kubernetes/longhorn.nix
  ];
  # Define the K3s server token secret
  age.secrets.k3s-server-token = {
    file = ../../secrets/k3s-server-token.age;
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
    5001 # k3s: distributed registry mirror peer-to-peer communication
  ];
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.tokenFile = config.age.secrets.k3s-server-token.path;
  services.k3s.extraFlags = toString [
    "--disable=traefik" # Disable traefik to use ingress nginx instead
    "--disable=local-storage"
    "--container-runtime-endpoint=/run/containerd/containerd.sock"
    "--tls-san=ocean.mercury"
    "--tls-san=100.64.0.6"
    "--node-ip=100.64.0.6"
    # "--embedded-registry" # Enable distributed OCI registry mirror (TODO: fix nft-expr-counter kernel module issue)
    # "--debug" # Optionally add additional args to k3s
  ];

  # K3s registry mirror configuration
  environment.etc."rancher/k3s/registries.yaml" = {
    text = ''
      mirrors:
        "*":
    '';
  };
}
