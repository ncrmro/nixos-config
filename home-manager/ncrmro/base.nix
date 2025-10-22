{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
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

  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # Tag messaging apps
      "tag +messaging, class:Signal"
      "tag +messaging, title:.*WhatsApp.*"
      "tag +messaging, class:discord"
      "tag +messaging, class:telegram"

      # Apply rules to all messaging apps
      "noscreenshare, tag:messaging"
      "workspace special:magic, tag:messaging"
      "tile, tag:messaging"

      "workspace special:magic, title:.*YouTube Music.*"
      "tile, title:.*YouTube Music.*"
    ];
  };

  home.packages = with pkgs; [
    google-chrome
    zig
  ];

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
