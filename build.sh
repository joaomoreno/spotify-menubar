#!/bin/bash
cd "$(dirname "$0")"
mkdir -p SpotifyMenuBar.app/Contents/MacOS
swiftc -o SpotifyMenuBar.app/Contents/MacOS/SpotifyMenuBar main.swift -framework Cocoa -framework ServiceManagement

# Create Info.plist if it doesn't exist
if [ ! -f SpotifyMenuBar.app/Contents/Info.plist ]; then
cat > SpotifyMenuBar.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SpotifyMenuBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.joaomoreno.SpotifyMenuBar</string>
    <key>CFBundleName</key>
    <string>SpotifyMenuBar</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF
fi

echo "Build complete! Run with: open SpotifyMenuBar.app"
