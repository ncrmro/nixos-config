{ inputs, ... }:
{
  imports = [
    inputs.keystone.nixosModules.desktop
    inputs.keystone.nixosModules.hardwareKey
  ];

  keystone.desktop = {
    enable = true;
    user = "ncrmro";
  };

  # YubiKey support (pcscd, age-plugin-yubikey, ykman)
  # GPG agent disabled to avoid SSH_AUTH_SOCK conflict with OpenSSH agent
  keystone.hardwareKey = {
    enable = true;
    gpgAgent = {
      enable = false;
      enableSSHSupport = false;
    };
  };
}
