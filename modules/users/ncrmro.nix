{...}: {
  users.users.ncrmro = {
    isNormalUser = true;
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
    ];
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "sound"
      "tty"
      "wheel"
      "docker"
    ];
  };
}
