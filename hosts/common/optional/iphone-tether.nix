{ pkgs, ... }:
{
  # iPhone USB tethering support
  environment.systemPackages = [
    pkgs.libimobiledevice
  ];

  # USB multiplexer daemon needed for iOS device communication
  services.usbmuxd.enable = true;
}
