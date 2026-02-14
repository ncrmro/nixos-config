# Shared home-manager configuration for Agent VMs
# This module provides common user configuration for all agent VMs
# including terminal packages, SSH key generation, Git config, and Bitwarden.
#
# Import this in each agent's agent.nix and override username/email.
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

  # Terminal Packages (Keystone-style)
  home.packages = with pkgs; [
    # Core utilities
    eza # Modern ls
    bat # Modern cat
    ripgrep # Fast grep
    fd # Fast find
    fzf # Fuzzy finder
    jq # JSON processor
    htop # Process viewer
    btop # Modern resource monitor

    # Development tools
    git
    gh # GitHub CLI
    curl
    wget
    vim

    # Bitwarden CLI for secrets
    bitwarden-cli

    # Terminal tools
    tmux
    zellij
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

  # Git Configuration with SSH Signing
  programs.git = {
    enable = true;
    # These should be overridden in agent-specific config
    userName = lib.mkDefault "Agent";
    userEmail = lib.mkDefault "agent@example.com";

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;

      # SSH signing (use the generated key)
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
    };
  };

  # Bash Configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -la";
      la = "eza -a";
      cat = "bat";
      grep = "rg";
      find = "fd";
    };
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

  # Environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  # Ensure agents directory exists for work
  home.file."agents/.keep".text = "";
}
