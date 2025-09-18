# Quick Start: Tailscale + GitHub Actions

This is a condensed guide to get GitHub Actions working with your Tailscale/Headscale network quickly.

## Prerequisites

- ✅ Headscale server running on Mercury (`mercury.ncrmro.com`)
- ✅ SSH access to Mercury server
- ✅ GitHub repository where you want to add Tailscale access

## Step 1: Create Auth Key

Use the provided script to create an ephemeral auth key:

```bash
# From repository root
./bin/tailscale-github-actions create-ephemeral
```

This will output an auth key like: `tskey-auth-xxxxxxxxxx`

## Step 2: Add to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `TAILSCALE_AUTHKEY`
5. Value: (paste the auth key from step 1)

## Step 3: Create Reusable Action

First, create `.github/actions/setup-tailscale/action.yml` in your repository:

```yaml
name: 'Setup Tailscale'
description: 'Connect to Tailscale network via Headscale server'
inputs:
  authkey:
    description: 'Tailscale auth key (preferably ephemeral)'
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
        tailscale version
        
    - name: Connect to Tailscale Network
      shell: bash
      run: |
        sudo tailscale up \
          --authkey=${{ inputs.authkey }} \
          --login-server=https://mercury.ncrmro.com \
          --timeout=${{ inputs.timeout }}s \
          --accept-routes --accept-dns
        
    - name: Verify Connection
      shell: bash
      run: |
        echo "=== Tailscale Status ==="
        tailscale status
        echo "=== Tailscale IP ==="
        tailscale ip -4
```

## Step 4: Use in Workflow

Create `.github/workflows/example.yml`:

```yaml
name: Test Tailscale Connection

on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Tailscale
        uses: ./.github/actions/setup-tailscale
        with:
          authkey: ${{ secrets.TAILSCALE_AUTHKEY }}
      
      - name: Test Connection
        run: |
          # Test internal service
          curl -f http://grafana.ncrmro.com/api/health
          
          # Test Kubernetes API
          curl -k https://100.64.0.6:6443/healthz

      - name: Cleanup
        if: always()
        run: |
          sudo tailscale logout || true
```

## Step 5: Configure ACLs (Optional but Recommended)

Apply the example ACL configuration to restrict GitHub Actions access:

```bash
# SSH to Mercury
ssh root@mercury.ncrmro.com

# Apply ACL (modify path as needed)
headscale acls load /path/to/acl.hujson

# Verify ACL
headscale acls get
```

## Common Use Cases

### Access Kubernetes

```yaml
- name: Setup kubectl
  run: |
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl && sudo mv kubectl /usr/local/bin/

- name: Deploy
  env:
    KUBECONFIG: /tmp/kubeconfig
  run: |
    echo "${{ secrets.KUBECONFIG }}" | base64 -d > $KUBECONFIG
    kubectl config set-cluster cluster --server=https://100.64.0.6:6443
    kubectl apply -f manifests/
```

### Access Database

```yaml
- name: Database Operation
  env:
    PGPASSWORD: ${{ secrets.DB_PASSWORD }}
  run: |
    pg_dump -h 100.64.0.6 -U postgres mydb > backup.sql
```

### Monitor Services

```yaml
- name: Health Check
  run: |
    curl -f http://grafana.ncrmro.com/api/health
    curl -f http://vaultwarden.ncrmro.com/alive
```

## Troubleshooting

### Connection Fails
```bash
# Check auth key validity
./bin/tailscale-github-actions list

# Test manual connection
tailscale up --login-server=https://mercury.ncrmro.com --authkey=YOUR_KEY
```

### ACL Issues
```bash
# Test ACL rules
ssh root@mercury.ncrmro.com "headscale acls test --user ncrmro"
```

### DNS Issues
```bash
# In workflow, test DNS
nslookup grafana.ncrmro.com
tailscale netcheck
```

## Security Best Practices

1. **Use ephemeral keys** - they auto-cleanup after disconnection
2. **Rotate keys regularly** - create new keys weekly/monthly
3. **Use environment secrets** for production deployments
4. **Implement ACLs** to restrict access by environment
5. **Monitor connections** through Headscale logs

## Key Management

```bash
# Create ephemeral key (recommended)
./bin/tailscale-github-actions create-ephemeral

# Create reusable key (for testing)
./bin/tailscale-github-actions create-reusable --expiration 72h

# List all keys
./bin/tailscale-github-actions list

# Revoke a key
./bin/tailscale-github-actions revoke key_12345
```

## Next Steps

- Read the [full documentation](./TAILSCALE_GITHUB_ACTIONS.md) for comprehensive setup
- Review [example workflows](./.github/workflows/) for common patterns
- Set up [ACL configuration](./examples/headscale-acl.hujson) for production use
- Configure monitoring and alerting for failed connections

---

**Need help?** Check the troubleshooting section in the [full documentation](./TAILSCALE_GITHUB_ACTIONS.md#troubleshooting).