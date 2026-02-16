# Shared NixOS configuration for Agent VMs
# This module provides the common system configuration for all agent VMs
# including GNOME desktop, SPICE integration, SSH, and basic services.
#
# Import this in each agent's default.nix to get the shared config.
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # GNOME Desktop Environment
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # SPICE guest integration (clipboard, mouse, display resize)
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  # Display Manager with auto-login disabled by default (each agent overrides)
  services.displayManager.autoLogin.enable = lib.mkDefault false;

  # SSH Server for remote access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true; # Allow password during initial setup
      PermitRootLogin = "no";
    };
  };

  # Persist SSH host keys in /var for qcow2 images
  services.openssh.hostKeys = [
    {
      path = "/var/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "/var/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  # Network Configuration
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved"; # Use systemd-resolved for DNS
  networking.firewall.enable = true;

  # DNS resolution via systemd-resolved (required for Tailscale MagicDNS)
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "allow-downgrade";
      FallbackDNS = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };
  };

  # Tailscale is configured via tailscale-authkey.nix for auto-auth
  # If not using authkey, enable manually: services.tailscale.enable = true;

  # Nix Configuration with Flakes
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Chrome/Chromium policy: auto-install Bitwarden extension
  # This applies to both Google Chrome and Chromium
  # Extension ID from Chrome Web Store URL
  programs.chromium = {
    enable = true;
    extraOpts = {
      # Force install extensions
      # Format: extension_id;update_url
      ExtensionInstallForcelist = [
        "nngceckbapebfimnlniiiahkandclblb;https://clients2.google.com/service/update2/crx" # Bitwarden
        "hpbjkfadkecgpnpjnfflahhdcfboimek;https://clients2.google.com/service/update2/crx" # Claude
      ];
    };
  };

  # Basic system packages for agents
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    htop
    git
    gnome-tweaks
    spice-vdagent
    dnsutils # Provides dig, nslookup, host
  ];

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Timezone
  time.timeZone = "America/Chicago";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # Boot configuration for qcow2 VMs (hybrid partition table)
  boot.loader.grub.device = "/dev/vda";
  boot.loader.timeout = 0;

  # Filesystem for qcow2 image
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };
}
