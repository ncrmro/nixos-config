# Transitional access for the physical Windows NVMe.
#
# The live libvirt domain currently passes through the NVMe controller. Keep
# the pinned device readable while physical migration is in progress, but do
# not emit a second/stale domain definition. Remove this module only after the
# Ocean VM has been promoted, RDP-validated, merged, and deployed.
{
  config,
  ...
}:
let
  admin = config.keystone.os.adminUsername;
in
{
  users.users.${admin}.extraGroups = [ "disk" ];

  services.udev.extraRules = ''
    # Samsung 980 PRO 2 TB containing the BitLocker Windows installation.
    # Match immutable hardware identity, never the enumeration-order nvme1n1.
    SUBSYSTEM=="block", ENV{ID_SERIAL_SHORT}=="S6B0NJ0RB17772A", GROUP="disk", MODE="0660"
    SUBSYSTEM=="block", ENV{ID_SERIAL_SHORT}=="S6B0NJ0RB17772A", KERNEL=="nvme*n*", GROUP="disk", MODE="0660"
  '';

  systemd.services.libvirtd.serviceConfig.SupplementaryGroups = [ "disk" ];

  warnings = [
    ''
      The physical Windows NVMe compatibility module is still active. Its
      libvirt XML is intentionally unmanaged during adoption; retire this module
      only after ncrmro-desktop-windows is verified and deployed on Ocean.
    ''
  ];
}
