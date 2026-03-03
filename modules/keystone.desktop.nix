{ inputs, ... }:
{
  imports = [
    inputs.keystone.nixosModules.desktop
  ];

  keystone.desktop = {
    enable = true;
    user = "ncrmro";
  };

  # Desktop needs resolved for Tailscale MagicDNS
  keystone.os.services.resolved.enable = true;

  keystone.os.users.ncrmro.desktop.enable = true;
}
