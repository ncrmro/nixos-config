{ inputs, ... }:
{
  imports = [
    inputs.keystone.nixosModules.server
  ];

  keystone.server.enable = true;
}
