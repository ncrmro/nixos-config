# Home-manager configuration for virt-manager remote access
# Configures connection to ocean VM host
{ pkgs, ... }:
{
  # Configure libvirt client to connect to ocean by default
  home.file.".config/libvirt/libvirt.conf".text = ''
    # Default to local system connection
    uri_default = "qemu:///system"
  '';

  # Add connection bookmarks for virt-manager
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu+ssh://ncrmro@ocean/system" ];
      uris = [
        "qemu:///system"
        "qemu+ssh://ncrmro@ocean/system"
      ];
    };
  };
}
