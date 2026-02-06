{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../common/global
    inputs.keystone.homeModules.terminal
  ];

  home = {
    username = lib.mkDefault "ncrmro";
    homeDirectory = "/home/ncrmro";
    stateVersion = "25.05";
    packages = [
    ];
  };

  keystone.terminal = {
    enable = true;
    git = {
      userName = "Nicholas Romero";
      userEmail = "ncrmro@gmail.com";
    };
  };

  programs.home-manager.enable = true;

  programs.zsh = {
    initExtra = ''
      # NixOS rebuild function with --boot support for critical changes
      update() {
        local cmd="switch"
        if [[ "$1" == "--boot" ]]; then
          cmd="boot"
          shift
        fi
        sudo nixos-rebuild "$cmd" --flake ~/nixos-config#ocean "$@"
        if [[ "$cmd" == "boot" ]]; then
          echo "Reboot required to apply changes."
        fi
      }
    '';
  };
}
