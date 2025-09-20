{...}: {
  imports = [
    ./cert-manager.nix
    #./ceph-cluster.nix
    ./cluster-issuer.nix
    ./ingress-nginx.nix
    ./loki.nix
    ./pgo.nix
    ./kube-prometheus-stack.nix
    ./vaultwarden.nix
  ];
}
