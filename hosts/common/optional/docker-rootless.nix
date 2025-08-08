{ pkgs, lib, ... }:
{
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    docker = {
      enable = lib.mkForce false;
      rootless = {
        enable = true;
        setSocketVariable = true;
        daemon.settings = {
          dns = [ "1.1.1.1" "8.8.8.8" ];
          #registry-mirrors = [ "https://mirror.gcr.io" ];
          experimental = true;
          features = {
            buildkit = true;
            
          };
        };
      };
      
    };
  };

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
    #podman-compose # start group of containers for dev
  ];
  
  # Needed for default bridge network to automatically work
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.ip_forward" = 1;
}