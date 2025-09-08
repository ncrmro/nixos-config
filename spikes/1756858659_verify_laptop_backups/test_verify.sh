#!/usr/bin/env bash
set -euo pipefail

# Quick test script to verify the backup verification script works
# This script tests with a dry-run approach first

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_SCRIPT="${SCRIPT_DIR}/verify_backup.sh"

echo "Testing backup verification script..."
echo "======================================"
echo

# Check if script exists
if [[ ! -f "${VERIFY_SCRIPT}" ]]; then
    echo "Error: verify_backup.sh not found!"
    exit 1
fi

# Test SSH connectivity first
REMOTE_HOST="${1:-maia.mercury}"
echo "Testing SSH connectivity to ${REMOTE_HOST}..."
if ssh "root@${REMOTE_HOST}" "echo 'SSH connection successful'"; then
    echo "✓ SSH connection works"
else
    echo "✗ SSH connection failed"
    exit 1
fi

echo
echo "Checking for ZFS snapshot device on remote host..."
if ssh "root@${REMOTE_HOST}" "ls -la /dev/zvol/maia-pool/replicated/ncrmro-laptop/ 2>/dev/null || echo 'No zvol found'"; then
    echo "✓ Found zvol directory"
else
    echo "✗ Could not list zvol directory"
fi

echo
echo "Ready to run the verification script."
echo "The script will:"
echo "  1. Unlock the LUKS encrypted device"
echo "  2. Activate LVM volumes"
echo "  3. Mount the filesystem"
echo "  4. List contents of /home/ncrmro"
echo "  5. Clean up (unless you choose to keep it mounted)"
echo
read -p "Continue with verification? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    exec "${VERIFY_SCRIPT}" "$@"
else
    echo "Verification cancelled."
fi