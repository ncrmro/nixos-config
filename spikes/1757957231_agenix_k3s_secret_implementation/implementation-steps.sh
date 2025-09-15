#!/bin/bash

# Agenix K3s Secret Implementation Steps
# This script contains the commands to implement agenix secrets for K3s

echo "=== Agenix K3s Secret Implementation ==="

# Step 1: Copy the secrets.nix to the main secrets directory
echo "1. Setting up secrets configuration..."
cp spikes/1757957231_agenix_k3s_secret_implementation/secrets.nix secrets/secrets.nix

# Step 2: Create the encrypted K3s server token
echo "2. Creating encrypted K3s server token..."
echo "Generated token: 216c8a7e74b196dada498830bde6ebb98d12bb5fe7a63d9ed21622e7fe53367c"
echo "216c8a7e74b196dada498830bde6ebb98d12bb5fe7a63d9ed21622e7fe53367c" | nix-shell -p age --run "agenix -e secrets/k3s-server-token.age"

# Step 3: Update ocean configuration to import agenix
echo "3. The following changes need to be made to hosts/ocean/default.nix:"
echo "   - Add ../common/optional/agenix.nix to imports"

# Step 4: Update ocean k3s configuration to use token file
echo "4. The following changes need to be made to hosts/ocean/k3s.nix:"
echo "   - Add age.secrets.k3s-server-token configuration"
echo "   - Add tokenFile = config.age.secrets.k3s-server-token.path to services.k3s"

echo ""
echo "See the modified configuration files in this spike directory for exact changes."