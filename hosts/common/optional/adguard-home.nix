{...}: {
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    openFirewall = true;
  };
}
