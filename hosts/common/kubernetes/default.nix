{ ... }:
{
  imports = [
    ./cert-manager.nix
    #./ceph-cluster.nix
    ./cluster-issuer.nix
    # ./gitea.nix # Replaced by keystone.os.gitServer (NixOS Forgejo)
    ./ingress-nginx.nix
    #./loki.nix
    #./alloy.nix
    ./pgo.nix
    #./kube-prometheus-stack.nix
  ];
}
