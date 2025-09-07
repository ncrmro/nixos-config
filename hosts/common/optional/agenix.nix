{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Install agenix CLI for secret management
  environment.systemPackages = [
    inputs.agenix.packages.x86_64-linux.default
  ];

  # Age configuration
  age = {
    # Secrets will be owned by root with mode 0400 by default
    # Individual secrets can override these settings
  };
}