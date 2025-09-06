{...}: {
  imports = [
    ./hardware-configuration.nix
    ../common/global
  ];

  networking.hostName = "ocean";
  services.openssh.enable = true;
  system.stateVersion = "25.05";
}