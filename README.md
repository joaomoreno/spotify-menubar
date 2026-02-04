# Spotify Menu Bar

A simple macOS menu bar app to control Spotify playback.

## Features

- Shows current track and artist in a popover
- Play/Pause control
- Next/Previous track
- Shows Spotify running status
- Open Spotify if not running

## Build

```bash
./build.sh
```

Or manually:
```bash
swiftc -o SpotifyMenuBar.app/Contents/MacOS/SpotifyMenuBar main.swift -framework Cocoa -framework SwiftUI
```

## Run

```bash
open SpotifyMenuBar.app
```

## Requirements

- macOS 12.0+
- Spotify desktop app installed

## Note

On first run, macOS may prompt you to allow the app to control Spotify via AppleScript. Click "OK" to allow.
