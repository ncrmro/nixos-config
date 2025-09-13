{...}: {
  imports = [
    ./cert-manager.nix
    ./cluster-issuer.nix
    ./ingress-nginx.nix
    ./loki.nix
    ./pgo.nix
    ./zfs-localpv.nix
    ./kube-prometheus-stack.nix
  ];
}
