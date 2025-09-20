{
  # k3s firewall configuration - restrict API server to Tailscale only
  networking.firewall = {
    interfaces.tailscale0 = {
      allowedTCPPorts = [
        6443 # k3s: API server (restricted to Tailscale only)
        5001 # k3s: distributed registry mirror peer-to-peer communication
        # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
      ];
      allowedUDPPorts = [
        # 8472 # k3s, flannel: required if using multi-node for inter-node networking
      ];
    };
  };
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    "--disable=traefik" # Disable traefik to use ingress nginx instead
    # "--debug" # Optionally add additional args to k3s
  ];
}
