let
  # SSH public keys for users and systems
  users = {
    ncrmro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k";
  };

  systems = {
    ocean = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7Oo3b71YDnN2i3vOsXrE4PFhmByjCIW5YtH7VkrTtC";
    maia = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAtdLpd4fI4U4JSQeo0z/m2KdB+qAGyURSPko7/1BCIa";
    mercury = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK80XMxx82fVvZgZ5djaXKvy1fRriQwkO4OAtf65ElhU";
    workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMalqC7xISpPwp7pPHcx8Qc3eiA1LOqJAmflFlHH0oCw";
    laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdFyolB6Fb6z8r+38nsqDig9II1D400COykJPUs2G18";
  };

  # Convenience aliases for common key combinations
  adminKeys = [ users.ncrmro ];
  desktops = [
    systems.workstation
    systems.laptop
  ];
  k3sServers = [ systems.ocean ]; # Only server nodes
  k3sAgents = [ systems.maia ]; # Only agent nodes
in
{
  # K3s server token - accessible by admin and K3s server nodes only
  "secrets/k3s-server-token.age".publicKeys = adminKeys ++ k3sServers;

  # K3s agent token - accessible by admin and K3s agent nodes only
  "secrets/k3s-agent-token.age".publicKeys = adminKeys ++ k3sAgents;

  # Cloudflare API token for ACME DNS-01 challenge
  "secrets/cloudflare-api-token.age".publicKeys = adminKeys ++ [
    systems.mercury
    systems.ocean
  ];

  # SABnzbd usenet server configuration (contains credentials)
  "secrets/sabnzbd-servers.age".publicKeys = adminKeys ++ [ systems.ocean ];

  # Samba Time Machine password
  "secrets/samba-timemachine-password.age".publicKeys = adminKeys ++ [ systems.ocean ];

  # Stalwart admin password (ocean mail server)
  "secrets/stalwart-admin-password.age".publicKeys = adminKeys ++ [ systems.ocean ];

  # Stalwart mail user password (for himalaya client on desktops)
  "secrets/stalwart-mail-ncrmro-password.age".publicKeys = adminKeys ++ desktops;
}
