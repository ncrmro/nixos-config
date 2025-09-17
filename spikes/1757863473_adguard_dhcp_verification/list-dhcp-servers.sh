#!/usr/bin/env bash

# Simple script to discover DHCP servers on the network

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NETWORK="${NETWORK:-192.168.1.0/24}"
INTERFACE="${INTERFACE:-enp192s0}"

log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[FOUND]${NC} $1"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_dependencies() {
  local deps=("nmap")
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done

  if [ ${#missing[@]} -ne 0 ]; then
    echo "Missing dependencies: ${missing[*]}"
    echo "Install with: nix-shell -p ${missing[*]}"
    exit 1
  fi
}

discover_dhcp_servers() {
  echo "Discovering DHCP servers on network $NETWORK..."
  echo "=============================================="
  echo

  # Check if running as root
  if [ "$EUID" -eq 0 ]; then
    log "Running with root privileges - full discovery available"

    # Method 1: DHCP Discovery broadcast
    log "Sending DHCP discover broadcast..."
    if sudo nmap --script broadcast-dhcp-discover 2>/dev/null | grep -A 20 "broadcast-dhcp-discover:"; then
      echo
    else
      warning "No DHCP servers responded to broadcast discover"
      echo
    fi

    # Method 2: Scan for DHCP server ports
    log "Scanning for open DHCP ports (UDP 67)..."
    local dhcp_hosts
    if dhcp_hosts=$(sudo nmap -sU -p 67 --open "$NETWORK" 2>/dev/null | grep -B 2 "67/udp open" | grep "Nmap scan report" | awk '{print $5}'); then
      if [ -n "$dhcp_hosts" ]; then
        while read -r host; do
          success "DHCP server found at: $host"
        done <<<"$dhcp_hosts"
      else
        warning "No hosts found with open DHCP port 67"
      fi
    else
      warning "Could not scan for DHCP ports"
    fi
    echo

    # Method 3: Check specific known hosts
    log "Checking known potential DHCP servers..."
    local known_hosts=("192.168.1.1" "192.168.1.10" "192.168.1.254")

    for host in "${known_hosts[@]}"; do
      if sudo nmap -sU -p 67 --open "$host" 2>/dev/null | grep -q "67/udp open"; then
        success "DHCP server confirmed at: $host"
      fi
    done
  else
    warning "Not running as root - limited discovery available"
    log "For full DHCP discovery, run: sudo $0"
    echo

    # Method 1: DHCP Discovery broadcast (try without sudo first)
    log "Attempting DHCP discover broadcast (may require sudo)..."
    if nmap --script broadcast-dhcp-discover 2>/dev/null | grep -A 20 "broadcast-dhcp-discover:"; then
      echo
    else
      log "Trying with sudo..."
      if sudo nmap --script broadcast-dhcp-discover 2>/dev/null | grep -A 20 "broadcast-dhcp-discover:"; then
        echo
      else
        warning "No DHCP servers responded to broadcast discover"
        echo
      fi
    fi

    # Method 2: TCP connect scan (doesn't require root)
    log "Checking for services on known DHCP server IPs..."
    local known_hosts=("192.168.1.1" "192.168.1.10" "192.168.1.254")

    for host in "${known_hosts[@]}"; do
      # Check if host is reachable
      if ping -c 1 -W 1 "$host" &>/dev/null; then
        success "Host reachable: $host (potential DHCP server)"
      fi
    done
  fi
}

show_network_info() {
  echo
  log "Current network configuration:"
  echo "Network: $NETWORK"
  echo "Interface: $INTERFACE"

  if command -v ip &>/dev/null; then
    echo
    log "Current IP configuration:"
    ip addr show "$INTERFACE" 2>/dev/null || warning "Interface $INTERFACE not found"

    echo
    log "Current default gateway:"
    ip route show default 2>/dev/null || warning "No default route found"
  fi
}

main() {
  echo "DHCP Server Discovery"
  echo "===================="
  echo

  check_dependencies
  show_network_info
  echo
  discover_dhcp_servers

  echo "Discovery complete!"
  echo
  echo "To monitor DHCP traffic in real-time (requires root):"
  echo "  sudo tcpdump -i $INTERFACE port 67 or port 68"
}

# Handle command line arguments
case "${1:-}" in
--help | -h)
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --help, -h          Show this help"
  echo "  --network CIDR      Set network range (default: 192.168.1.0/24)"
  echo "  --interface IFACE   Set network interface (default: enp4s0)"
  echo
  echo "Environment variables:"
  echo "  NETWORK             Network range"
  echo "  INTERFACE           Network interface"
  exit 0
  ;;
--network)
  NETWORK="$2"
  shift 2
  ;;
--interface)
  INTERFACE="$2"
  shift 2
  ;;
esac

main "$@"
