let
  # SSH public keys for users and systems
  users = {
    ncrmro = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k";
  };

  systems = {
    ocean = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7Oo3b71YDnN2i3vOsXrE4PFhmByjCIW5YtH7VkrTtC";
  };

  # Convenience aliases for common key combinations
  adminKeys = [users.ncrmro];
  k3sServers = [systems.ocean];
in {
  # K3s server token - accessible by admin and K3s server nodes
  "k3s-server-token.age".publicKeys = adminKeys ++ k3sServers;
}
