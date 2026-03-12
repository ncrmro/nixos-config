{ inputs, ... }:
let
  keys = import ./users/keys.nix;
in
{
  imports = [
    inputs.keystone.nixosModules.operating-system
    inputs.keystone.nixosModules.hardwareKey
  ];

  keystone.hardwareKey = {
    enable = true;
    keys.yubi-black = {
      description = "Primary YubiKey 5 NFC (USB-A, black)";
      sshPublicKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILEOo3uKwbDN1SJemQx8UPVXv0TjKn2VfZSTVFfp3tlcAAAACnNzaDpuY3Jtcm8=";
    };
    keys.yubi-green = {
      description = "Backup YubiKey 5C NFC (USB-C, green sticker)";
      sshPublicKey = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDtwsz3zAJokZ3rnVyXUxmeUGba61b8KIW3u4aE52dK2AAAAFXNzaDpuY3Jtcm8teXViaS1ncmVlbg==";
    };
    rootKeys = [
      "yubi-black"
      "yubi-green"
    ];
    gpgAgent = {
      enable = false;
      enableSSHSupport = false;
    };
  };

  keystone.os = {
    enable = true;
    storage.enable = false; # All hosts use disko
    ssh.enable = false; # SSH configured independently
    secureBoot.enable = false; # Lanzaboote per-host
    tpm.enable = false; # TPM per-host
    hypervisor.enable = true;

    users.ncrmro = {
      fullName = "Nicholas Romero";
      extraGroups = [
        "wheel"
        "media"
        "audio"
        "input"
        "networkmanager"
        "sound"
        "docker"
        "podman"
        "dialout"
      ];
      authorizedKeys = keys.ncrmro;
      hardwareKeys = [ "yubi-black" ];
      terminal.enable = true;
      sshAutoLoad.enable = true;
    };
  };
}
