# hosts.nix — Host registry for `ks build` and `ks update`.
#
# This file is the single source of truth for host identity and connection details.
# - NixOS modules: imported via hosts/common/global/default.nix
# - Shell scripts: read via `nix eval -f hosts.nix --json <host>`
#
# Keys MUST match nixosConfigurations names in flake.nix.
# The hostname field MUST match the host's networking.hostName.
#
{
  ocean = {
    hostname = "ocean";
    sshTarget = "ocean.mercury";
    fallbackIP = "192.168.1.10";
    role = "server";
    buildOnRemote = true;
  };
  mercury = {
    hostname = "mercury";
    sshTarget = "216.128.136.32";
    role = "server";
    buildOnRemote = false;
  };
  maia = {
    hostname = "maia";
    sshTarget = "maia.mercury";
    role = "server";
    buildOnRemote = true;
  };
  mox = {
    hostname = "mox";
    sshTarget = "mox.mercury";
    role = "client";
    buildOnRemote = true;
  };
  ncrmro-workstation = {
    hostname = "ncrmro-workstation";
    sshTarget = "ncrmro-workstation.mercury";
    role = "client";
    buildOnRemote = true;
  };
  ncrmro-laptop = {
    hostname = "ncrmro-laptop";
    sshTarget = null;
    role = "client";
    buildOnRemote = false;
  };
  devbox = {
    hostname = "ncrmro-devbox";
    sshTarget = "ncrmro-devbox.mercury";
    role = "client";
    buildOnRemote = false;
  };
  catalystPrimary = {
    hostname = "catalyst-primary";
    sshTarget = "144.202.67.5";
    role = "server";
    buildOnRemote = false;
  };
  test-vm = {
    hostname = "test-vm";
    sshTarget = null;
    role = "client";
    buildOnRemote = false;
  };
  testbox = {
    hostname = "testbox";
    sshTarget = null;
    role = "client";
    buildOnRemote = false;
  };
  build-vm-desktop = {
    hostname = "build-vm-desktop";
    sshTarget = null;
    role = "client";
    buildOnRemote = false;
  };
}
