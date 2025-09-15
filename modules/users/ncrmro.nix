{config, ...}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.users.ncrmro = {
    isNormalUser = true;
    extraGroups =
      [
        "wheel"
      ]
      ++ ifTheyExist [
        "media"
        "audio"
        "input"
        "networkmanager"
        "sound"
        "docker"
        "podman"
      ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
    ];
  };
}
