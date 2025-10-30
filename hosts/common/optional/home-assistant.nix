{
  config,
  lib,
  pkgs,
  ...
}: {
  services.home-assistant = {
    enable = true;
    openFirewall = false;
    extraComponents = [
      # List of integrations: https://www.home-assistant.io/integrations/
      "met"
      "radio_browser"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};

      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
        # Trust proxies for ingress
        trusted_proxies = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
        ];
        use_x_forwarded_for = true;
      };
    };
  };

  # Open port on tailscale interface only
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      8123 # Home Assistant
    ];
  };
}
