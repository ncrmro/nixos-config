{ inputs, oceanConfig, ... }:
let
  keys = import ../../modules/users/keys.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/headscale
    ../common/optional/alloy-client.nix
    ../common/optional/tailscale.node.nix
    ../common/optional/agenix.nix
    ./adguard-home.nix
    ./nginx.nix
    inputs.keystone.nixosModules.headscale-dns
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  time.timeZone = "America/Chicago";
  networking.hostName = "mercury";
  networking.domain = "";
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = keys.root;

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
    tags = [ "tag:server" ];
    loginServer = "https://mercury.ncrmro.com";
  };

  # Auto-DNS: import generated DNS records from ocean's keystone services
  keystone.headscale = {
    enable = true;
    dnsRecords = oceanConfig.keystone.server.generatedDNSRecords;
  };

  system.stateVersion = "25.05";
}
