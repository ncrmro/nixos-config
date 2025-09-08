#!/usr/bin/env bash
set -euo pipefail

# Configuration
REMOTE_HOST="${1:-maia.mercury}"
REMOTE_USER="${REMOTE_USER:-root}"
SNAPSHOT_DEVICE="/dev/zvol/maia-pool/replicated/ncrmro-laptop/credstore"
LUKS_NAME="credstore_backup"
VG_NAME="vg0"
LV_NAME="root"
MOUNT_POINT="/mnt/backup_verify"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to execute commands on remote host
remote_exec() {
    ssh "${REMOTE_USER}@${REMOTE_HOST}" "$@"
}

# Function to unlock LUKS device
unlock_luks() {
    log_info "Attempting to unlock LUKS device ${SNAPSHOT_DEVICE}..."
    
    # Check if device exists
    if ! remote_exec "test -e ${SNAPSHOT_DEVICE}"; then
        log_error "Device ${SNAPSHOT_DEVICE} not found on ${REMOTE_HOST}"
        return 1
    fi
    
    # Check if already unlocked
    if remote_exec "test -e /dev/mapper/${LUKS_NAME}"; then
        log_warning "LUKS device already unlocked at /dev/mapper/${LUKS_NAME}"
        return 0
    fi
    
    # Prompt for passphrase and unlock
    echo -n "Enter LUKS passphrase: "
    read -rs PASSPHRASE
    echo
    
    if echo "${PASSPHRASE}" | remote_exec "cryptsetup luksOpen ${SNAPSHOT_DEVICE} ${LUKS_NAME} -"; then
        log_info "Successfully unlocked LUKS device"
        return 0
    else
        log_error "Failed to unlock LUKS device"
        return 1
    fi
}

# Function to activate LVM volumes
activate_lvm() {
    log_info "Activating LVM volumes..."
    
    # Scan for volume groups
    remote_exec "vgscan" > /dev/null 2>&1 || true
    
    # Activate the volume group
    if remote_exec "vgchange -ay ${VG_NAME}"; then
        log_info "Successfully activated volume group ${VG_NAME}"
        
        # List available logical volumes
        log_info "Available logical volumes:"
        remote_exec "lvs ${VG_NAME}" || true
        
        return 0
    else
        log_error "Failed to activate volume group ${VG_NAME}"
        return 1
    fi
}

# Function to mount the filesystem
mount_filesystem() {
    log_info "Mounting filesystem..."
    
    # Create mount point if it doesn't exist
    remote_exec "mkdir -p ${MOUNT_POINT}"
    
    # Check if already mounted
    if remote_exec "mountpoint -q ${MOUNT_POINT}"; then
        log_warning "Filesystem already mounted at ${MOUNT_POINT}"
        return 0
    fi
    
    # Mount the logical volume
    if remote_exec "mount /dev/${VG_NAME}/${LV_NAME} ${MOUNT_POINT}"; then
        log_info "Successfully mounted filesystem at ${MOUNT_POINT}"
        return 0
    else
        log_error "Failed to mount filesystem"
        return 1
    fi
}

# Function to verify backup contents
verify_contents() {
    log_info "Verifying backup contents..."
    
    # Check if /home/ncrmro exists
    if remote_exec "test -d ${MOUNT_POINT}/home/ncrmro"; then
        log_info "Found /home/ncrmro directory"
        
        # List contents
        log_info "Directory contents:"
        remote_exec "ls -la ${MOUNT_POINT}/home/ncrmro" | head -20
        
        # Count files
        FILE_COUNT=$(remote_exec "find ${MOUNT_POINT}/home/ncrmro -type f | wc -l")
        DIR_COUNT=$(remote_exec "find ${MOUNT_POINT}/home/ncrmro -type d | wc -l")
        
        log_info "Found ${FILE_COUNT} files and ${DIR_COUNT} directories in /home/ncrmro"
        
        # Check for specific important directories
        for dir in ".ssh" ".config" "Documents" "Projects"; do
            if remote_exec "test -d ${MOUNT_POINT}/home/ncrmro/${dir}"; then
                log_info "✓ Found ${dir} directory"
            else
                log_warning "✗ Missing ${dir} directory"
            fi
        done
        
        return 0
    else
        log_error "/home/ncrmro directory not found in backup"
        return 1
    fi
}

# Function to cleanup and unmount
cleanup() {
    log_info "Cleaning up..."
    
    # Unmount filesystem
    if remote_exec "mountpoint -q ${MOUNT_POINT}" 2>/dev/null; then
        log_info "Unmounting filesystem..."
        remote_exec "umount ${MOUNT_POINT}" || log_warning "Failed to unmount ${MOUNT_POINT}"
    fi
    
    # Deactivate LVM
    if remote_exec "vgs ${VG_NAME}" > /dev/null 2>&1; then
        log_info "Deactivating LVM volumes..."
        remote_exec "vgchange -an ${VG_NAME}" || log_warning "Failed to deactivate ${VG_NAME}"
    fi
    
    # Close LUKS device
    if remote_exec "test -e /dev/mapper/${LUKS_NAME}" 2>/dev/null; then
        log_info "Closing LUKS device..."
        remote_exec "cryptsetup luksClose ${LUKS_NAME}" || log_warning "Failed to close LUKS device"
    fi
    
    log_info "Cleanup complete"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    log_info "Starting backup verification on ${REMOTE_HOST}"
    log_info "Using device: ${SNAPSHOT_DEVICE}"
    
    # Step 1: Unlock LUKS
    if ! unlock_luks; then
        log_error "Failed to unlock LUKS device"
        exit 1
    fi
    
    # Step 2: Activate LVM
    if ! activate_lvm; then
        log_error "Failed to activate LVM"
        exit 1
    fi
    
    # Step 3: Mount filesystem
    if ! mount_filesystem; then
        log_error "Failed to mount filesystem"
        exit 1
    fi
    
    # Step 4: Verify contents
    if verify_contents; then
        log_info "✅ Backup verification completed successfully!"
    else
        log_error "❌ Backup verification failed!"
        exit 1
    fi
    
    # Ask if user wants to keep mounted for exploration
    echo
    read -p "Do you want to keep the backup mounted for exploration? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Backup remains mounted at ${REMOTE_HOST}:${MOUNT_POINT}"
        log_info "To unmount later, run: ssh ${REMOTE_USER}@${REMOTE_HOST} 'umount ${MOUNT_POINT} && vgchange -an ${VG_NAME} && cryptsetup luksClose ${LUKS_NAME}'"
        trap - EXIT  # Remove the cleanup trap
    fi
}

# Run main function
main "$@"