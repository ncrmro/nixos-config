{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Use unstable nixpkgs for Vulkan acceleration support
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in {
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-vulkan;
  };
}
