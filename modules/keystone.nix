{ inputs, lib, ... }:
let
  keys = import ./users/keys.nix;
in
{
  imports = [
    inputs.keystone.nixosModules.operating-system
    inputs.keystone.nixosModules.hardwareKey
  ];

  keystone.hardwareKey = {
    enable = lib.mkDefault true;
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
      enable = lib.mkDefault false;
      enableSSHSupport = lib.mkDefault false;
    };
  };

  keystone.os = {
    enable = lib.mkDefault true;
    secretsBasePath = inputs.agenix-secrets;
    storage.enable = lib.mkDefault false; # All hosts use disko
    ssh.enable = lib.mkDefault false; # SSH configured independently
    hypervisor.enable = lib.mkDefault true;

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
      terminal.enable = lib.mkDefault true;
      sshAutoLoad.enable = lib.mkDefault true;
    };
  };
}
