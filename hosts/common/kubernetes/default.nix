{ ... }:
{
  imports = [
    ./cert-manager.nix
    #./ceph-cluster.nix
    ./cluster-issuer.nix
    ./gitea.nix
    ./ingress-nginx.nix
    ./loki.nix
    ./alloy.nix
    ./pgo.nix
    ./kube-prometheus-stack.nix
  ];
}
