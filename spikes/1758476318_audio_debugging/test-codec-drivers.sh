#!/usr/bin/env bash

# Test different codec drivers for AMD HD Audio
# Usage: ./test-codec-drivers.sh

CODECS=(
    "snd_hda_codec_analog"
    "snd_hda_codec_via" 
    "snd_hda_codec_cmedia"
    "snd_hda_codec_conexant"
    "snd_hda_codec_cirrus"
    "snd_hda_codec_idt"
    "snd_hda_codec_ca0110"
    "snd_hda_codec_ca0132"
    "snd_hda_codec_si3054"
    "snd_hda_codec_senarytech"
    "snd_hda_codec_cs8409"
)

echo "=== AMD HD Audio Codec Driver Test ==="
echo "Testing different codec drivers to see if AMD card (card0) detects a codec"
echo ""

for codec in "${CODECS[@]}"; do
    echo "========================================="
    echo "Testing codec: $codec"
    echo "========================================="
    
    # Stop audio services
    echo "Stopping PipeWire services..."
    systemctl --user stop pipewire pipewire-pulse wireplumber 2>/dev/null
    
    # Load the codec module
    echo "Loading $codec module..."
    if sudo modprobe "$codec" 2>/dev/null; then
        echo "✓ Module loaded successfully"
    else
        echo "✗ Failed to load module"
        continue
    fi
    
    # Wait for detection
    sleep 3
    
    # Check AMD card (card0) for codec files
    echo "Checking AMD card (card0) for codec detection..."
    if ls /proc/asound/card0/codec* 2>/dev/null; then
        echo "🎉 SUCCESS! Codec files found on AMD card:"
        ls -la /proc/asound/card0/codec* 2>/dev/null
        echo ""
        echo "Codec info:"
        head -10 /proc/asound/card0/codec#0 2>/dev/null || echo "Cannot read codec info"
        echo ""
        echo "ALSA playback devices:"
        aplay -l | grep -A5 "card 0" || echo "No playback devices"
        
        # Test with PipeWire
        echo ""
        echo "Testing with PipeWire..."
        systemctl --user start pipewire pipewire-pulse wireplumber
        sleep 3
        wpctl status | grep -A10 "Sinks:" || echo "No PipeWire sinks"
        
        echo ""
        echo "🎉 FOUND WORKING CODEC: $codec"
        echo "Press Enter to continue testing other codecs, or Ctrl+C to stop"
        read -r
    else
        echo "❌ No codec files found on AMD card"
    fi
    
    # Unload the codec module
    echo "Unloading $codec module..."
    sudo modprobe -r "$codec" 2>/dev/null || echo "Could not unload module"
    
    echo ""
done

echo "========================================="
echo "Codec testing complete!"
echo "Restarting PipeWire services..."
systemctl --user start pipewire pipewire-pulse wireplumber

echo "Final status:"
wpctl status | head -20