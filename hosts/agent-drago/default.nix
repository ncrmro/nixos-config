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

    # QEMU Package Selection:
    # - qemu_kvm is actually qemu-host-cpu-only (minimal, no SPICE/virgl)
    # - qemu_full includes SPICE, virgl, and OpenGL support
    # - optimize.enable=true (default) applies nixosTestRunner which strips SPICE
    # See docs/microvm.md for details
    optimize.enable = false;
    qemu.package = pkgs.qemu_full;

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

    # Disable microvm graphics (adds -nographic), use QXL+SPICE
    graphics.enable = false;

    # Increase memory for GNOME
    mem = 4096;
    vcpu = 2;

    qemu.extraArgs = [
      # QXL display for better SPICE integration (resize, 2D acceleration)
      "-vga"
      "qxl"
      # SPICE remote display
      "-spice"
      "port=5900,addr=100.64.0.6,disable-ticketing=on"
      # SPICE agent for clipboard, mouse, resize
      "-device"
      "virtio-serial-pci"
      "-chardev"
      "spicevmc,id=vdagent,debug=0,name=vdagent"
      "-device"
      "virtserialport,chardev=vdagent,name=com.redhat.spice.0"
      # Networking: user-mode with SSH port forward
      "-netdev"
      "user,id=net0,hostfwd=tcp::2223-:22"
      "-device"
      "virtio-net-pci,netdev=net0"
    ];
  };

  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # SPICE guest integration (clipboard, mouse, display resize)
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

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
