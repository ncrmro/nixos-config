#!/usr/bin/env bash

# Test manual ALSA card activation for AMD Generic card
echo "=== Manual ALSA Card Test ==="
echo "Testing if we can manually activate the AMD 'Generic' card"
echo ""

echo "Current ALSA cards:"
cat /proc/asound/cards
echo ""

echo "Checking if card 0 has any PCM devices:"
if ls /proc/asound/card0/pcm* 2>/dev/null; then
    echo "PCM devices found!"
    ls -la /proc/asound/card0/pcm*
else
    echo "No PCM devices found - this is the problem!"
    echo "Without PCM devices, PipeWire won't see the card"
fi
echo ""

echo "Checking if we can play test sound directly to card 0:"
echo "Testing: aplay -D hw:0,0 /dev/zero (will error if no device)"
timeout 3 aplay -D hw:0,0 /dev/zero 2>&1 | head -5
echo ""

echo "Testing if we can force load analog codec:"
sudo modprobe snd_hda_codec_realtek 2>/dev/null
sudo modprobe snd_hda_codec_generic 2>/dev/null

echo "Waiting 5 seconds for codec detection..."
sleep 5

echo "Checking again for codec files:"
if ls /proc/asound/card0/codec* 2>/dev/null; then
    echo "SUCCESS! Codec files now exist:"
    ls -la /proc/asound/card0/codec*
    echo ""
    echo "Codec info:"
    head -10 /proc/asound/card0/codec#0 2>/dev/null
    
    echo ""
    echo "PCM devices:"
    ls -la /proc/asound/card0/pcm* 2>/dev/null || echo "Still no PCM devices"
    
    echo ""
    echo "ALSA playback test:"
    aplay -l | grep "card 0" || echo "No ALSA playback devices"
    
    echo ""
    echo "Restarting PipeWire to detect new codec:"
    systemctl --user restart pipewire pipewire-pulse wireplumber
    sleep 3
    
    echo "PipeWire devices now:"
    wpctl status | grep -A10 "Devices:"
    
else
    echo "Still no codec files - hardware issue confirmed"
fi

echo ""
echo "=== Test Complete ==="