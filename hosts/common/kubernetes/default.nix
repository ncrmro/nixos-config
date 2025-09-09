{...}: {
  imports = [
    ./cert-manager.nix
    ./ingress-nginx.nix
    ./loki.nix
    ./zfs-localpv.nix
    ./kube-prometheus-stack.nix
  ];
}
