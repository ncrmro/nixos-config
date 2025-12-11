# OctoPrint - Web interface for 3D printers
# Only accessible via Tailscale IP for security
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Ocean's Tailscale IP address
  tailscaleIP = "100.64.0.6";
in
{
  # Override octoprint package to add custom plugins
  nixpkgs.overlays = [
    (final: prev: {
      octoprint = prev.octoprint.override {
        packageOverrides = pyself: pysuper: {
          # paho-mqtt v1.x - BambuPrinter requires paho-mqtt<2
          paho-mqtt_1 = pyself.buildPythonPackage rec {
            pname = "paho-mqtt";
            version = "1.6.1";
            pyproject = true;

            src = final.fetchFromGitHub {
              owner = "eclipse";
              repo = "paho.mqtt.python";
              rev = "v${version}";
              hash = "sha256-9nH6xROVpmI+iTKXfwv2Ar1PAmWbEunI3HO0pZyK6Rg=";
            };

            build-system = [ pyself.setuptools ];

            doCheck = false;
          };

          # pybambu - Python library for Bambu Lab Printers
          pybambu = pyself.buildPythonPackage rec {
            pname = "pybambu";
            version = "1.0.1";
            pyproject = true;

            src = final.fetchFromGitHub {
              owner = "greghesp";
              repo = "pybambu";
              rev = version;
              hash = "sha256-VAif36yGYGnXEmwAnFeirW5ih6ncF8+6rvjJHMRDrqw=";
            };

            build-system = [ pyself.setuptools ];

            dependencies = [
              pyself.paho-mqtt_1
              pyself.python-dateutil
            ];

            doCheck = false;
          };

          # OctoPrint-BambuPrinter plugin
          octoprint-bambuprinter = pyself.buildPythonPackage rec {
            pname = "OctoPrint-BambuPrinter";
            version = "0.1.7";
            pyproject = true;

            src = final.fetchFromGitHub {
              owner = "jneilliii";
              repo = "OctoPrint-BambuPrinter";
              rev = version;
              hash = "sha256-GHkcBkPtclIjl183mKX+G1PrjgKG9DBS7aRR8/X/WwM=";
            };

            build-system = [ pyself.setuptools ];

            dependencies = [
              pysuper.octoprint
              pyself.pybambu
            ];

            doCheck = false;
          };
        };
      };
    })
  ];

  services.octoprint = {
    enable = true;
    # Bind only to Tailscale interface
    host = tailscaleIP;
    port = 5000;
    # Don't open firewall globally - we configure Tailscale-only access below
    openFirewall = false;

    # Enable BambuPrinter plugin
    plugins =
      plugins: with plugins; [
        octoprint-bambuprinter
      ];
  };

  # Open firewall only on Tailscale interface
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 5000 ];
  };

  # Allow octoprint user to access USB devices (for 3D printer communication)
  users.users.octoprint.extraGroups = [ "dialout" ];
}
