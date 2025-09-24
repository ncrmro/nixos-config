{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/headscale
    ../common/optional/alloy-client.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
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

  system.stateVersion = "25.05";
}
