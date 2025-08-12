{
  pkgs,
  ...
}: {
virtualisation.libvirtd = {
  enable = true;
  qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;
    swtpm.enable = true;
    ovmf = {
      enable = true;
      packages = [(pkgs.OVMF.override {
        secureBoot = true;
        tpmSupport = true;
      }).fd];
    };
  };
};
  programs.virt-manager.enable = true;
  users.users.ncrmro.extraGroups = [ "libvirtd" ];

  # This will need be set in the home-manager config
  # home.file.".config/libvirt/libvirt.conf".text = ''
  #   uri_default = "qemu:///system"
  # '';
  
}
