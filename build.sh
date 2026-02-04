#!/bin/bash
cd "$(dirname "$0")"
swiftc -o SpotifyMenuBar.app/Contents/MacOS/SpotifyMenuBar main.swift -framework Cocoa -framework ServiceManagement
echo "Build complete! Run with: open SpotifyMenuBar.app"
