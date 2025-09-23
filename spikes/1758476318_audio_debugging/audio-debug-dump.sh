#!/usr/bin/env bash
# Audio debugging information dump script

echo "=== AUDIO DEBUG INFO DUMP ==="
echo "Date: $(date)"
echo "Kernel: $(uname -r)"
echo ""

echo "=== PCI AUDIO DEVICES ==="
lspci | grep -i audio
echo ""

echo "=== ALSA CARDS ==="
cat /proc/asound/cards
echo ""

echo "=== ALSA MODULES ==="
cat /proc/asound/modules
echo ""

echo "=== LOADED SOUND MODULES ==="
lsmod | grep snd | sort
echo ""

echo "=== HDA INTEL MODULE PARAMETERS ==="
if [ -d /sys/module/snd_hda_intel/parameters ]; then
    for param in /sys/module/snd_hda_intel/parameters/*; do
        echo "$(basename $param): $(cat $param 2>/dev/null || echo 'N/A')"
    done
else
    echo "snd_hda_intel module not loaded or no parameters"
fi
echo ""

echo "=== AUDIO CARD DETAILS ==="
for card in /proc/asound/card*; do
    if [ -d "$card" ]; then
        echo "--- $(basename $card) ---"
        echo "ID: $(cat $card/id 2>/dev/null || echo 'N/A')"
        echo "Contents: $(ls -la $card/ 2>/dev/null || echo 'No access')"
        if [ -f "$card/codec#0" ]; then
            echo "Codec info:"
            head -10 "$card/codec#0" 2>/dev/null || echo "Cannot read codec"
        fi
        echo ""
    fi
done

echo "=== PLAYBACK DEVICES ==="
aplay -l 2>/dev/null || echo "aplay command not available"
echo ""

echo "=== CAPTURE DEVICES ==="
arecord -l 2>/dev/null || echo "arecord command not available"
echo ""

echo "=== PIPEWIRE STATUS ==="
wpctl status 2>/dev/null || echo "wpctl not available"
echo ""

echo "=== PCI DEVICE POWER STATES ==="
for device in /sys/bus/pci/devices/*/class; do
    class=$(cat "$device" 2>/dev/null)
    if [[ "$class" == "0x040300" ]]; then  # Audio device class
        device_path=$(dirname "$device")
        device_name=$(basename "$device_path")
        echo "Device: $device_name"
        echo "  Vendor: $(cat $device_path/vendor 2>/dev/null)"
        echo "  Device: $(cat $device_path/device 2>/dev/null)"
        echo "  Power state: $(cat $device_path/power/runtime_status 2>/dev/null)"
        echo "  Power control: $(cat $device_path/power/control 2>/dev/null)"
        echo ""
    fi
done

echo "=== KERNEL COMMAND LINE ==="
cat /proc/cmdline
echo ""

echo "=== MODPROBE CONFIGURATION ==="
if [ -f /etc/modprobe.d/nixos.conf ]; then
    echo "--- /etc/modprobe.d/nixos.conf ---"
    cat /etc/modprobe.d/nixos.conf
else
    echo "No modprobe configuration found"
fi
echo ""

echo "=== PROCESSES USING SOUND ==="
lsof /dev/snd/* 2>/dev/null || echo "No processes using sound devices or lsof not available"
echo ""

echo "=== DMESG AUDIO MESSAGES (last 20) ==="
dmesg | grep -i "snd_hda\|audio\|alsa" | tail -20 2>/dev/null || echo "Cannot access dmesg"
echo ""

echo "=== END DEBUG INFO ==="