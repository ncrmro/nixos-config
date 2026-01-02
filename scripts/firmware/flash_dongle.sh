#!/usr/bin/env bash
set -e

# Firmware file path
FIRMWARE="ncp-uart-hw-v7.4.3.0-zbdonglee-115200.gbl"
DEVICE="/dev/serial/by-id/usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20231031082732-if00"

echo "Checking for firmware file..."
if [ ! -f "$FIRMWARE" ]; then
    echo "Firmware file $FIRMWARE not found! Downloading..."
    curl -L -o "$FIRMWARE" https://github.com/darkxst/silabs-firmware-builder/raw/main/firmware_builds/zbdonglee/ncp-uart-hw-v7.4.3.0-zbdonglee-115200.gbl
fi

echo "Entering Nix shell to setup flashing environment..."

# We use nix-shell to get python, pip, and virtualenv
nix-shell -p python3 python3Packages.pip python3Packages.virtualenv --run "
  echo 'Setting up Python virtual environment...'
  if [ ! -d \"venv\" ]; then
    python3 -m venv venv
  fi
  source venv/bin/activate
  
  echo 'Installing universal-silabs-flasher...'
  pip install universal-silabs-flasher

  echo 'Starting firmware flash...'
  echo \"Device: $DEVICE\"
  echo \"Firmware: $FIRMWARE\"
  
  # Using rts_dtr for Sonoff Dongle-E
  universal-silabs-flasher --device \"$DEVICE\" --bootloader-reset rts_dtr flash --firmware \"$FIRMWARE\"
  
  echo 'Flash command finished.'
"
