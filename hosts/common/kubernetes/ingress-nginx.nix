{ ... }: {
  services.k3s.autoDeployCharts = {
    ingress-nginx = {
      name = "ingress-nginx";
      repo = "https://kubernetes.github.io/ingress-nginx";
      version = "4.13.2";
      hash = "sha256-5rZUCUQ1AF6GBa+vUbko3vMhinZ7tsnJC5p/JiKllTo=";
      targetNamespace = "ingress-nginx";
      createNamespace = true;
      values = {
        controller = {
          service = {
            type = "LoadBalancer";
          };
          watchIngressWithoutClass = true;
          ingressClassResource = {
            name = "nginx";
            enabled = true;
            default = true;
          };
        };
      };
    };
  };
}
