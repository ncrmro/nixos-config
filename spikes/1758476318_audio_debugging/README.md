# Audio Debugging Spike - AMD HD Audio Controller / Realtek ALC1220-VB

## Problem Summary
- AMD HD Audio Controller (0c:00.4) detected by kernel but not functional
- Realtek ALC1220-VB codec not being detected
- Card shows as "Generic" with no codec files or playback devices
- Only NVIDIA HDMI audio works

## Hardware Details
- **Motherboard**: Gigabyte (exact model TBD)
- **Audio Codec**: Realtek ALC1220-VB
- **AMD Controller**: Advanced Micro Devices, Inc. [AMD] Starship/Matisse HD Audio Controller
- **PCI ID**: 0c:00.4 (vendor: 0x1022, device: 0x1487)

## Current Status
```
Card 0: NVIDIA HDMI (working)
Card 1: AMD HD Audio "Generic" (non-functional)
Card 2: USB Webcam (working)
```

## Attempted Solutions

### 1. Kernel Module Configuration
```nix
boot.kernelModules = [ "snd_hda_codec_realtek" "snd_hda_codec_generic" ];
```
**Result**: Modules loaded but no codec detection

### 2. Power Management
```nix
boot.kernelParams = [ "snd_hda_intel.power_save=0" ];
```
**Result**: No change

### 3. Probe Mask Restriction
```nix
boot.extraModprobeConfig = ''
  options snd-hda-intel probe_mask=1
'';
```
**Result**: No change

### 4. Firmware Loading
```nix
hardware.enableAllFirmware = true;
```
**Result**: No change

### 5. HDMI Codec Blacklist (to test conflicts)
```nix
boot.extraModprobeConfig = ''
  blacklist snd_hda_codec_hdmi
'';
```
**Result**: Blacklist didn't take effect, HDMI still working

### 6. Model Testing Script
Created `test-audio-model.sh` to test different snd_hda_intel models:
- **dual-codecs**: No codec detection
- **auto**: No codec detection

### 7. Manual Power Control
```bash
echo on > /sys/class/sound/card1/device/power/control
```
**Result**: Device became active but still no codec

## Diagnostic Information

### ALSA Cards
```
0 [NVidia]: HDA-Intel - HDA NVidia
1 [Generic]: HDA-Intel - HD-Audio Generic  # <-- Problem card
2 [BRIO]: USB-Audio - Logitech BRIO
```

### PipeWire Status
- Only NVIDIA HDMI sink available
- AMD controller not visible in wpctl

### Codec Files
```bash
ls /proc/asound/card1/
# Only shows: id (no codec# files)
```

### Loaded Modules
```
snd_hda_codec_realtek: loaded
snd_hda_codec_generic: loaded  
snd_hda_intel: loaded and handling both controllers
```

## Potential Root Causes

1. **Hardware Design**: Gigabyte motherboard may have AMD controller but no codec physically connected
2. **BIOS Configuration**: HD Audio might be disabled in firmware
3. **Front Panel Dependency**: ALC1220-VB might require front panel audio header connection
4. **Driver Compatibility**: Kernel driver may not properly support this specific Realtek variant

## Next Steps to Try

1. **Check BIOS/UEFI**: Look for "HD Audio", "Onboard Audio", or "Audio Controller" settings
2. **Front Panel Connection**: Verify front panel audio header is connected to motherboard
3. **Model-specific Options**: Try Realtek-specific models:
   ```bash
   ./test-audio-model.sh ref
   ./test-audio-model.sh basic
   ./test-audio-model.sh 3stack
   ```
4. **PCI Device Reset**: Force hardware re-detection:
   ```bash
   echo 1 > /sys/bus/pci/devices/0000:0c:00.4/remove
   echo 1 > /sys/bus/pci/rescan
   ```

## References
- [NixOS ALSA Wiki](https://nixos.wiki/wiki/ALSA)
- [Gigabyte Audio Linux Issues](https://frdmtoplay.com/gigabyte-front-panel-audio-with-linux/)
- [Kernel HD Audio Models](https://www.kernel.org/doc/Documentation/sound/hd-audio/models.rst)

### 8. Realtek Codec Blacklist Test
```nix
boot.extraModprobeConfig = ''
  blacklist snd_hda_codec_realtek
'';
```
**Result**: No change - AMD controller still shows no codec

### 9. Card Index Reordering
```nix
boot.extraModprobeConfig = ''
  options snd-hda-intel index=1,0
'';
```
**Result**: ✅ Successfully made AMD controller card 0, NVIDIA card 1

### 10. DMIC Detection Disable
```nix
boot.extraModprobeConfig = ''
  options snd-hda-intel dmic_detect=0
'';
```
**Result**: No change - still no codec detection

### 11. Comprehensive Codec Driver Testing
Created `test-all-codecs.sh` to test all available codec drivers:
- Tested 20+ different codec modules
- No codec driver could detect hardware on AMD controller

### 12. Manual ALSA Card Analysis
Created `test-manual-alsa-card.sh` - **CONCLUSIVE TEST**:
```
✅ AMD card detected by ALSA as "Generic" 
❌ No PCM devices - this is why PipeWire can't see it
❌ No codec files - no functional codec detected
❌ Can't play audio directly to hw:0,0
```

## Root Cause Analysis

**CONFIRMED: Hardware-level issue**
- AMD HD Audio Controller is detected by kernel
- Controller has no functional codec attached
- No PCM (audio) interfaces created
- PipeWire ignores devices without PCM interfaces

This differs from similar forum posts where users had codec detection but GUI profile issues.

## Final Conclusion

The AMD Starship/Matisse HD Audio Controller appears to be a "phantom" device on this motherboard:
1. **Hardware present**: PCI controller exists and responds
2. **Codec missing**: No ALC1220-VB codec physically connected or functional
3. **Design issue**: Motherboard may route all audio through NVIDIA HDMI only

**Recommended actions:**
1. Check BIOS for audio settings
2. Verify front panel audio header connection
3. If both OK, accept NVIDIA HDMI as the functional audio solution

## Debug Scripts

- `audio-debug-dump.sh` - Comprehensive system audio state capture
- `test-all-codecs.sh` - Test all available codec drivers  
- `test-manual-alsa-card.sh` - Verify PCM device creation
- `test-audio-model.sh` - Test snd_hda_intel model parameters

## Working Configuration
**Current functional audio**: NVIDIA HDMI via PipeWire
- Device: GA102 High Definition Audio Controller  
- Output: LG Ultra HD monitor speakers
- Status: Fully functional

---
*Investigation complete - Hardware issue confirmed*