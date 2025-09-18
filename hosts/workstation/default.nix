{
  inputs,
  outputs,
  modulesPath,
  lib,
  pkgs,
  ...
} @ args: {
  imports = [
    inputs.disko.nixosModules.disko
    # inputs.omarchy-nix.nixosModules.default
    inputs.home-manager.nixosModules.default
    outputs.nixosModules.omarchy-config
    ./disk-config.nix
    ../common/optional/zfs.luks.root.nix
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
    ../common/optional/tailscale.node.nix
    ../common/optional/secureboot.nix
    ../common/optional/ollama.nix
    ../common/optional/nfs-client.nix
    ../common/optional/monitoring-client.nix
    ./nvidia.nix
  ];

  programs.zsh.enable = true;
  users.mutableUsers = true;
  users.users.ncrmro.shell = pkgs.zsh;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {inherit inputs outputs;};
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ncrmro-laptop.nix;

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

  environment.variables = {
    TERM = "xterm-256color"; # Or your preferred terminal type
  };

  # Configure Tailscale node (no tags for client machine)
  services.tailscale.node = {
    enable = true;
  };

  services.openssh.settings.PermitRootLogin = "yes";

  services.monitoring-client = {
    enable = true;
    listenAddress = "100.64.0.3";
  };

  networking.hostId = "cb1216ed"; # generate with: head -c 8 /etc/machine-id
  networking.hostName = "ncrmro-workstation";

  system.stateVersion = "25.11";
}
