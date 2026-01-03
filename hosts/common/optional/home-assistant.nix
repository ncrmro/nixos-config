{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.home-assistant = {
    enable = true;
    openFirewall = false;
    extraComponents = [
      # List of integrations: https://www.home-assistant.io/integrations/
      "met"
      "radio_browser"
      "homekit"
      "homekit_controller"
      "apple_tv"
      "brother"
      "google_translate"
      "hue"
      "ipp"
      "spotify"
      "zha" # Native Zigbee Home Automation
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };

      homekit = {
        filter = {
          exclude_domains = [
            "light"
          ];
        };
      };

      # Removed debug logging for HomeKit:
      # logger = {
      #   default = "info";
      #   logs = {
      #     "homeassistant.components.homekit" = "debug";
      #     "pyhap" = "debug";
      #   };
      # };

      homekit = {
        advertise_ip = "192.168.1.10";
      };

      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
        # Trust proxies for ingress
        trusted_proxies = [
          "127.0.0.1"
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

  networking.firewall.allowedTCPPorts = [
    21063 # Home Assistant HomeKit extension
  ];

  networking.firewall.allowedUDPPorts = [
    5353 # mDNS/Bonjour service discovery
  ];

  # ---------------------------------------------------------------------------
  # Matter Server
  # ---------------------------------------------------------------------------
  # SECURITY: Matter Server WebSocket is bound to localhost.
  # Home Assistant connects to it locally via ws://localhost:5580/ws
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  services.matter-server = {
    enable = true;
    port = 5580;
  };
}
