{...}: {
  services.k3s.autoDeployCharts = {
    cert-manager = {
      name = "cert-manager";
      repo = "https://charts.jetstack.io";
      version = "v1.18.2";
      hash = "sha256-2t33r3sfDqqhDt15Cu+gvYwrB4MP6/ZZRg2EMhf1s8U=";
      targetNamespace = "kube-system";
      createNamespace = false;
      values = {
        crds = {
          enabled = true;
        };
      };
    };
  };
}
