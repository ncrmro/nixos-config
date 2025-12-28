{ ... }:
{
  services.k3s.autoDeployCharts = {
    cloudnative-pg = {
      name = "cloudnative-pg";
      repo = "https://cloudnative-pg.github.io/charts";
      version = "0.26.0";
      hash = "sha256-5Um2iHfHjWRaEITwTbrhV6nNhXeMdHbIegf8nEsTmOI=";
      targetNamespace = "kube-system";
      createNamespace = false;
      values = { };
    };
  };
}
