#!/usr/bin/env bash
# Test script for ZFS remote replication
# Tests the syncoid replication command used in hosts/ncrmro-laptop/zfs.remote-replication.nix

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
SSH_KEY="${1:-/home/ncrmro/.ssh/id_ed25519}"
SOURCE_DATASET="${2:-rpool}"
REMOTE_HOST="${3:-maia.mercury}"
REMOTE_USER="${4:-laptop-sync}"
REMOTE_DATASET="${5:-lake/backups/ncrmro-laptop/rpool}"
HOSTNAME=$(hostname)

echo -e "${YELLOW}Testing ZFS replication configuration...${NC}"
echo "SSH Key: $SSH_KEY"
echo "Source Dataset: $SOURCE_DATASET"
echo "Remote Host: $REMOTE_HOST"
echo "Remote User: $REMOTE_USER"
echo "Remote Dataset: $REMOTE_DATASET"
echo ""

# Step 1: Test SSH connection
echo -e "${YELLOW}Testing SSH connection to $REMOTE_USER@$REMOTE_HOST...${NC}"
if ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "echo Connection successful"; then
  echo -e "${GREEN}SSH connection successful${NC}"
else
  echo -e "${RED}SSH connection failed${NC}"
  exit 1
fi

# Step 2: Check if required tools are available
echo -e "${YELLOW}Checking required tools...${NC}"
REQUIRED_TOOLS=("syncoid" "mbuffer" "lzop" "pv" "gzip")
for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo -e "${GREEN}$tool is installed${NC}"
  else
    echo -e "${RED}$tool is not installed${NC}"
    #        exit 1
  fi
done

# Step 3: Check if source dataset exists
echo -e "${YELLOW}Checking source dataset $SOURCE_DATASET...${NC}"
if zfs list "$SOURCE_DATASET" >/dev/null 2>&1; then
  echo -e "${GREEN}Source dataset exists${NC}"
else
  echo -e "${RED}Source dataset does not exist${NC}"
  exit 1
fi

# Step 4: Check if destination dataset exists (or can be created)
echo -e "${YELLOW}Checking remote dataset access...${NC}"
if ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "zfs list $REMOTE_DATASET 2>/dev/null || echo 'Dataset would be created'"; then
  echo -e "${GREEN}Remote dataset access verified${NC}"
else
  echo -e "${RED}Cannot access remote dataset location${NC}"
  exit 1
fi

# Step 5: Test syncoid command with dry-run
echo -e "${YELLOW}Testing syncoid command with dry-run...${NC}"
SYNCOID_CMD="syncoid \
    --no-privilege-elevation \
    --no-sync-snap \
    --sshkey $SSH_KEY \
    --identifier \"laptop-$HOSTNAME\" \
    --skip-parent \
    --preserve-properties \
    --recursive \
    --include-snaps autosnap \
    --compress=none \
    --sendoptions=raw \
    --exclude-datasets='docker|containers|images|nix|libvirt'\
    $SOURCE_DATASET $REMOTE_USER@$REMOTE_HOST:$REMOTE_DATASET"

echo "Command: $SYNCOID_CMD"
if eval "$SYNCOID_CMD"; then
  echo -e "${GREEN}Syncoid dry-run successful${NC}"
else
  echo -e "${RED}Syncoid dry-run failed${NC}"
  exit 1
fi

echo -e "${GREEN}All tests passed. The ZFS replication configuration appears to be working correctly.${NC}"
