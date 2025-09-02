{
  config,
  lib,
  pkgs,
  ...
}: {
  services.tailscale = {
    enable = true;

    # By default, automatically connect to your tailnet
    # Set this to false if you want to manually connect with 'tailscale up'
    useRoutingFeatures = lib.mkDefault "client";

    # Additional arguments for tailscale daemon
    extraUpFlags = [
      # Uncomment and modify for use with Headscale
      "--login-server=https://mercury.ncrmro.com"
    ];
  };

  # Install the tailscale package
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Open firewall for Tailscale
  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
  };

  # Optional: Enable IP forwarding for Tailscale subnet routing and exit nodes
  # boot.kernel.sysctl = {
  #   "net.ipv4.ip_forward" = 1;
  #   "net.ipv6.conf.all.forwarding" = 1;
  # };
}
