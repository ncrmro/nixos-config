{ pkgs }:
pkgs.writeShellApplication {
  name = "keystone-physical-migration";
  # The wrapped script's generated PATH prefix precedes its file-level
  # ShellCheck directive. These two checks are intentional: SC2016 is jq
  # syntax, and SC2029 covers commands already escaped with printf %q.
  excludeShellChecks = [
    "SC2016"
    "SC2029"
  ];
  runtimeInputs = with pkgs; [
    coreutils
    diffutils
    findutils
    freerdp
    gawk
    gh
    git
    gnugrep
    gnused
    jq
    libvirt
    netcat-openbsd
    nix
    openssh
    rsync
    systemd
    util-linux
    virt-viewer
    zfs
  ];
  text = builtins.readFile ../../bin/keystone-physical-migration;
}
