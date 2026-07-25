{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  testMicrovmTpm = inputs.keystone.packages.${system}.test-microvm-tpm or null;
in
{
  packages = with pkgs; [
    nixfmt-classic
    jq
    yq
  ];

  scripts.k8s-apply = {
    description = "Apply Ocean's K3s HelmCharts and cluster resources";
    exec = ./k8s-cluster/scripts/k8s-apply;
    packages = [
      pkgs.kubectl
      pkgs.yq-go
    ];
  };

  scripts.k8s-apply-secrets = {
    description = "Decrypt and apply Ocean's agenix-managed Kubernetes Secrets";
    exec = ./k8s-cluster/scripts/k8s-apply-secrets;
    packages = [
      inputs.keystone.inputs.agenix.packages.${system}.default
      pkgs.kubectl
      pkgs.yq-go
    ];
  };

  scripts.k8s-apply-link = {
    description = "Install Link Operator and apply the Vega resident agent on Ocean";
    exec = ./k8s-cluster/scripts/k8s-apply-link;
    packages = [
      pkgs.git
      pkgs.kubectl
      pkgs.kustomize
      pkgs.yq-go
    ];
  };

  scripts.vega-pi-sync = {
    description = "Copy local Pi auth directly into Vega's workspace PVC";
    exec = ./k8s-cluster/scripts/vega-pi-sync;
    packages = [
      pkgs.gnutar
      pkgs.kubectl
    ];
  };

  process.manager.implementation = "process-compose";

  processes = lib.optionalAttrs (testMicrovmTpm != null) {
    vm-tpm-microvm = {
      exec = "${testMicrovmTpm}/bin/test-microvm-tpm";
      process-compose = {
        availability.restart = "no";
        readiness_probe.exec.command = "pgrep -f tpm-microvm";
      };
    };
  };
}
