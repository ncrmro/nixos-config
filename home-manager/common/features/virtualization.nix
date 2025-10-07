{pkgs, ...}: {
  home.packages = with pkgs; [
    quickemu
  ];

  home.file.".config/libvirt/libvirt.conf".text = ''
    uri_default = "qemu:///system"
  '';

  # Configure libvirt to use our consistent firmware paths
  # These paths are created by systemd tmpfiles in the system configuration
  home.file.".config/libvirt/qemu.conf".text = ''
    # NVRAM firmware configurations for UEFI VMs
    # Using consistent paths that are independent of nix store paths
    nvram = [
      "/run/libvirt/nix-ovmf/AAVMF_CODE.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.fd",
      "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd"
    ]

    # Additional firmware paths for broader compatibility
    # These can be referenced directly in VM XML configurations
    # Example: <loader readonly='yes' type='pflash'>/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd</loader>
  '';
}
