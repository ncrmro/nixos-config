# Shared agent identity declarations.
# Import this on every host that needs to know about agents — either to
# create OS users (workstation) or to provision service accounts (ocean).
{ ... }:
{
  keystone.os.agents = {
    drago = {
      host = "ncrmro-workstation";
      fullName = "Drago";
      email = "drago@ncrmro.com";
      ssh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9TbHc93b0RWSekJcUmlDkw0UulfzkbJqdd0ejfuV2C agent-drago";
      mail.provision = true;
      git.provision = true;
    };
    # luce = {
    #   host = "ocean";
    #   fullName = "Luce";
    #   email = "luce@ncrmro.com";
    #   ssh.publicKey = "ssh-ed25519 AAAA...";
    #   mail.provision = true;
    #   git.provision = true;
    # };
  };
}
