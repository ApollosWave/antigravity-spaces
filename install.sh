#!/usr/bin/env bash
set -e

echo "==> Installing Antigravity Spaces for macOS..."

INSTALL_DIR="$HOME/.local/bin"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.apolloswave.antigravity-spaces.plist"

mkdir -p "$INSTALL_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Compiling native Swift binary..."
swiftc -O -o "$INSTALL_DIR/antigravity-spaces" "$SCRIPT_DIR/main.swift"

echo "==> Installed binary to $INSTALL_DIR/antigravity-spaces"

# Verify PATH configuration
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "Note: Add ~/.local/bin to your PATH in ~/.zshrc:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Configure launchd service for automatic launch on login
mkdir -p "$PLIST_DIR"
cat << PLIST > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.apolloswave.antigravity-spaces</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/antigravity-spaces</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST

# Reload launch agent
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE" 2>/dev/null || true

echo "==> Installation complete. Antigravity Spaces is active in your menu bar."
