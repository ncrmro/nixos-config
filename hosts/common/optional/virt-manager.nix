{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  users.users.ncrmro.extraGroups = [ "libvirtd" ];
  # This will need be set in the home-manager config
  # home.file.".config/libvirt/libvirt.conf".text = ''
  #   uri_default = "qemu:///system"
  # '';
}
