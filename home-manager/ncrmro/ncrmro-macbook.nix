{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../common/features/macos-dev.nix
    ../common/optional/mosh.nix
  ];

  home = {
    username = "ncrmro";
    homeDirectory = "/Users/ncrmro";
    stateVersion = "25.05";
  };

  # macOS-specific configurations can be added here
  # For example:
  # programs.alacritty.settings.font.size = lib.mkForce 14.0;
}
