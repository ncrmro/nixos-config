{ pkgs, inputs, ... }:

{
  imports = [
    ../common/optional/agent-minimal.nix
    ./qcow.nix
    ../../modules/users/drago.nix
    ../../modules/users/ncrmro.nix
  ];

  networking.hostName = "agent-drago";

  # Initial password for SSH access
  users.users.drago.initialPassword = "password";
  users.users.ncrmro.initialPassword = "password";

  system.stateVersion = "24.05";
}
