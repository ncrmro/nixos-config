{...}: {
  # k3s configuration
  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
  ];
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    "--disable=traefik" # Disable traefik to use ingress nginx instead
    # "--debug" # Optionally add additional args to k3s
  ];
}