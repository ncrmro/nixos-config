{
  pkgs,
  config,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.ncrmro = {
    isNormalUser = true;
    # shell = pkgs.fish;
    extraGroups =
      [
        "wheel"
        # "video"
        # "audio"
        # "adbusers"
        # "kvm"
        # "adbgroup"
      ]
      ++ ifTheyExist [
        # "network"
        # "networkmanager"
        # "wireshark"
        # "git"
        # "libvirtd"
        # "docker"
        # "kvm"
      ];

    openssh.authorizedKeys.keys = [
      # (builtins.readFile ../ssh.pub)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
    ];
    packages = [
      pkgs.home-manager
    ];
  };
}
