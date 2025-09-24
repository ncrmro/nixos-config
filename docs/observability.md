# Observability Infrastructure

This document covers the observability stack implementation in the NixOS configuration, including metrics collection with Prometheus/Grafana and centralized logging with Loki/Alloy.

## Architecture Overview

The observability stack consists of three main components:

1. **Metrics Collection**: Prometheus + Grafana for monitoring system and application metrics
2. **Log Aggregation**: Loki for centralized log storage and querying
3. **Data Collection**: Grafana Alloy for unified telemetry data collection

## Prometheus & Grafana (Metrics)

### Components

- **Prometheus**: Time-series database that scrapes metrics from exporters
- **Grafana**: Visualization platform for creating dashboards and alerts
- **Node Exporter**: Collects system-level metrics (CPU, memory, disk, network)
- **AlertManager**: Handles alerts sent by Prometheus

### Configuration

Located at `hosts/common/kubernetes/kube-prometheus-stack.nix`:

- Prometheus retention: 90 days
- Storage: 50Gi on `ocean-nvme` storage class
- Grafana persistence: 10Gi
- Ingress endpoints:
  - Prometheus: https://prometheus.ncrmro.com
  - Grafana: https://grafana.ncrmro.com

### Node Exporters

Deployed on client machines via `hosts/common/optional/monitoring-client.nix`:

- **ncrmro-laptop**: Tailscale IP 100.64.0.1:9100
- **ncrmro-workstation**: Tailscale IP 100.64.0.3:9100

## Loki (Log Aggregation)

### Overview

Loki is a horizontally scalable, highly available log aggregation system inspired by Prometheus. It indexes metadata rather than full-text content, making it cost-effective for long-term log storage.

### Configuration

Located at `hosts/common/kubernetes/loki.nix`:

- **Deployment Mode**: SimpleScalable (separate read/write/backend components)
- **Storage Backend**: MinIO S3-compatible object storage
- **Schema**: TSDB with v13 schema for optimal performance
- **Ingress**: https://loki.ncrmro.com
- **Features**:
  - Pattern ingestion enabled for log pattern detection
  - Structured metadata support
  - Volume-based log queries
  - Snappy compression for chunks

### Storage Classes

- Backend persistence: `ocean-nvme`
- Write component: `ocean-nvme`
- MinIO object storage: `ocean-nvme`

## Grafana Alloy (Data Collection)

### Overview

Grafana Alloy is a vendor-neutral, batteries-included telemetry collector. It replaces the previous Grafana Agent and provides:

- **Log Collection**: System logs, application logs, Kubernetes pod logs
- **Metrics Collection**: Prometheus-compatible metrics scraping
- **Traces Collection**: OpenTelemetry trace data
- **Data Processing**: Filtering, relabeling, and transformation

### Kubernetes Deployment

Located at `hosts/common/kubernetes/alloy.nix`:

- **Helm Chart**: `grafana/alloy` from Grafana Helm repository
- **Namespace**: `monitoring`
- **Log Sources**:
  - Kubernetes pod logs via API
  - System logs from nodes
  - Kubernetes events
- **Destination**: Ships logs to Loki at `loki.ncrmro.com`

### NixOS Client Configuration

Located at `hosts/common/optional/alloy-client.nix`:

- **Service**: `services.alloy.enable = true`
- **Configuration**: System log collection and forwarding
- **Target**: Remote Loki instance via Tailscale network
- **Logs Collected**:
  - System journal logs
  - Application logs
  - Service-specific logs

### Supported Hosts

Alloy clients are deployed on:

- **ncrmro-laptop**: Desktop/laptop system logs
- **ncrmro-workstation**: Workstation system logs  
- **ncrmro-devbox**: Development/testing system logs
- **mercury**: VPS system logs

## Network Architecture

All observability components communicate over the Tailscale mesh network:

- **Kubernetes Cluster**: Accessible via Tailscale ingress
- **Client Nodes**: Connect via Tailscale IPs (100.64.0.x range)
- **Log Shipping**: Encrypted over Tailscale WireGuard tunnels
- **Metrics Scraping**: Secure communication between Prometheus and exporters

## Data Flow

1. **Metrics Path**:
   ```
   Node Exporter → Prometheus → Grafana Dashboards
   ```

2. **Logs Path**:
   ```
   System Logs → Alloy → Loki → Grafana Log Explorer
   ```

3. **Kubernetes Path**:
   ```
   Pod Logs → Alloy (K8s) → Loki → Grafana
   K8s Events → Alloy (K8s) → Loki → Grafana
   ```

## Usage

### Accessing Dashboards

- **Grafana**: https://grafana.ncrmro.com
- **Prometheus**: https://prometheus.ncrmro.com
- **Loki**: https://loki.ncrmro.com (API endpoint)

### Log Querying

Use LogQL (Loki Query Language) in Grafana:

```logql
# View logs from specific host
{host="ncrmro-laptop"}

# Filter by service
{host="ncrmro-workstation"} |= "sshd"

# Error logs across all hosts  
{} |= "ERROR" or {} |= "error"

# Kubernetes pod logs
{namespace="default", container="nginx"}
```

### Common Dashboards

- **Node Exporter Full**: System metrics overview
- **Kubernetes Cluster**: Pod and node metrics
- **Loki Logs**: Centralized log browser
- **Application Specific**: Custom dashboards per service

## Maintenance

### Log Retention

- **Prometheus**: 90 days (configurable)
- **Loki**: Configured for long-term storage in object storage
- **Grafana**: Dashboard and configuration persistence

### Storage Management

Monitor storage usage on `ocean-nvme` storage class:
- Prometheus: 50Gi allocation
- Loki components: Expandable persistent volumes
- Grafana: 10Gi for dashboards and settings

### Updates

Update Helm chart versions in respective NixOS modules:
- `kube-prometheus-stack.nix`: Prometheus stack updates
- `loki.nix`: Loki version updates  
- `alloy.nix`: Alloy collector updates