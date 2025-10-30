#!/usr/bin/env bash
# Check for active wake locks preventing monitor suspend

echo "=== Active Wake Lock Check ==="
echo ""

echo "1. Systemd Inhibitor Locks:"
systemd-inhibit --list
echo ""

echo "2. Hypridle Status (last 20 lines):"
systemctl --user status hypridle.service | tail -20
echo ""

echo "3. Recent Wake Lock Activity:"
journalctl --user -u hypridle.service --since "10 minutes ago" | grep -E "(inhibit|Cookie)" | tail -15
echo ""

echo "4. Current Inhibit Lock Count:"
journalctl --user -u hypridle.service --since "1 minute ago" | grep "Inhibit locks:" | tail -1
echo ""

echo "=== Recommendations ==="
echo "- Visit chrome://media-internals/ in Chrome to see active wake locks"
echo "- Check for tabs with video/audio players"
echo "- Look for browser extensions that might hold wake locks"
echo "- Consider closing Chrome temporarily to test if display suspends"
