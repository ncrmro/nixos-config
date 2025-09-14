# Kubernetes SSL Certificate Management

This document outlines the SSL certificate management strategy using cert-manager with Cloudflare DNS-based validation for automatic certificate provisioning in the Kubernetes cluster.

## Overview

The SSL certificate infrastructure uses:
- **cert-manager**: Automated certificate provisioning and renewal
- **Cloudflare DNS**: DNS-01 challenge validation
- **Let's Encrypt**: Certificate Authority (CA)
- **ingress-nginx**: Default SSL certificate handling

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │   cert-manager   │    │  ingress-nginx  │
│   DNS Provider  │◄───┤   Controller     │────►│   Controller    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    DNS-01 Challenge         Certificate              SSL Termination
    Validation               Management               & Routing
```

## ClusterIssuer Configuration

### Cloudflare ClusterIssuer

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cloudflare
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@ncrmro.com
    privateKeySecretRef:
      name: letsencrypt-cloudflare-private-key
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

### Required Secrets

#### Creating the Cloudflare API Token Secret

Before the ClusterIssuer can function, you must manually create the Cloudflare API token secret:

```bash
# Create the secret with your Cloudflare API token
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token=<your-cloudflare-api-token> \
  --namespace=kube-system

# Verify the secret was created
kubectl get secret cloudflare-api-token -n cert-manager
```

#### Cloudflare API Token Secret (YAML format)
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
data:
  api-token: <base64-encoded-cloudflare-api-token>
```

**Cloudflare API Token Permissions**:
- Zone: Zone:Read
- Zone: DNS:Edit
- Include: All zones

## Default Wildcard Certificate

### Certificate Resource
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-ncrmro-com
  namespace: kube-system
spec:
  secretName: wildcard-ncrmro-com-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
  - "*.ncrmro.com"
  - "ncrmro.com"
```

### ingress-nginx Default Certificate Configuration
```yaml
# In ingress-nginx values
controller:
  extraArgs:
    default-ssl-certificate: "kube-system/wildcard-ncrmro-com-tls"
```

This ensures that any ingress without a specific TLS configuration automatically uses the wildcard certificate.

## Certificate Provisioning Methods

### Method 1: Automatic via Ingress Annotations

For ingresses that need specific certificates or custom domains:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  annotations:
    # Request automatic certificate generation
    cert-manager.io/cluster-issuer: "letsencrypt-cloudflare"
    # Optional: Specify certificate name
    cert-manager.io/common-name: "grafana.ncrmro.com"
    # ingress-nginx annotations
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - grafana.ncrmro.com
    secretName: grafana-ncrmro-com-tls
  rules:
  - host: grafana.ncrmro.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 80
```

### Method 2: Manual Certificate Resource

For pre-provisioned certificates or custom requirements:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: custom-service-cert
  namespace: monitoring
spec:
  secretName: custom-service-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
  - custom.ncrmro.com
  - api.ncrmro.com
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-service-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
  - hosts:
    - custom.ncrmro.com
    secretName: custom-service-tls
  rules:
  - host: custom.ncrmro.com
    # ... rest of ingress spec
```

## Certificate Lifecycle Management

### Automatic Renewal
- cert-manager automatically renews certificates 30 days before expiration
- DNS-01 challenges are automatically handled via Cloudflare API
- No manual intervention required for standard renewals

### Certificate Status Monitoring
```bash
# Check certificate status
kubectl get certificates -A

# Check certificate details
kubectl describe certificate wildcard-ncrmro-com -n kube-system

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager -f

# Check certificate expiration
kubectl get secret wildcard-ncrmro-com-tls -n kube-system -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates
```

## Common Use Cases

### 1. Service with Default Certificate (*.ncrmro.com)
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-service
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  # No TLS section - uses default wildcard certificate
  rules:
  - host: app.ncrmro.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

### 2. Service with Custom Certificate
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-domain-service
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-cloudflare"
spec:
  tls:
  - hosts:
    - external-domain.com
    secretName: external-domain-tls
  rules:
  - host: external-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: external-service
            port:
              number: 80
```

### 3. Multi-Domain Certificate
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: multi-domain-cert
  namespace: production
spec:
  secretName: multi-domain-tls
  issuerRef:
    name: letsencrypt-cloudflare
    kind: ClusterIssuer
  dnsNames:
  - api.ncrmro.com
  - app.ncrmro.com
  - admin.ncrmro.com
```

## Security Considerations

### API Token Security
- Store Cloudflare API token in Kubernetes Secret
- Use least-privilege API token permissions
- Rotate API tokens regularly
- Monitor API token usage in Cloudflare dashboard

### Certificate Secret Access
```yaml
# RBAC for certificate secrets
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: monitoring
  name: certificate-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["grafana-ncrmro-com-tls"]
  verbs: ["get", "list"]
```

## Troubleshooting

### Common Issues and Solutions

#### Certificate Stuck in Pending State
```bash
# Check certificate events
kubectl describe certificate <cert-name> -n <namespace>

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check DNS propagation
dig TXT _acme-challenge.ncrmro.com @1.1.1.1
```

#### DNS-01 Challenge Failures
1. Verify Cloudflare API token permissions
2. Check DNS record propagation time
3. Ensure Cloudflare zone is active
4. Verify cert-manager has network access to Cloudflare API

#### Certificate Not Applied to Ingress
1. Verify secret exists in correct namespace
2. Check ingress TLS configuration
3. Ensure ingress-nginx controller is running
4. Verify certificate matches ingress hostname

### Debug Commands
```bash
# List all certificates across namespaces
kubectl get certificates -A

# Check certificate details and events
kubectl describe certificate <name> -n <namespace>

# Check certificate secret
kubectl get secret <secret-name> -n <namespace> -o yaml

# Check cert-manager challenges
kubectl get challenges -A

# Check cert-manager orders
kubectl get orders -A

# Manually trigger certificate renewal (for testing)
kubectl patch certificate <cert-name> -n <namespace> -p '{"spec":{"renewBefore":"720h"}}'
```

## Backup and Recovery

### Certificate Backup
```bash
# Backup certificate secrets
kubectl get secret -n kube-system wildcard-ncrmro-com-tls -o yaml > wildcard-cert-backup.yaml

# Backup cert-manager configuration
kubectl get clusterissuer letsencrypt-cloudflare -o yaml > clusterissuer-backup.yaml
```

### Certificate Recovery
```bash
# Restore certificate secret
kubectl apply -f wildcard-cert-backup.yaml

# Restore cluster issuer
kubectl apply -f clusterissuer-backup.yaml

# Force certificate regeneration if needed
kubectl delete certificate wildcard-ncrmro-com -n kube-system
kubectl apply -f certificate-config.yaml
```

## Monitoring and Alerts

### Certificate Expiration Monitoring
```yaml
# Prometheus rule for certificate expiration
- alert: CertificateExpiringSoon
  expr: |
    (cert_manager_certificate_expiration_timestamp_seconds - time()) / 86400 < 30
  for: 1h
  labels:
    severity: warning
  annotations:
    summary: "Certificate {{ $labels.name }} expires in less than 30 days"
    description: "Certificate {{ $labels.name }} in namespace {{ $labels.namespace }} expires in {{ $value }} days"
```

### cert-manager Metrics
- `cert_manager_certificate_expiration_timestamp_seconds`
- `cert_manager_certificate_renewal_timestamp_seconds`
- `cert_manager_acme_client_request_count`
- `cert_manager_acme_client_request_duration_seconds`
