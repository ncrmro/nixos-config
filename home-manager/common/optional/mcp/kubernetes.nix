{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = [
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
    }).mcp-k8s-go
  ];
}
