# Shared home-manager configuration for Agent VMs
# This module provides agent-specific configuration that complements keystone.terminal.
# Each agent's agent.nix should import keystone.homeModules.terminal and this module.
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Ensure systemd user services start properly
  systemd.user.startServices = "sd-switch";

  # Agent-specific packages (not provided by keystone.terminal)
  home.packages = with pkgs; [
    # Core utilities not in keystone
    bat # Modern cat
    fd # Fast find
    fzf # Fuzzy finder
    jq # JSON processor
    btop # Modern resource monitor
    curl
    wget

    # GitHub CLI for agent workflows
    gh

    # Browsers for web automation
    google-chrome
    chromium

    # Bitwarden CLI for secrets
    bitwarden-cli

    # tmux as backup multiplexer
    tmux
  ];

  # SSH Key Auto-Generation Service
  # Generates ed25519 key on first boot if not present
  systemd.user.services.ssh-keygen = {
    Unit = {
      Description = "Generate SSH key if not present";
      ConditionPathExists = "!%h/.ssh/id_ed25519";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N '' -f %h/.ssh/id_ed25519";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Ensure .ssh directory exists
  home.file.".ssh/.keep".text = "";

  # Enable SSH commit signing (keystone.terminal handles the rest of git config)
  programs.git.settings = {
    commit.gpgsign = true;
    gpg.format = "ssh";
    user.signingkey = "~/.ssh/id_ed25519.pub";
  };

  # GNOME Keyring Integration
  services.gnome-keyring = {
    enable = true;
    components = [
      "pkcs11"
      "secrets"
      "ssh"
    ];
  };

  # Ensure agents directory exists for work
  home.file."agents/.keep".text = "";
}
