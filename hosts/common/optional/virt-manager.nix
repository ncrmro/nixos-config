{pkgs, ...}: let
  # Define the OVMF package with required features
  ovmfPkg = pkgs.OVMF.override {
    secureBoot = true;
    tpmSupport = true;
  };

  # QEMU package for accessing EDK2 firmware files
  qemuPkg = pkgs.qemu_kvm;
in {
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = qemuPkg;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ovmfPkg.fd];
      };
    };
  };
  programs.virt-manager.enable = true;
  users.users.ncrmro.extraGroups = ["libvirtd"];

  # Create consistent symlinks for firmware files that VM XML files can reference
  # This ensures portable VM configurations across different nix store paths
  systemd.tmpfiles.rules = [
    # Create the directory for our consistent firmware paths
    "d /run/libvirt/nix-ovmf 0755 root root -"

    # OVMF firmware files (x86_64 UEFI)
    "L+ /run/libvirt/nix-ovmf/OVMF_CODE.fd - - - - ${ovmfPkg.fd}/FV/OVMF_CODE.fd"
    "L+ /run/libvirt/nix-ovmf/OVMF_VARS.fd - - - - ${ovmfPkg.fd}/FV/OVMF_VARS.fd"

    # ARM64 firmware files (if available)
    "L+ /run/libvirt/nix-ovmf/AAVMF_CODE.fd - - - - ${ovmfPkg.fd}/FV/AAVMF_CODE.fd"
    "L+ /run/libvirt/nix-ovmf/AAVMF_VARS.fd - - - - ${ovmfPkg.fd}/FV/AAVMF_VARS.fd"

    # EDK2 firmware files from QEMU package (for additional compatibility)
    "L+ /run/libvirt/nix-ovmf/edk2-i386-vars.fd - - - - ${qemuPkg}/share/qemu/edk2-i386-vars.fd"
    "L+ /run/libvirt/nix-ovmf/edk2-x86_64-code.fd - - - - ${qemuPkg}/share/qemu/edk2-x86_64-code.fd"
    "L+ /run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd - - - - ${qemuPkg}/share/qemu/edk2-x86_64-secure-code.fd"
  ];

  # Usage in VM XML configurations:
  # The consistent firmware paths can now be used in VM XML files like this:
  #
  # <os>
  #   <type arch='x86_64' machine='pc-q35-6.2'>hvm</type>
  #   <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
  #   <nvram>/run/libvirt/nix-ovmf/OVMF_VARS.fd</nvram>
  #   <boot dev='hd'/>
  # </os>
  #
  # For Secure Boot:
  # <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd</loader>
  #
  # These paths remain consistent across NixOS rebuilds and package updates.

  # This will need be set in the home-manager config
  # home.file.".config/libvirt/libvirt.conf".text = ''
  #   uri_default = "qemu:///system"
  # '';
}
