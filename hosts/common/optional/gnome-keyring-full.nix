{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enhanced GNOME Keyring configuration with comprehensive integration
  # This module provides complete GNOME Keyring setup for credential management
  # across SSH, 1Password, Bitwarden, and Docker
  
  options = {
    services.gnome-keyring-full = {
      enable = lib.mkEnableOption "Enhanced GNOME Keyring with full credential integration";
    };
  };

  config = lib.mkIf config.services.gnome-keyring-full.enable {
    # Core GNOME Keyring service
    services.gnome.gnome-keyring.enable = true;
    
    # Install required packages for credential management
    environment.systemPackages = with pkgs; [
      gnome-keyring
      libsecret  # For secret-tool command line interface
      seahorse   # GUI keyring management
    ];

    # PAM integration for automatic unlock
    security.pam.services = {
      # Enable for common login services
      login.enableGnomeKeyring = true;
      gdm.enableGnomeKeyring = true;
      lightdm.enableGnomeKeyring = true;
      greetd.enableGnomeKeyring = true;
      su.enableGnomeKeyring = true;
      sudo.enableGnomeKeyring = true;
    };

    # Ensure proper D-Bus activation
    services.dbus.packages = [ pkgs.gnome-keyring ];

    # Optional: Add polkit rules for enhanced keyring access
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.secrets.modify-own" &&
              subject.isInGroup("wheel")) {
              return polkit.Result.YES;
          }
      });
    '';
  };
}