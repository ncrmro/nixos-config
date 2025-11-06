{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  # Example Home Manager configuration with full GNOME Keyring integration
  # This configuration enables comprehensive credential management

  imports = [
    # Import the GNOME Keyring integration module
    ../../../home-manager/common/features/security.nix

    # Common configurations
    ../../../home-manager/common/global
  ];

  # Enable comprehensive GNOME Keyring integration
  programs.gnome-keyring-integration = {
    enable = true;

    # SSH agent integration (default: true)
    ssh.enable = true;

    # Docker credential helper (default: true)
    docker.enable = true;

    # Password managers
    passwordManagers = {
      # Enable 1Password CLI integration
      onePassword = true;

      # Enable Bitwarden CLI integration
      bitwarden = true;
    };
  };

  # Additional packages for demonstration
  home.packages = with pkgs; [
    # Development tools that benefit from credential management
    git
    gh # GitHub CLI (uses keyring for auth)
    docker-compose

    # Optional: GUI tools for keyring management
    seahorse # GNOME Keyring GUI
  ];

  # Git configuration that works with keyring
  programs.git = {
    enable = true;
    userName = "Example User";
    userEmail = "user@example.com";
    extraConfig = {
      # Use credential helper that integrates with keyring
      credential.helper = "libsecret";

      # SSH signing with keys from keyring
      gpg.format = "ssh";
      commit.gpgsign = true;
      user.signingkey = "~/.ssh/id_ed25519";
    };
  };

  # Shell aliases for keyring management
  programs.zsh.shellAliases = {
    # Keyring status and management
    "keyring-status" = "keyring-status";
    "keyring-unlock" = "gnome-keyring-daemon --unlock";

    # Password manager shortcuts
    "bw-login" = "bw-keyring-login";
    "op-login" = "op-keyring-login";

    # SSH key management
    "ssh-keys" = "ssh-add -l";
    "ssh-add-all" = "ssh-add ~/.ssh/id_*";
  };

  # Optional: Configure browser to use keyring for password storage
  programs.chromium = {
    enable = true;
    extensions = [
      {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
    ];
  };

  # Home Manager state version
  home.stateVersion = "25.05";
}
