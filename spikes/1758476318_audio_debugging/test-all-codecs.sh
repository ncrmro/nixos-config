#!/usr/bin/env bash

# Test ALL available codec drivers for AMD HD Audio
# Including SOC and other codec types

CODECS=(
    # Standard HDA codecs
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
    
    # AC97 codec (older standard)
    "snd_ac97_codec"
    
    # SOC HDA codec (might work for integrated audio)
    "snd_soc_hda_codec"
    
    # Cirrus scodec modules (sometimes used with Realtek)
    "snd_hda_scodec_cs35l41"
    "snd_hda_scodec_cs35l56"
    
    # Component codec support
    "snd_hda_scodec_component"
    
    # TAS2781 (sometimes paired with ALC codecs)
    "snd_hda_scodec_tas2781_i2c"
    
    # Re-test Realtek with forced loading
    "snd_hda_codec_realtek"
)

echo "=== COMPREHENSIVE AMD HD Audio Codec Driver Test ==="
echo "Testing ALL available codec drivers including SOC and component drivers"
echo "AMD Controller: 0c:00.4 (card0)"
echo ""

# First, let's try loading the main HDA codec module
echo "Loading base HDA codec module..."
sudo modprobe snd_hda_codec 2>/dev/null

for codec in "${CODECS[@]}"; do
    echo "========================================="
    echo "Testing codec: $codec"
    echo "========================================="
    
    # Stop audio services
    echo "Stopping PipeWire services..."
    systemctl --user stop pipewire pipewire-pulse wireplumber 2>/dev/null
    sleep 1
    
    # Load the codec module
    echo "Loading $codec module..."
    if sudo modprobe "$codec" 2>/dev/null; then
        echo "✓ Module loaded successfully"
        
        # Also try loading dependencies that might help
        if [[ "$codec" == *"scodec"* ]]; then
            sudo modprobe snd_hda_scodec_component 2>/dev/null
        fi
        
    else
        echo "✗ Failed to load module - may not exist or have dependencies"
        continue
    fi
    
    # Wait for detection
    echo "Waiting for codec detection..."
    sleep 4
    
    # Check AMD card (card0) for codec files
    echo "Checking AMD card (card0) for codec detection..."
    if ls /proc/asound/card0/codec* 2>/dev/null >/dev/null; then
        echo "🎉 SUCCESS! Codec files found on AMD card:"
        ls -la /proc/asound/card0/codec* 2>/dev/null
        echo ""
        echo "Codec info:"
        head -15 /proc/asound/card0/codec#0 2>/dev/null || echo "Cannot read codec info"
        echo ""
        echo "ALSA playback devices:"
        aplay -l | grep -A5 "card 0" || echo "No playback devices found"
        
        # Test with PipeWire
        echo ""
        echo "Testing with PipeWire..."
        systemctl --user start pipewire pipewire-pulse wireplumber
        sleep 4
        echo "PipeWire sinks:"
        wpctl status | grep -A15 "Sinks:" || echo "No PipeWire sinks"
        
        echo ""
        echo "🎉 FOUND WORKING CODEC: $codec"
        echo "This codec successfully detected hardware on AMD controller!"
        echo ""
        echo "Press Enter to continue testing (to see if others work too) or Ctrl+C to stop here"
        read -r
    else
        echo "❌ No codec files found on AMD card with $codec"
        
        # Check if any PCM devices appeared
        if ls /proc/asound/card0/pcm* 2>/dev/null >/dev/null; then
            echo "ℹ️  PCM devices found (codec might be partially working):"
            ls -la /proc/asound/card0/pcm* 2>/dev/null
        fi
    fi
    
    # Unload the codec module(s)
    echo "Unloading codec modules..."
    sudo modprobe -r "$codec" 2>/dev/null
    if [[ "$codec" == *"scodec"* ]]; then
        sudo modprobe -r snd_hda_scodec_component 2>/dev/null
    fi
    
    echo ""
done

echo "========================================="
echo "Comprehensive codec testing complete!"
echo ""
echo "Summary: If no codec was detected, this indicates:"
echo "1. Hardware issue - codec not physically connected to AMD controller"
echo "2. BIOS issue - audio disabled in firmware"  
echo "3. Driver issue - kernel doesn't support this specific codec variant"
echo ""
echo "Restarting PipeWire services..."
systemctl --user start pipewire pipewire-pulse wireplumber

echo ""
echo "Final audio status:"
wpctl status | head -25