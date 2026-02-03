{
  pkgs,
  lib,
  ...
}:
{
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    docker.enable = lib.mkForce false;
    podman = {
      enable = true;

      dockerSocket.enable = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  # networking.firewall.interfaces."podman+".allowedUDPPorts = [53 5353];

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    #podman-tui # status of containers in the terminal
    # Needed because podman doesn't support buildkit but uses podman via dockerSocket.enable = true;
    docker-compose # start group of containers for dev

    # podman compose rather than podman-compose seems to be a better option
    # podman-compose # start group of containers for dev
  ];
}
