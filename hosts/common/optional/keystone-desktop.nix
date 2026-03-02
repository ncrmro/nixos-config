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

    keys.yubi-black = {
      description = "Primary YubiKey 5 NFC (USB-A, black)";
      sshPublicKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILEOo3uKwbDN1SJemQx8UPVXv0TjKn2VfZSTVFfp3tlcAAAACnNzaDpuY3Jtcm8=";
    };

    rootKeys = [ "yubi-black" ];

    gpgAgent = {
      enable = false;
      enableSSHSupport = false;
    };
  };
}
