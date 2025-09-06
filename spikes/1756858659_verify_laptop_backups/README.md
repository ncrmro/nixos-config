# Verify Laptop Backups Spike

This spike explores the process of verifying ZFS snapshots from ncrmro-laptop that have been replicated to the maia server. The verification includes unlocking the LUKS-encrypted credstore zvol, decrypting the crypt dataset, mounting it, and verifying that expected files exist.

## Problem Statement

After replicating ZFS snapshots from ncrmro-laptop to maia, we need a reliable way to verify that:

1. The replication was successful
2. The encrypted data can be properly accessed
3. Critical files are intact and accessible

## Solution

Create a verification script that can be run on maia to:
1. Locate and identify the latest snapshot of the laptop's data
2. Unlock the LUKS-encrypted credstore zvol
3. Import and decrypt the crypt dataset
4. Mount the filesystem
5. Verify the existence of important files
6. Clean up by unmounting and closing encrypted volumes

## Implementation