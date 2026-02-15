# Libvirt server for hosting VMs with remote virt-manager access
# Connect from workstation/laptop using: qemu+ssh://ncrmro@ocean/system
{ pkgs, lib, ... }:
let
  ovmfPkg = pkgs.OVMF.override {
    secureBoot = true;
    tpmSupport = true;
    msVarsTemplate = true;
  };
  qemuPkg = pkgs.qemu_kvm;
in
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = lib.mkDefault qemuPkg;
      runAsRoot = true;
      swtpm.enable = true;
      # ovmf option removed in nixos-unstable - OVMF is now included by default with QEMU
      # We still create symlinks via tmpfiles for VM XML compatibility
    };
  };

  # Polkit rule allows libvirtd group members to manage VMs
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.libvirt.unix.manage" &&
          subject.isInGroup("libvirtd")) {
        return polkit.Result.YES;
      }
    });
  '';

  users.users.ncrmro.extraGroups = [ "libvirtd" ];

  # Directories and firmware symlinks
  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/qemu/nvram 0755 root root -"
    "d /var/lib/libvirt/images 0755 root root -"
    "d /var/lib/libvirt/isos 0755 root root -"
    "d /run/libvirt/nix-ovmf 0755 root root -"
    "L+ /run/libvirt/nix-ovmf/OVMF_CODE.fd - - - - ${ovmfPkg.fd}/FV/OVMF_CODE.fd"
    "L+ /run/libvirt/nix-ovmf/OVMF_VARS.fd - - - - ${ovmfPkg.fd}/FV/OVMF_VARS.fd"
    "L+ /run/libvirt/nix-ovmf/OVMF_CODE.ms.fd - - - - ${ovmfPkg.fd}/FV/OVMF_CODE.fd"
    "L+ /run/libvirt/nix-ovmf/OVMF_VARS.ms.fd - - - - ${ovmfPkg.fd}/FV/OVMF_VARS.ms.fd"
    "L+ /run/libvirt/nix-ovmf/edk2-x86_64-code.fd - - - - ${qemuPkg}/share/qemu/edk2-x86_64-code.fd"
    "L+ /run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd - - - - ${qemuPkg}/share/qemu/edk2-x86_64-secure-code.fd"
  ];

  environment.systemPackages = with pkgs; [
    virt-viewer
    libguestfs
  ];
}
