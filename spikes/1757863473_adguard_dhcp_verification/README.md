# AdGuard DHCP Server Verification Spike

This spike creates a comprehensive verification script to test AdGuard Home DHCP server functionality.

## Overview

AdGuard Home is configured on the `ocean` host (192.168.1.10) with DHCP server capabilities enabled. This spike provides tools to verify that the DHCP server is working correctly after deployment.

## Current Configuration

From `hosts/common/optional/adguard-home.nix`:
```nix
services.adguardhome = {
  enable = true;
  mutableSettings = true;
  openFirewall = true;
  allowDHCP = true;
};
```

The `ocean` host imports this configuration and has a static IP of 192.168.1.10.

## Verification Script

The `verify-dhcp.sh` script performs comprehensive DHCP server testing:

### Features

1. **Dependency Checks**: Ensures required tools are available (nmap, dig, dhcpdump, curl, ip)
2. **DHCP Server Discovery**: Multiple methods to detect DHCP servers on the network
3. **AdGuard Status**: Checks if AdGuard Home is accessible and running
4. **DHCP Configuration**: Retrieves DHCP settings from AdGuard API
5. **DNS Resolution**: Tests DNS and ad-blocking functionality
6. **Network Interface Inspection**: Shows current IP configuration and routing
7. **DHCP Lease Testing**: Experimental network namespace testing for DHCP leases

### Usage

```bash
# Basic usage
./verify-dhcp.sh

# With custom parameters
ADGUARD_HOST=192.168.1.10 INTERFACE=enp4s0 ./verify-dhcp.sh

# Command line options
./verify-dhcp.sh --adguard-host 192.168.1.10 --interface enp4s0 --network 192.168.1.0/24

# Run with root for complete testing
sudo ./verify-dhcp.sh
```

### DHCP Discovery Methods

The script uses multiple approaches to discover DHCP servers:

1. **DHCP Broadcast Discovery**: Uses nmap's `broadcast-dhcp-discover` script
2. **Traffic Monitoring**: Listens for DHCP packets with dhcpdump (requires root)
3. **Port Scanning**: Scans network for open UDP port 67 (DHCP server port)

### Dependencies

Required tools (install with `nix-shell -p <tools>`):
- `nmap`: Network scanning and DHCP discovery
- `dig`: DNS testing
- `dhcpdump`: DHCP packet capture
- `curl`: API communication with AdGuard
- `ip`: Network interface management

## Expected Results

When AdGuard DHCP is working correctly, you should see:

- ✅ AdGuard Home accessible at 192.168.1.10:3000
- ✅ DHCP server enabled in AdGuard configuration
- ✅ DNS resolution working through AdGuard
- ✅ Ad blocking functionality active
- ✅ DHCP server detected on network scans

## Resolution

### Firewall Configuration Required

The main issue was that firewall ports needed to be opened for DHCP functionality. Updated `hosts/common/optional/adguard-home.nix` to include:

```nix
# Open firewall ports for DNS and DHCP
networking.firewall = {
  allowedTCPPorts = [
    53    # DNS
  ];
  allowedUDPPorts = [
    53    # DNS
    67    # DHCP server
    68    # DHCP client
  ];
};
```

### Quick Verification

The simplest way to verify DHCP server is working:
```bash
sudo nmap --script broadcast-dhcp-discover
```

## Troubleshooting

### Common Issues

1. **AdGuard not accessible**: Check if service is running and firewall is open
2. **DHCP not enabled**: Configure DHCP through AdGuard web interface  
3. **DHCP not working**: Ensure firewall ports 67/68 UDP are open (see Resolution above)
4. **Missing dependencies**: Run `nix-shell -p nmap dig dhcpdump curl iproute2`
5. **Permission issues**: Some tests require root privileges

### Manual Verification Commands

```bash
# Check AdGuard status directly
curl -s http://192.168.1.10:3000/control/status | python3 -m json.tool

# Check DHCP configuration
curl -s http://192.168.1.10:3000/control/dhcp/status | python3 -m json.tool

# Monitor DHCP traffic
sudo dhcpdump -i enp4s0

# Test DHCP discovery
sudo nmap --script broadcast-dhcp-discover
```

## Integration with NixOS Build

This verification script can be integrated into deployment workflows:

1. Add to system packages for easy access
2. Run as part of post-deployment testing
3. Include in monitoring/health checks
4. Use in CI/CD pipelines for infrastructure validation

## Next Steps

1. Test the script on the current AdGuard deployment
2. Integrate with existing deployment scripts in `/bin/`
3. Add to system packages or create a NixOS module for easy inclusion
4. Consider adding continuous monitoring capabilities