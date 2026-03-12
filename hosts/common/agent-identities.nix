# Shared agent identity declarations.
#
# Import this on every host that needs to know about agents. The `host`
# field controls WHERE feature-specific resources land:
#
#   - agent's host (e.g. workstation): SSH keys, desktop, mail client (himalaya)
#   - server host (e.g. ocean):        mail/git account provisioning (via mail.provision / git.provision)
#   - ALL importing hosts:             OS user account + home directory
#
# Agenix note: secrets like agent-{name}-mail-password need recipients on
# BOTH the agent's host AND the server host. See agenix-secrets/secrets.nix.
{ ... }:
{
  keystone.os.agents = {
    drago = {
      host = "ncrmro-workstation";
      fullName = "Drago";
      email = "drago@ncrmro.com";
      ssh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9TbHc93b0RWSekJcUmlDkw0UulfzkbJqdd0ejfuV2C agent-drago";
      mail.provision = true; # provision Stalwart account on server host (ocean)
      git.provision = true; # provision Forgejo account on server host (ocean)
    };
    luce = {
      host = "ocean";
      fullName = "Luce";
      email = "luce@ncrmro.com";
      ssh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+jItdMeX71E3PxfxP+LH2yFXKHxrpPqeJpoRHkLecg agent-luce";
      mail.provision = true;
      git.provision = true;
    };
  };
}
