# DNS Architecture Documentation

This document outlines the multi-layered DNS architecture used across the infrastructure, covering local network, VPN, and public DNS resolution.

## DNS Layers Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Public DNS    │    │   Tailscale DNS  │    │   Local DNS     │
│   (Cloudflare)  │    │   (Headscale)    │    │   (AdGuard)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    WAN Access              VPN Devices              Home LAN
   (Internet Users)        (100.64.x.x/10)         (192.168.x.x)
```

## DNS Resolution Hierarchy

### 1. Local Network DNS (AdGuard on Ocean)
**Purpose**: Primary DNS for devices on the home LAN  
**Server**: Hosted on Ocean (ocean.mercury)  
**Network**: 192.168.x.x subnet  
**Features**:
- Ad blocking and content filtering
- Local domain resolution
- Upstream forwarding to public DNS
- Custom local records for internal services

**Local DNS Records**:
```
ocean.mercury        -> 192.168.1.x (direct LAN IP)
jellyfin.local       -> 192.168.1.x (direct access for performance)
grafana.local        -> 192.168.1.x (local access only)
prometheus.local     -> 192.168.1.x (local access only)
```

### 2. Tailscale/Headscale DNS
**Purpose**: DNS resolution for VPN-connected devices  
**Server**: Headscale server on Mercury  
**Network**: 100.64.0.0/10 (Tailscale subnet)  
**Features**:
- Automatic device name resolution
- Split DNS for internal vs external domains
- MagicDNS for seamless connectivity

**VPN DNS Records**:
```
ocean                -> 100.64.0.6 (Tailscale IP)
mercury              -> 100.64.0.x (Headscale server)
laptop               -> 100.64.0.x (VPN client)
```

### 3. Public DNS (Cloudflare)
**Purpose**: External/WAN access to public services  
**Provider**: Cloudflare DNS  
**Domain**: ncrmro.com and related domains  
**Features**:
- Global CDN and DDoS protection
- SSL/TLS termination
- Geographic load balancing

**Public DNS Records**:
```
ncrmro.com           -> Public WAN IP (available globally)
jellyfin.ncrmro.com  -> Public WAN IP (WAN access)
blog.ncrmro.com      -> Public WAN IP (available globally)
```

## Service Access Patterns

### Publicly Available Services
Services accessible from all network layers:

| Service | Local Access | VPN Access | Public Access | Notes |
|---------|-------------|------------|---------------|--------|
| ncrmro.com | ✅ Direct LAN | ✅ Tailscale | ✅ Internet | Personal website |
| Blog | ✅ Direct LAN | ✅ Tailscale | ✅ Internet | Public content |

### Hybrid Access Services
Services with different access patterns by network:

| Service | Local Access | VPN Access | Public Access | Implementation |
|---------|-------------|------------|---------------|----------------|
| Jellyfin | ✅ Direct IP (192.168.1.x) | ✅ Tailscale IP | ✅ jellyfin.ncrmro.com | DNS split-brain |

**Jellyfin Access Strategy**:
- **Local LAN**: Direct connection to `192.168.1.x` for maximum performance
- **VPN Users**: Access via Tailscale IP `100.64.0.6`
- **Public**: Access via `jellyfin.ncrmro.com` through WAN

### VPN-Only Services
Services restricted to VPN access only:

| Service | Local Access | VPN Access | Public Access | Security |
|---------|-------------|------------|---------------|----------|
| Grafana | ✅ grafana.local | ✅ Tailscale | ❌ Blocked | Ingress subnet restriction |
| Prometheus | ✅ prometheus.local | ✅ Tailscale | ❌ Blocked | Ingress subnet restriction |
| AdGuard Admin | ✅ Direct LAN | ✅ Tailscale | ❌ Blocked | Admin interface |

## Network Security Implementation

### Ingress Nginx Subnet Restrictions
VPN-only services are protected using ingress-nginx annotations:

```yaml
nginx.ingress.kubernetes.io/whitelist-source-range: "192.168.0.0/16,100.64.0.0/10"
```

**Allowed Subnets**:
- `192.168.0.0/16`: Home LAN networks
- `100.64.0.0/10`: Tailscale/Headscale VPN network

### DNS Poisoning Prevention
- Local AdGuard filters malicious domains
- Headscale provides authenticated DNS resolution
- Cloudflare provides DDoS protection for public domains

## DNS Configuration Examples

### AdGuard Custom DNS Records
```
# Local service resolution
ocean.mercury        A    192.168.1.100
jellyfin.local       A    192.168.1.100
grafana.local        A    192.168.1.100
prometheus.local     A    192.168.1.100

# Upstream forwarding
*.ncrmro.com         ->   Cloudflare DNS
```

### Headscale DNS Configuration
```yaml
dns_config:
  override_local_dns: true
  nameservers:
    - 1.1.1.1
    - 1.0.0.1
  domains:
    - tailscale-domain.ts.net
  magic_dns: true
  base_domain: headscale.mercury
```

### Cloudflare DNS Records
```
Type  Name              Content            TTL
A     ncrmro.com        203.0.113.1        Auto
A     jellyfin          203.0.113.1        Auto
A     *.ncrmro.com      203.0.113.1        Auto
```

## Troubleshooting DNS Issues

### Common DNS Resolution Paths

1. **Local Device Query**:
   ```
   Device → AdGuard (ocean.mercury) → Cloudflare → Response
   ```

2. **VPN Device Query**:
   ```
   VPN Device → Headscale DNS → Cloudflare → Response
   ```

3. **Public Query**:
   ```
   Internet → Cloudflare → WAN IP → Router → Ocean
   ```

### DNS Testing Commands

```bash
# Test local DNS resolution
nslookup jellyfin.local 192.168.1.100

# Test VPN DNS resolution
nslookup ocean 100.64.0.1

# Test public DNS resolution
nslookup ncrmro.com 1.1.1.1

# Test ingress restrictions
curl -H "Host: grafana.ncrmro.com" http://ocean.mercury
```

## Maintenance Notes

### Updating DNS Records
1. **Local Records**: Update AdGuard admin interface
2. **VPN Records**: Managed automatically by Headscale
3. **Public Records**: Update via Cloudflare API or dashboard

### Certificate Management
- **Local**: Self-signed or local CA certificates
- **VPN**: Headscale manages internal certificates
- **Public**: Let's Encrypt via cert-manager in Kubernetes

### Backup Considerations
- AdGuard configuration backup
- Headscale database backup
- Cloudflare zone file exports