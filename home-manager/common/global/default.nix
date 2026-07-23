{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../../modules/keystone/terminal/agent-assets-dotagents.nix
    ../../../modules/home-manager/dotfiles
  ];

  home.username = lib.mkDefault "ncrmro";
  home.homeDirectory = lib.mkDefault "/home/ncrmro";
  home.stateVersion = lib.mkDefault "25.05";

  programs.home-manager.enable = true;

  # Plain-text dotfiles (stow) own git + ssh config; nix only provisions the
  # binaries. Desktop/other features append their own packages (e.g. hyprland).
  dotfiles.enable = true;
  dotfiles.packages = [
    "git"
    "ssh"
  ];

  home.packages = [ pkgs.lsof ];

  # The personal repository is the canonical global agent layer. Project-local
  # .agents trees are discovered from their repository; Outfitter 0.10 keeps a
  # compatibility view under legacy/outfitter. Leave ~/.outfitter/cache mutable.
  home.file.".agents".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/ncrmro/.agents";
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/ncrmro/.agents/skills";
  home.file.".outfitter/settings.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/ncrmro/.agents/legacy/outfitter/settings.yml";
  home.file.".outfitter/profiles".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/ncrmro/.agents/legacy/outfitter/profiles";
  home.file.".outfitter/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/ncrmro/.agents/skills";

  home.shellAliases = {
    killport = "function _killp(){ lsof -nti:$1 | xargs kill -9 };_killp";
  };

  # Enable Wayland support for Electron/Chromium applications
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # ssh config now lives in ncrmro/dotfiles (packages/ssh/.ssh/config), stowed
  # into place. Disable HM generation so it does not fight stow for ~/.ssh/config.
  programs.ssh.enable = lib.mkForce false;

  keystone.development = lib.mkDefault true;
  keystone.repos = import ../../../repos.nix;

  # Keystone terminal configuration
  keystone.terminal = {
    enable = true;
    git = {
      userName = "Nicholas Romero";
      userEmail = "ncrmro@gmail.com";
      forgejo = {
        enable = true;
        domain = "git.ncrmro.com";
        sshPort = 2222;
        username = "ncrmro";
      };
    };
    sandbox = {
      extraSubstituters = [ "https://cache.ncrmro.com/main" ];
      extraTrustedPublicKeys = [ "main:H852yjGdbbRIOQcnKm3uZOpZWRFmQoQ5p4I7VDz7kAI=" ];
    };
  };

  # git config now lives in ncrmro/dotfiles (packages/git/.config/git/config),
  # stowed into place. Disable HM generation so it does not fight stow.
  programs.git.enable = lib.mkForce false;
}
