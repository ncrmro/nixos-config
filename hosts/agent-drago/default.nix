{ pkgs, inputs, ... }:

{
  imports = [
    ../../modules/users/drago.nix
    ../../modules/users/ncrmro.nix
    inputs.home-manager.nixosModules.default
    inputs.agenix.nixosModules.default
  ];

  # Apply overlays (provides keystonePkgs for home-manager modules)
  nixpkgs.overlays = import ../../overlays { inherit inputs; };
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "agent-drago";

  # Stalwart mail password for drago user (for himalaya client)
  age.secrets.stalwart-mail-drago-password = {
    file = ../../secrets/stalwart-mail-drago-password.age;
    owner = "drago";
    mode = "0400";
  };

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

    # Disable microvm graphics (adds -nographic), we configure display manually
    graphics.enable = false;

    # Increase memory for GNOME
    mem = 4096;
    vcpu = 2;

    qemu.extraArgs = [
      # Display: virtio-vga (works, but no auto-resize in remote-viewer)
      # Known issue: auto-resize doesn't work with current setup
      # Tried: QXL (-vga qxl) - broke display entirely
      # Tried: X11 force (gdm.wayland=false) - no effect on resize
      # TODO: investigate spice-vdagent status in guest, or manual xrandr
      "-device"
      "virtio-vga"
      # SPICE remote display
      "-spice"
      "port=5900,addr=100.64.0.6,disable-ticketing=on"
      # SPICE agent for clipboard, mouse, resize (resize not working)
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
    users.drago = {
      imports = [
        ../../home-manager/drago/agent-drago.nix
        ../../home-manager/drago/himalaya.nix
      ../../home-manager/drago/email-trigger.nix
      ];
    };
    users.ncrmro = import ../../home-manager/ncrmro/base.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  system.stateVersion = "24.05";
}
