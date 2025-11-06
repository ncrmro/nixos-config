{pkgs, ...}: {
  home.packages = with pkgs; [
    quickemu
    virt-viewer
    pkg-config
    libvirt
    python3Packages.libvirt
    # Build tools needed for compiling Python C extensions (like libvirt-python)
    gcc
  ];

  # Set up PKG_CONFIG_PATH for libvirt development
  # Required when building Python libvirt bindings (libvirt-python) outside of Nix
  # (e.g., via uv, pip, or poetry) as they need to compile against libvirt C headers
  home.sessionVariables = {
    PKG_CONFIG_PATH = "${pkgs.libvirt}/lib/pkgconfig:$PKG_CONFIG_PATH";
  };

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
