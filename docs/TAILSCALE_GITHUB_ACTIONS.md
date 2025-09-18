# Tailscale and Headscale with GitHub Actions

This document provides comprehensive guidance for setting up Tailscale and Headscale integration with GitHub Actions for secure CI/CD access to your infrastructure.

## Table of Contents

1. [Overview](#overview)
2. [Headscale Server Configuration](#headscale-server-configuration)
3. [Tailscale Tag-Based Access Control](#tailscale-tag-based-access-control)
4. [GitHub Actions Integration](#github-actions-integration)
5. [Security Best Practices](#security-best-practices)
6. [Example Workflows](#example-workflows)
7. [Troubleshooting](#troubleshooting)

## Overview

This infrastructure uses Headscale as a self-hosted coordination server (alternative to Tailscale's SaaS) running on the Mercury host. GitHub Actions can securely connect to the Tailscale network using ephemeral keys and tag-based access control to deploy to Kubernetes clusters and access internal services.

### Architecture

```
GitHub Actions Runner
    ↓ (ephemeral auth key)
Tailscale Client
    ↓ (VPN connection)
Headscale Server (mercury.ncrmro.com)
    ↓ (coordination/routing)
Internal Services (K3s cluster, databases, etc.)
```

### Benefits

- **Secure Access**: No need to expose internal services to the internet
- **Ephemeral Connections**: GitHub Actions runners connect temporarily and are automatically cleaned up
- **Fine-grained Access Control**: Tag-based ACLs control what runners can access
- **Audit Trail**: All connections are logged and tracked
- **Zero Trust**: All traffic is encrypted and authenticated

## Headscale Server Configuration

The Mercury host runs Headscale with the following configuration (see `hosts/mercury/headscale.nix`):

### Key Features

- **Server URL**: `https://mercury.ncrmro.com`
- **Magic DNS**: Enabled for seamless service discovery
- **DERP Server**: Built-in relay server for NAT traversal
- **DNS Records**: Custom internal DNS entries for services

### DNS Configuration

Headscale provides internal DNS resolution for services:

```yaml
dns:
  base_domain: "mercury"
  magic_dns: true
  nameservers:
    global: ["1.1.1.1", "1.0.0.1"]
  override_local_dns: true
  extra_records:
    - name: "grafana.ncrmro.com"
      type: "A"
      value: "100.64.0.6"
    - name: "vaultwarden.ncrmro.com"
      type: "A"
      value: "100.64.0.6"
    # ... additional service records
```

### Managing the Headscale Server

#### Deployment

Use the provided script to update the Mercury server:

```bash
./bin/updateMercury
```

This script:
1. Deploys the latest NixOS configuration
2. Automatically creates the `ncrmro` user if it doesn't exist

#### Manual Management

Direct server management via SSH:

```bash
# SSH to Mercury server
ssh root@mercury.ncrmro.com

# List users
headscale users list

# List nodes (connected devices)
headscale nodes list

# List pre-auth keys
headscale preauthkeys list --user ncrmro
```

## Tailscale Tag-Based Access Control

### ACL Configuration

Create an ACL configuration file to control access between different types of devices and services. Save this as `acl.hujson` on your Headscale server:

```json
{
  // Define tags for different types of devices/services
  "tagOwners": {
    "tag:github-actions": ["ncrmro"],
    "tag:k8s-cluster": ["ncrmro"],
    "tag:dev-services": ["ncrmro"],
    "tag:prod-services": ["ncrmro"]
  },

  // Define what each tag can access
  "acls": [
    // GitHub Actions runners can access Kubernetes API
    {
      "action": "accept",
      "src": ["tag:github-actions"],
      "dst": ["tag:k8s-cluster:6443", "tag:k8s-cluster:443"]
    },
    
    // GitHub Actions can access development services
    {
      "action": "accept",
      "src": ["tag:github-actions"],
      "dst": ["tag:dev-services:*"]
    },
    
    // Restrict GitHub Actions from production services (except specific ports)
    {
      "action": "accept",
      "src": ["tag:github-actions"],
      "dst": ["tag:prod-services:80", "tag:prod-services:443"]
    },
    
    // Allow all authenticated users to access basic services
    {
      "action": "accept",
      "src": ["ncrmro"],
      "dst": ["*:*"]
    }
  ],

  // SSH access rules
  "ssh": [
    {
      "action": "accept",
      "src": ["ncrmro"],
      "dst": ["*"]
    }
  ]
}
```

### Applying ACL Configuration

```bash
# SSH to Mercury server
ssh root@mercury.ncrmro.com

# Apply the ACL configuration
headscale acls load /path/to/acl.hujson

# Verify ACL is loaded
headscale acls get
```

### Creating Tagged Auth Keys

Create ephemeral auth keys with specific tags for GitHub Actions:

```bash
# Create an ephemeral key for GitHub Actions (24 hour expiration)
headscale preauthkeys create \
  --user ncrmro \
  --ephemeral \
  --expiration 24h \
  --tags "tag:github-actions"

# Create a reusable key for development (longer expiration)
headscale preauthkeys create \
  --user ncrmro \
  --reusable \
  --expiration 168h \
  --tags "tag:github-actions"
```

## GitHub Actions Integration

### Authentication Methods

There are two main ways to authenticate GitHub Actions with Tailscale:

1. **Auth Keys** (Traditional method) - Uses pre-shared keys
2. **OAuth Clients** (Recommended) - Uses GitHub OIDC tokens for authentication

### Method 1: Using Auth Keys

#### Setting Up Repository Secrets

Add the following secrets to your GitHub repository:

1. **TAILSCALE_AUTHKEY**: Ephemeral or reusable auth key with appropriate tags
2. **KUBECONFIG**: Base64-encoded Kubernetes configuration (if accessing K8s)

#### Basic Tailscale Setup Action

Create a reusable action for connecting to Tailscale:

```yaml
# .github/actions/setup-tailscale/action.yml
name: 'Setup Tailscale'
description: 'Connect to Tailscale network'
inputs:
  authkey:
    description: 'Tailscale auth key'
    required: true
  timeout:
    description: 'Connection timeout in seconds'
    required: false
    default: '30'

runs:
  using: 'composite'
  steps:
    - name: Install Tailscale
      shell: bash
      run: |
        curl -fsSL https://tailscale.com/install.sh | sh
        
    - name: Connect to Tailscale
      shell: bash
      run: |
        sudo tailscale up \
          --authkey="${{ inputs.authkey }}" \
          --login-server=https://mercury.ncrmro.com \
          --timeout=${{ inputs.timeout }}s \
          --accept-routes
          
    - name: Verify Connection
      shell: bash
      run: |
        echo "Tailscale Status:"
        tailscale status
        echo "Tailscale IP:"
        tailscale ip -4
```

### Environment Cleanup

Ensure runners are properly cleaned up after job completion:

```yaml
# Add this as a post-job cleanup step
- name: Disconnect from Tailscale
  if: always()
  shell: bash
  run: |
    sudo tailscale logout || true
    sudo systemctl stop tailscaled || true
```

### Method 2: Using OAuth Clients (Recommended)

OAuth clients provide a more secure authentication method by using GitHub's OIDC tokens instead of long-lived auth keys. This approach is more secure because:

- No long-lived secrets to manage
- Fine-grained access control via OAuth scopes
- Automatic token expiration
- Better audit trail

#### Setting Up OAuth Client for Headscale

**Note:** OAuth client support for Headscale requires configuration of an OIDC provider. This section shows how to set up GitHub as an OIDC provider for Headscale.

1. **Configure Headscale OIDC** - Add to your `headscale.nix`:

```nix
services.headscale.settings.oidc = {
  issuer = "https://token.actions.githubusercontent.com";
  client_id = "your-github-org-or-username";
  client_secret_path = "/path/to/github/oidc/secret";
  scope = ["openid" "profile" "email"];
  extra_params = {};
  allowed_domains = ["github.com"];
  allowed_users = ["your-github-username"];
  strip_email_domain = false;
};
```

2. **Create GitHub OIDC Configuration** - In your repository settings:

   - Go to Settings → Secrets and variables → Actions
   - Add repository variable: `TAILSCALE_OAUTH_CLIENT_ID`
   - Add repository secret: `TAILSCALE_OAUTH_CLIENT_SECRET`

#### OAuth-Based Tailscale Setup Action

Create `.github/actions/setup-tailscale-oauth/action.yml`:

```yaml
name: 'Setup Tailscale with OAuth'
description: 'Connect to Tailscale network using GitHub OIDC'
inputs:
  login-server:
    description: 'Headscale server URL'
    required: true
    default: 'https://mercury.ncrmro.com'
  timeout:
    description: 'Connection timeout in seconds'
    required: false
    default: '30'

runs:
  using: 'composite'
  steps:
    - name: Install Tailscale
      shell: bash
      run: |
        curl -fsSL https://tailscale.com/install.sh | sh
        tailscale version

    - name: Connect via GitHub OIDC
      shell: bash
      env:
        GITHUB_TOKEN: ${{ github.token }}
      run: |
        # Use GitHub OIDC token for authentication
        sudo tailscale up \
          --login-server=${{ inputs.login-server }} \
          --timeout=${{ inputs.timeout }}s \
          --accept-routes \
          --accept-dns \
          --auth-key="$GITHUB_TOKEN" \
          --oauth

    - name: Verify Connection
      shell: bash
      run: |
        echo "=== Tailscale Status ==="
        tailscale status
        echo "=== Tailscale IP ==="
        tailscale ip -4
        echo "=== OAuth Authentication Successful ==="
```

#### OAuth Workflow Example

```yaml
# .github/workflows/deploy-oauth.yml
name: Deploy with OAuth Authentication

on:
  push:
    branches: [main]

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Tailscale via OAuth
        uses: ./.github/actions/setup-tailscale-oauth
        with:
          login-server: https://mercury.ncrmro.com

      - name: Deploy to Kubernetes
        env:
          KUBECONFIG: /tmp/kubeconfig
        run: |
          # Configure kubectl with Tailscale network access
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $KUBECONFIG
          kubectl config set-cluster cluster --server=https://100.64.0.6:6443
          
          # Deploy applications
          kubectl apply -f kubernetes/
          kubectl rollout status deployment/my-app

      - name: Cleanup
        if: always()
        run: |
          rm -f /tmp/kubeconfig
          sudo tailscale logout || true
```

#### OAuth Client Management

**Creating OAuth Clients in Headscale:**

```bash
# SSH to Mercury server
ssh root@mercury.ncrmro.com

# Create OAuth client for GitHub Actions
headscale oauth clients create \
  --name "github-actions" \
  --redirect-uri "https://github.com/your-org/your-repo" \
  --scopes "read:user,user:email"

# List OAuth clients
headscale oauth clients list

# Revoke OAuth client
headscale oauth clients delete <client-id>
```

**GitHub Repository Configuration:**

1. **Enable OIDC** in repository settings:
   ```yaml
   # Add to workflow permissions
   permissions:
     id-token: write
     contents: read
   ```

2. **Configure audience** for your Headscale server:
   ```bash
   # In Headscale configuration
   oidc.allowed_domains = ["github.com"]
   oidc.client_id = "your-github-org"
   ```

#### OAuth Security Benefits

- **No stored secrets**: Authentication uses short-lived OIDC tokens
- **Automatic expiration**: Tokens expire automatically (typically 1 hour)
- **Audit trail**: All authentication events logged in GitHub and Headscale
- **Revocable access**: Can revoke OAuth clients without affecting other authentication methods
- **Fine-grained permissions**: OAuth scopes control access levels

#### OAuth Troubleshooting

**Common OAuth Issues:**

```bash
# 1. Check OIDC configuration
ssh root@mercury.ncrmro.com "headscale config show | grep -A 20 oidc"

# 2. Verify GitHub OIDC token
echo "$GITHUB_TOKEN" | base64 -d | jq '.'

# 3. Test OAuth client
curl -X POST https://mercury.ncrmro.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code&code=$GITHUB_TOKEN"

# 4. Check Headscale OAuth logs
journalctl -u headscale -f | grep -i oauth
```

**Workflow Debugging:**

```yaml
- name: Debug OAuth Authentication
  run: |
    echo "GitHub Token Present: ${{ github.token != '' }}"
    echo "Repository: ${{ github.repository }}"
    echo "Actor: ${{ github.actor }}"
    echo "OIDC Token URL: ${{ env.ACTIONS_ID_TOKEN_REQUEST_URL }}"
```

## Security Best Practices

### Ephemeral Keys

Always use ephemeral keys for GitHub Actions:

```bash
# Create ephemeral keys with short expiration
headscale preauthkeys create \
  --user ncrmro \
  --ephemeral \
  --expiration 24h \
  --tags "tag:github-actions"
```

**Benefits of ephemeral keys:**
- Automatically cleanup after disconnection
- Reduce attack surface
- Prevent credential reuse
- Automatic node removal from network

### Secret Management

1. **Rotate auth keys regularly** (weekly/monthly)
2. **Use GitHub Environment secrets** for production deployments
3. **Implement key expiration policies**
4. **Monitor auth key usage** through Headscale logs

### Network Segmentation

1. **Use tags for access control** - separate dev/staging/prod access
2. **Implement least privilege** - only grant necessary access
3. **Regular ACL audits** - review and update access rules
4. **Monitor network traffic** - log and alert on suspicious activity

### Monitoring and Auditing

Monitor Tailscale/Headscale activity:

```bash
# Monitor Headscale logs
journalctl -u headscale -f

# Check connected nodes
headscale nodes list

# Review ACL rules
headscale acls get

# Check auth key usage
headscale preauthkeys list --user ncrmro
```

## Example Workflows

### Example 1: Deploy to Kubernetes

```yaml
# .github/workflows/deploy-k8s.yml
name: Deploy to Kubernetes

on:
  push:
    branches: [main]
    paths: ['kubernetes/**']

env:
  KUBECONFIG_PATH: /tmp/kubeconfig

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Tailscale
        uses: ./.github/actions/setup-tailscale
        with:
          authkey: ${{ secrets.TAILSCALE_AUTHKEY }}

      - name: Setup kubectl
        run: |
          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x kubectl
          sudo mv kubectl /usr/local/bin/

      - name: Configure Kubernetes access
        run: |
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $KUBECONFIG_PATH
          chmod 600 $KUBECONFIG_PATH
          
          # Update server URL to use Tailscale IP
          kubectl config set-cluster cluster --server=https://100.64.0.6:6443
          
          # Test connection
          kubectl cluster-info

      - name: Deploy applications
        run: |
          kubectl apply -f kubernetes/
          kubectl rollout status deployment/my-app

      - name: Cleanup
        if: always()
        run: |
          rm -f $KUBECONFIG_PATH
          sudo tailscale logout || true
```

### Example 2: Access Internal Services

```yaml
# .github/workflows/test-services.yml
name: Test Internal Services

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

jobs:
  health-check:
    runs-on: ubuntu-latest
    
    steps:
      - name: Setup Tailscale
        uses: ./.github/actions/setup-tailscale
        with:
          authkey: ${{ secrets.TAILSCALE_AUTHKEY }}

      - name: Test service connectivity
        run: |
          # Test internal services via Tailscale DNS
          curl -f http://grafana.ncrmro.com/api/health
          curl -f http://vaultwarden.ncrmro.com/alive
          
          # Test Kubernetes API
          curl -k https://100.64.0.6:6443/healthz

      - name: Report results
        if: failure()
        run: |
          echo "Service health check failed" >> $GITHUB_STEP_SUMMARY
          # Add notification logic here

      - name: Cleanup
        if: always()
        run: |
          sudo tailscale logout || true
```

### Example 3: Database Operations

```yaml
# .github/workflows/db-backup.yml
name: Database Backup

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Setup Tailscale
        uses: ./.github/actions/setup-tailscale
        with:
          authkey: ${{ secrets.TAILSCALE_AUTHKEY }}

      - name: Install database tools
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      - name: Create database backup
        env:
          PGPASSWORD: ${{ secrets.DB_PASSWORD }}
        run: |
          # Connect to database via Tailscale network
          pg_dump -h 100.64.0.6 -U postgres -d myapp > backup.sql
          
          # Upload to storage (implementation depends on your setup)
          # aws s3 cp backup.sql s3://my-backups/$(date +%Y%m%d)/

      - name: Cleanup
        if: always()
        run: |
          rm -f backup.sql
          sudo tailscale logout || true
```

### Example 4: OAuth-Based Kubernetes Deployment

```yaml
# .github/workflows/deploy-k8s-oauth.yml
name: Deploy to Kubernetes with OAuth

on:
  push:
    branches: [main]
    paths: ['kubernetes/**']

permissions:
  id-token: write  # Required for GitHub OIDC
  contents: read

env:
  KUBECONFIG_PATH: /tmp/kubeconfig

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Tailscale via OAuth
        uses: ./.github/actions/setup-tailscale-oauth
        with:
          login-server: https://mercury.ncrmro.com

      - name: Install kubectl
        run: |
          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x kubectl
          sudo mv kubectl /usr/local/bin/

      - name: Configure Kubernetes access
        run: |
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $KUBECONFIG_PATH
          chmod 600 $KUBECONFIG_PATH
          kubectl config set-cluster cluster --server=https://100.64.0.6:6443
          kubectl cluster-info

      - name: Deploy applications
        run: |
          kubectl apply -f kubernetes/
          kubectl rollout status deployment/my-app --timeout=300s

      - name: Cleanup
        if: always()
        run: |
          rm -f $KUBECONFIG_PATH
          sudo tailscale logout || true
```

### Example 5: OAuth Service Monitoring

```yaml
# .github/workflows/monitor-oauth.yml
name: Service Monitoring with OAuth

on:
  schedule:
    - cron: '0 */4 * * *'  # Every 4 hours
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  monitor:
    runs-on: ubuntu-latest
    
    steps:
      - name: Setup Tailscale via OAuth
        uses: ./.github/actions/setup-tailscale-oauth

      - name: Health Check Services
        id: health-check
        run: |
          echo "Testing service connectivity..."
          FAILURES=0
          
          # Test internal services
          services=(
            "http://grafana.ncrmro.com/api/health"
            "http://vaultwarden.ncrmro.com/alive"
            "https://100.64.0.6:6443/healthz"
          )
          
          for service in "${services[@]}"; do
            if curl -f -s --connect-timeout 10 "$service" > /dev/null; then
              echo "✅ $(echo $service | cut -d'/' -f3): OK"
            else
              echo "❌ $(echo $service | cut -d'/' -f3): FAILED"
              FAILURES=$((FAILURES + 1))
            fi
          done
          
          echo "failures=$FAILURES" >> $GITHUB_OUTPUT

      - name: Report Results
        run: |
          cat >> $GITHUB_STEP_SUMMARY << EOF
          # OAuth Service Health Report
          
          **Authentication**: GitHub OIDC ✅
          **Timestamp**: $(date -u)
          **Failures**: ${{ steps.health-check.outputs.failures }}
          
          $([ "${{ steps.health-check.outputs.failures }}" = "0" ] && echo "## All Services Healthy ✅" || echo "## Some Services Failed ❌")
          EOF

      - name: Cleanup
        if: always()
        run: sudo tailscale logout || true
```

### OAuth vs Auth Key Comparison

| Feature | OAuth Authentication | Auth Key Authentication |
|---------|---------------------|------------------------|
| **Security** | ✅ No long-lived secrets | ⚠️ Requires key management |
| **Setup Complexity** | ⚠️ Requires OIDC configuration | ✅ Simple setup |
| **Token Lifetime** | ✅ Short-lived (1 hour) | ⚠️ Configurable (hours to days) |
| **Revocation** | ✅ Immediate via OAuth client | ⚠️ Manual key expiration |
| **Audit Trail** | ✅ GitHub + Headscale logs | ✅ Headscale logs only |
| **Automation** | ✅ Fully automated | ⚠️ Requires key rotation |

## Troubleshooting

### Common Issues

#### 1. Connection Timeout

**Problem**: GitHub Actions runner cannot connect to Tailscale network

**Solutions**:
```bash
# Check auth key validity
headscale preauthkeys list --user ncrmro

# Verify Headscale server status
systemctl status headscale
journalctl -u headscale -f

# Test connection manually
tailscale up --login-server=https://mercury.ncrmro.com --authkey=YOUR_KEY
```

#### 2. ACL Permission Denied

**Problem**: Runner connects but cannot access services

**Solutions**:
```bash
# Check current ACL rules
headscale acls get

# Verify node tags
headscale nodes list

# Test ACL rules
headscale acls test --user ncrmro
```

#### 3. DNS Resolution Issues

**Problem**: Cannot resolve internal service names

**Solutions**:
```bash
# Check DNS configuration in runner
tailscale status
nslookup grafana.ncrmro.com

# Verify Headscale DNS settings
# Check extra_records in headscale.nix configuration
```

#### 4. Kubernetes Access Issues

**Problem**: Cannot connect to Kubernetes API

**Solutions**:
```bash
# Verify Kubernetes endpoint
kubectl cluster-info

# Check service account permissions
kubectl auth can-i --list --as=system:serviceaccount:default:github-actions

# Test direct connection
curl -k https://100.64.0.6:6443/healthz
```

### Debugging Commands

#### Tailscale Client Debugging

```bash
# Check Tailscale status
tailscale status --json

# Test network connectivity
tailscale netcheck

# View detailed logs
sudo journalctl -u tailscaled -f

# Test ping to other nodes
tailscale ping 100.64.0.6
```

#### Headscale Server Debugging

```bash
# Check server status
systemctl status headscale

# View server logs
journalctl -u headscale -f

# List all connected nodes
headscale nodes list

# Check routes
headscale routes list
```

### Log Analysis

#### GitHub Actions Logs

Look for these key indicators in workflow logs:

```
✅ Successful connection:
- "tailscale up" command succeeds
- "tailscale status" shows connected state
- Service endpoints respond correctly

❌ Connection issues:
- Timeout errors during "tailscale up"
- DNS resolution failures
- HTTP connection refused errors
```

#### Headscale Server Logs

Monitor for these events:

```bash
# Successful authentications
grep "machine registered" /var/log/headscale.log

# ACL violations
grep "access denied" /var/log/headscale.log

# Node expiration
grep "ephemeral node expired" /var/log/headscale.log
```

### Performance Considerations

#### Runner Performance

- **Use self-hosted runners** for frequent deployments to reduce connection overhead
- **Cache Tailscale binary** to speed up setup
- **Pre-warm connections** for time-sensitive operations

#### Network Optimization

- **Use DERP servers** for optimal routing when direct connections aren't possible
- **Configure regional DERP** for geographically distributed runners
- **Monitor bandwidth usage** for large file transfers

### OAuth Authentication Troubleshooting

**Problem**: OAuth authentication fails or OIDC token errors

**Solutions**:
```bash
# Check Headscale OIDC configuration
ssh root@mercury.ncrmro.com "headscale config show | grep -A 20 oidc"

# Verify GitHub OIDC environment variables
echo "OIDC Token URL: $ACTIONS_ID_TOKEN_REQUEST_URL"
echo "OIDC Token: $ACTIONS_ID_TOKEN_REQUEST_TOKEN"

# Test OAuth token format
curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=https://mercury.ncrmro.com"

# Check Headscale OAuth logs
ssh root@mercury.ncrmro.com "journalctl -u headscale -f | grep -i 'oauth\|oidc'"
```

**Common OAuth Issues**:
- Missing `permissions: id-token: write` in workflow
- Incorrect OIDC issuer URL in Headscale config
- GitHub repository not configured for OIDC
- Headscale OIDC client configuration mismatch

## Additional Resources

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Headscale GitHub Repository](https://github.com/juanfont/headscale)
- [NixOS Tailscale Module](https://search.nixos.org/options?channel=unstable&show=services.tailscale)
- [Repository Headscale Setup Guide](./HEADSCALE_SETUP.md)
- [Repository DNS Architecture](./DNS.md)

## Security Considerations Summary

1. **Prefer OAuth authentication** over auth keys for GitHub Actions
2. **Use ephemeral keys** if OAuth is not available
3. **Implement tag-based ACLs** for fine-grained access control
4. **Rotate credentials regularly** and monitor usage
5. **Segment network access** based on environment (dev/staging/prod)
6. **Monitor and audit** all network connections
7. **Use environment-specific secrets** in GitHub Actions
8. **Implement proper cleanup** to remove nodes after job completion
9. **Configure OIDC properly** with correct issuer and audience
10. **Use short-lived tokens** whenever possible

This comprehensive setup provides secure, auditable access to your infrastructure while maintaining the benefits of a zero-trust network architecture.