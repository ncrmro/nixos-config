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
        # Optionally set private registry credentials here instead of using /etc/rancher/k3s/registries.yaml
        # plugins."io.containerd.grpc.v1.cri".registry.configs."registry.example.com".auth = {
        #   username = "";
        #   password = "";
        # };
      };
  };

  # k3s configuration
  networking.firewall = {
    # Open K3s cluster ports only on Tailscale interface
    interfaces.tailscale0 = {
      allowedTCPPorts = [
        6443 # k3s: API server (restricted to Tailscale only)
        10250 # k3s: kubelet API
        2379 # k3s: etcd server client API
        2380 # k3s: etcd server peer API
        5001 # k3s: distributed registry mirror peer-to-peer communication
      ];
      allowedUDPPorts = [
        8472 # k3s: flannel VXLAN
      ];
    };
  };
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
    "--flannel-iface=tailscale0"
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
