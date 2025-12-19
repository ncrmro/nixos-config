{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.keystone.homeModules.keystoneTerminal
  ];

  home = {
    username = "nicholas";
    homeDirectory = "/Users/nicholas";
    stateVersion = "25.05";
  };

  # Enable the Keystone TUI module
  keystone.terminal.enable = true;

  home.packages = with pkgs; [
    kubectl
    k9s
  ];

  programs.home-manager.enable = true;
}
