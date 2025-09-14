{...}: {
  # ClusterIssuer for Let's Encrypt with Cloudflare DNS validation
  #
  # IMPORTANT: Before this will work, you must manually create the Cloudflare API token secret.
  # See docs/KUBERNETES_SSL_CERTIFICATES.md for the complete setup instructions.

  services.k3s.manifests = {
    letsencrypt-cluster-issuer = {
      enable = true;
      target = "letsencrypt-cluster-issuer.yaml";
      content = {
        apiVersion = "cert-manager.io/v1";
        kind = "ClusterIssuer";
        metadata = {
          name = "letsencrypt-cloudflare";
        };
        spec = {
          acme = {
            server = "https://acme-v02.api.letsencrypt.org/directory";
            email = "admin@ncrmro.com";
            privateKeySecretRef = {
              name = "letsencrypt-cloudflare-private-key";
            };
            solvers = [
              {
                dns01 = {
                  cloudflare = {
                    apiTokenSecretRef = {
                      name = "cloudflare-api-token";
                      key = "api-token";
                    };
                  };
                };
              }
            ];
          };
        };
      };
    };
  };
}
