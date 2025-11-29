{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/headscale
    ../common/optional/alloy-client.nix
    ../common/optional/tailscale.node.nix
    ../common/optional/agenix.nix
    ../common/optional/stalwart-mail.nix
    ./adguard-home.nix
    ./nginx.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  time.timeZone = "America/Chicago";
  networking.hostName = "mercury";
  networking.domain = "";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k''];

  services.alloy-client = {
    enable = true;
    extraLabels = {
      environment = "production";
      device_type = "vps";
      service = "headscale";
    };
  };

  # Configure Tailscale node
  services.tailscale.node = {
    enable = true;
    tags = ["tag:server"];
    loginServer = "https://mercury.ncrmro.com";
  };

  system.stateVersion = "25.05";
}
