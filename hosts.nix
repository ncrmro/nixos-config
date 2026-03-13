# hosts.nix — Host registry for `ks build` and `ks update`.
#
# This file is the single source of truth for host identity and connection details.
# - NixOS modules: imported via hosts/common/global/default.nix
# - Shell scripts: read via `nix eval -f hosts.nix --json <host>`
#
# Keys MUST match nixosConfigurations names in flake.nix.
# The hostname field MUST match the host's networking.hostName.
#
# Caching workflow:
#   Build on workstation or ocean first — their attic binary cache push
#   (keystone.binaryCache.push) automatically populates the shared cache.
#   Low-power machines (laptop, maia) then pull cached derivations during
#   their deploy, avoiding expensive local compilation.
#
#   Recommended order:
#     ks build ncrmro-workstation && ks build ocean
#     ks update ncrmro-laptop && ks update maia
{
  ocean = {
    hostname = "ocean";
    sshTarget = "ocean.mercury";
    fallbackIP = "192.168.1.10";
    buildOnRemote = true;
  };
  mercury = {
    hostname = "mercury";
    sshTarget = "216.128.136.32";
    buildOnRemote = false;
  };
  maia = {
    hostname = "maia";
    sshTarget = "maia.mercury";
    buildOnRemote = true;
  };
  ncrmro-workstation = {
    hostname = "ncrmro-workstation";
    sshTarget = "ncrmro-workstation.mercury";
    buildOnRemote = true;
  };
  ncrmro-laptop = {
    hostname = "ncrmro-laptop";
    sshTarget = null;
    buildOnRemote = false;
  };
  devbox = {
    hostname = "ncrmro-devbox";
    sshTarget = "ncrmro-devbox.mercury";
    buildOnRemote = false;
  };
  catalystPrimary = {
    hostname = "catalyst-primary";
    sshTarget = "144.202.67.5";
    buildOnRemote = false;
  };
}
