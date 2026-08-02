{pkgs, ...}: let
  ripDisc = pkgs.writeShellApplication {
    name = "rip-disc";
    runtimeInputs = [
      pkgs.eject
      pkgs.makemkv
    ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${../../bin/rip-disc} "$@"
    '';
  };
in {
  # MakeMKV opens both /dev/sr* and the drive's /dev/sg* interface.
  boot.kernelModules = ["sg"];

  environment.systemPackages = [ripDisc];

  # MakeMKV needs both the optical block device and its SCSI generic device.
  services.udev.extraRules = ''
    SUBSYSTEM=="block", KERNEL=="sr[0-9]*", GROUP="cdrom", MODE="0660"
    SUBSYSTEM=="scsi_generic", ATTRS{type}=="5", GROUP="cdrom", MODE="0660"
  '';

  users.users.ncrmro.extraGroups = ["cdrom"];
}
