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
    inputs.keystone.homeModules.desktop
    ../common/global
    ../common/features/cli
    ../common/features/desktop
    ../common/features/virtualization.nix
    ../common/features/cliflux.nix
    ../common/optional/mcp/github-mcp.nix
    ../common/optional/mcp/kubernetes.nix
    ../common/optional/mcp/mcp-language-server.nix
    inputs.nix-index-database.homeModules.nix-index
  ];

  home.packages = with pkgs; [
    nixfmt-rfc-style
    google-chrome
    zig
    gh
    gh-dash
    devcontainer
    obsidian
    signal-desktop
    inputs.keystone.packages.${pkgs.stdenv.hostPlatform.system}.keystone-agent
  ];

  # Keystone desktop includes terminal
  keystone.desktop.enable = true;
  keystone.desktop.hyprland.enable = true;

  keystone.desktop.ageYubikey = {
    enable = true;
    identities = [
      "AGE-PLUGIN-YUBIKEY-17DDRYQ5ZFMHALWQJTKHAV" # Serial: 36854515, Slot: 1 (yubi-black)
    ];
  };

  # CRITICAL: exec-once MUST go in extraConfig, NOT in settings.
  # The hyprland HM settings type is a raw freeform valueType — setting
  # exec-once in settings silently REPLACES keystone's entire exec-once list,
  # which breaks: lock screen on boot (hyprlock), D-Bus activation environment,
  # hyprsunset, hyprpolkitagent, and clipboard manager (clipse).
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = hyprctl dispatch workspace 2
  '';

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
  programs.fastfetch.enable = true;

  programs.git.settings = {
    user = {
      name = "Nicholas Romero";
      email = "ncrmro@gmail.com";
      signingkey = "~/.ssh/id_ed25519";
    };
    credential.helper = "store";
    push.autoSetupRemote = true;
    gpg.format = "ssh";
    commit.gpgsign = true;
    includeIf."gitdir:~/code/unsupervised/" = {
      path = "~/code/unsupervised/.gitconfig";
    };
  };

  keystone.terminal.mail = {
    enable = true;
    accountName = "ncrmro";
    email = "nicholas.romero@ncrmro.com";
    displayName = "Nicholas Romero";
    login = "ncrmro";
    host = "mail.ncrmro.com";
    passwordCommand = "cat /run/agenix/stalwart-mail-ncrmro-password";
  };
}
