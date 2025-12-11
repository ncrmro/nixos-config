{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    outputs.homeManagerModules.keystone-desktop
    ../common/global
    ../common/features/cli
    ../common/features/desktop
    ../common/features/virtualization.nix
    ../common/optional/mcp/github-mcp.nix
    ../common/optional/mcp/kubernetes.nix
    ../common/optional/mcp/mcp-language-server.nix
    ../common/optional/mcp/playwright.nix
    inputs.nix-index-database.homeModules.nix-index
  ];

  home.packages = with pkgs; [
    nixfmt-rfc-style
    google-chrome
    zig
  ];

  # Keystone desktop includes terminal
  keystone.desktop.enable = true;
  keystone.desktop.hyprland.enable = true;

  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # Tag messaging apps
      "tag +messaging, match:class Signal"
      "tag +messaging, match:title .*WhatsApp.*"
      "tag +messaging, match:class discord"
      "tag +messaging, match:class telegram"

      # Apply rules to all messaging apps
      "no_screen_share on, match:tag messaging"
      "workspace special:magic, match:tag messaging"
      # "tile, match:tag messaging"

      "workspace special:magic, match:title .*YouTube Music.*"
      # "tile, match:title .*YouTube Music.*"
    ];
  };

  programs.git.extraConfig = {
    credential.helper = "store";
    push.autoSetupRemote = true;
    gpg.format = "ssh";
    commit.gpgsign = true;
    user.signingkey = "~/.ssh/id_ed25519";
    includeIf."gitdir:~/code/unsupervised/" = {
      path = "~/code/unsupervised/.gitconfig";
    };
  };
}
