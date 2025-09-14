{...}: {
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    openFirewall = true;
    allowDHCP = true;
  };

  # Open firewall ports for DNS and DHCP
  networking.firewall = {
    allowedTCPPorts = [
      53 # DNS
      # 3000  # AdGuard Home web interface - listening on Tailscale interface only
    ];
    allowedUDPPorts = [
      53 # DNS
      67 # DHCP server
      68 # DHCP client
    ];
  };
}
