{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.keystone.homeModules.terminal
  ];

  home = {
    username = "nicholas";
    homeDirectory = "/Users/nicholas";
    stateVersion = "25.05";
  };

  home.packages = with pkgs; [
    kubectl
    k9s
  ];

  programs.home-manager.enable = true;
}
