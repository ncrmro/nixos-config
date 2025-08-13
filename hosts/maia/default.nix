# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  # boot.loader.grub.enable = false;
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.systemd-boot.enable = true;
  environment.systemPackages = [pkgs.htop];

  networking.hostName = "maia"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "yes";
  };

  users.users."root".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
    # note: ssh-copy-id will add user@your-machine after the public key
    #   but we can remove the "@your-machine" part
  ];
  # generate with: head -c 8 /etc/machine-id
  networking.hostId = "22386ca6";

  # Enable wireguard
  networking.firewall = {
    allowedUDPPorts = [51820];
  };
  networking.wireguard.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP address and subnet of the server's end of the tunnel interface.
      ips = ["10.13.13.4/24"];

      # The port that WireGuard listens to. Must be accessible by the client.
      listenPort = 51820;

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
      #postSetup = ''
      #  ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.13.13.0/24 -o enp3s0 -j MASQUERADE
      #'';

      # This undoes the above command
      #postShutdown = ''
      #  ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.13.13.0/24 -o enp3s0 -j MASQUERADE
      #'';

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKeyFile = "/etc/wireguard/private.key";

      peers = [
        {
          endpoint = "192.168.1.10:51820";
          publicKey = "KOb09l0R69ZnHTs5RuGKBJgAN4AHGW8gfnIIErCOjWE=";
          allowedIPs = ["10.13.13.0/24"];
          presharedKeyFile = "/etc/wireguard/ocean.psk";
          persistentKeepalive = 25;
        }
      ];
    };
  };
  # Enable ZFS backup and NAS
  # zfs create -p lake/backups/ocean
  # zfs allow ocean-sync lake/backups/ocean
  # zfs allow ocean-sync receive,create,mount,readonly lake/backups/ocean
  # zfs set readonly=off lake/backups/ocean
  users.users.ocean-sync = {
    isSystemUser = true;
    shell = pkgs.bash;
    group = "zfs-sync";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCYpB2eDinPg/QrRH6MQXq7SIQpnywmtuFKTAYRibY5Pezkz+eJFYvL/edXID0vo4NeGOGSRtSrPlhICZPnR2U06CFnWG6Wr9qwxIizRG3iMFLVKT9K3ZmXslwBDXYe2Mnnd6KN05DTSUUwCTuUBnTxslfVI3/AU/KkaAinQ9J78i9C4ibPIMPqhgaRum4y3VDWkpJVnuXHLK11fbVKnevP+4KzYuL8/moJCD4sdAmsezdYaNO0Fl+3kPwK0mYmOzWeZTalRAHdPxLSyltIolYHqW8YEWHXP9adUdAaux9Iz22t9Tune9seDT8Jog1iUfwBjiYfw7I4i22XlbNzv14qPYeSiSBpRGzEqYQTdNeJxO91sZrY14MYwq3QVEY5HvtJAtNBbwnhtuZygKNFkK1IGbgvscPxWUWChCrbAFrrYHzQHYHlwOH2drn2CysrvOEEMZK9PKQYY3fKl5TLm0nG78wqR7oo2e816YNR6tDN6ThDgrHI2txtVvHb+ZOOhHM= root@ocean"
    ];
  };
  users.groups.zfs-sync = {};
  services.zfs.autoScrub.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  # programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
