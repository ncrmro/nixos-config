#!/usr/bin/env bash

set -euo pipefail

OCEAN_HOST="ocean.mercury"
ZVOL_BASE="/dev/zvol/ocean/users/ncrmro/backups/framework-13-ubuntu"
ZVOL_LUKS_PATH="${ZVOL_BASE}-part3"

# Check for --close flag
if [[ "${1:-}" == "--close" ]]; then
    echo "Closing and unmounting everything..."
    echo "Connecting to $OCEAN_HOST..."
    
    ssh "root@$OCEAN_HOST" << 'EOF'
MOUNT_PATH="/mnt/ubuntu_root"
LUKS_NAME="ubuntu_crypt"

echo "Unmounting filesystem..."
if mountpoint -q "$MOUNT_PATH"; then
    if umount "$MOUNT_PATH"; then
        echo "✓ Filesystem unmounted"
    else
        echo "ERROR: Failed to unmount filesystem - device may be in use"
        exit 1
    fi
else
    echo "✓ Filesystem not mounted"
fi

echo "Deactivating LVM volumes..."
if vgchange -an; then
    echo "✓ LVM volumes deactivated"
else
    echo "ERROR: Failed to deactivate LVM volumes - may still be in use"
    exit 1
fi

echo "Closing LUKS container..."
if [ -e "/dev/mapper/$LUKS_NAME" ]; then
    if cryptsetup luksClose "$LUKS_NAME"; then
        echo "✓ LUKS container closed"
    else
        echo "ERROR: Failed to close LUKS container - device still in use"
        exit 1
    fi
else
    echo "✓ LUKS container not open"
fi

echo "Cleanup complete!"
EOF
    exit 0
fi

echo "Verifying LUKS presence on zvol: $ZVOL_LUKS_PATH"
echo "Connecting to $OCEAN_HOST..."

ssh "root@$OCEAN_HOST" << EOF
ZVOL_BASE="/dev/zvol/ocean/users/ncrmro/backups/framework-13-ubuntu"
ZVOL_LUKS_PATH="\${ZVOL_BASE}-part3"

echo "Checking if zvol exists..."
if [ ! -e "\$ZVOL_LUKS_PATH" ]; then
    echo "ERROR: zvol \$ZVOL_LUKS_PATH does not exist"
    exit 1
fi

echo "✓ zvol exists"

echo "Checking LUKS header..."
if cryptsetup luksDump "\$ZVOL_LUKS_PATH" > /dev/null 2>&1; then
    echo "✓ LUKS header found and valid"
    
    echo "LUKS header details:"
    cryptsetup luksDump "\$ZVOL_LUKS_PATH" | head -20
else
    echo "ERROR: No valid LUKS header found"
    exit 1
fi

echo "Opening LUKS container..."
LUKS_NAME="ubuntu_crypt"
if [ ! -e "/dev/mapper/\$LUKS_NAME" ]; then
    echo "LUKS container needs to be opened manually."
    echo "Run: cryptsetup luksOpen \$ZVOL_LUKS_PATH \$LUKS_NAME"
    echo "Enter your LUKS passphrase when prompted."
    exit 0
else
    echo "✓ LUKS container already open"
fi

echo "Scanning for LVM volumes..."
vgscan
vgchange -ay

echo "Creating mount point..."
MOUNT_PATH="/mnt/ubuntu_root"
mkdir -p "\$MOUNT_PATH"

echo "Mounting root filesystem..."
if mount /dev/mapper/vgubuntu-root "\$MOUNT_PATH"; then
    echo "✓ Root filesystem mounted at \$MOUNT_PATH"
    echo "Root directory contents:"
    ls -la "\$MOUNT_PATH" | head -10
    
    echo ""
    echo "Contents of /home/ncrmro:"
    if [ -d "\$MOUNT_PATH/home/ncrmro" ]; then
        ls -la "\$MOUNT_PATH/home/ncrmro"
    else
        echo "Directory /home/ncrmro not found"
    fi
else
    echo "ERROR: Failed to mount root filesystem"
    exit 1
fi

echo "Verification and mount complete!"
EOF