{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/users/drago.nix
    ../../modules/users/ncrmro.nix
    inputs.home-manager.nixosModules.default
  ];

  # Apply overlays (provides keystonePkgs for home-manager modules)
  nixpkgs.overlays = import ../../overlays { inherit inputs; };
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "agent-drago";

  microvm = {
    hypervisor = "qemu";

    volumes = [
      {
        image = "agent-drago.img";
        mountPoint = "/var";
        size = 10240;
        autoCreate = true;
        fsType = "ext4";
      }
    ];

    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/store";
        proto = "virtiofs";
      }
    ];

    qemu.extraArgs = [
      "-vga"
      "qxl"
      "-device"
      "virtio-serial-pci"
      "-spice"
      "port=5900,addr=127.0.0.1,disable-ticketing=on"
      "-device"
      "virtio-gpu-pci,virgl=on"
      "-display"
      "none"
      "-netdev"
      "user,id=net0,hostfwd=tcp::2223-:22"
      "-device"
      "virtio-net-pci,netdev=net0"
    ];
  };

  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "drago";

  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  # Set a password for ncrmro for console access if needed
  users.users.ncrmro.initialPassword = "password";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.drago = import ../../home-manager/drago/agent-drago.nix;
    users.ncrmro = import ../../home-manager/ncrmro/base.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  system.stateVersion = "24.05";
}
