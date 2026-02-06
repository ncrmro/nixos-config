{ pkgs, ... }:

{
  home.username = "drago";
  home.homeDirectory = "/home/drago";

  # Ensure the agents directory exists
  home.file."agents/.keep".text = "";

  # Basic packages for an agent
  home.packages = with pkgs; [
    git
    curl
    wget
    vim
    htop
  ];

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.05";
}
