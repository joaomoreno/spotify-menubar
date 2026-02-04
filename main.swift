import Cocoa
import ServiceManagement

// MARK: - Spotify Controller
class SpotifyController: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTrack: String = "Not Playing"
    @Published var artist: String = ""
    @Published var isSpotifyRunning: Bool = false
    @Published var artworkImage: NSImage?
    
    private var timer: Timer?
    private var lastArtworkUrl: String = ""
    
    init() {
        startPolling()
    }
    
    func startPolling() {
        updateStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }
    
    func updateStatus() {
        isSpotifyRunning = isAppRunning("Spotify")
        
        if isSpotifyRunning {
            isPlaying = getSpotifyPlayerState()
            currentTrack = getSpotifyTrackName()
            artist = getSpotifyArtist()
            updateArtwork()
        } else {
            isPlaying = false
            currentTrack = "Spotify not running"
            artist = ""
            artworkImage = nil
            lastArtworkUrl = ""
        }
    }
    
    func updateArtwork() {
        let artworkUrl = getSpotifyArtworkUrl()
        if artworkUrl != lastArtworkUrl && !artworkUrl.isEmpty {
            lastArtworkUrl = artworkUrl
            downloadArtwork(from: artworkUrl)
        }
    }
    
    func getSpotifyArtworkUrl() -> String {
        if !isSpotifyRunning { return "" }
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is not stopped then
                    return artwork url of current track
                end if
            end tell
        end if
        return ""
        """
        return runAppleScript(script)
    }
    
    func downloadArtwork(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.artworkImage = image
            }
        }.resume()
    }
    
    func isAppRunning(_ appName: String) -> Bool {
        let apps = NSWorkspace.shared.runningApplications
        return apps.contains { $0.localizedName == appName }
    }
    
    func getSpotifyPlayerState() -> Bool {
        if !isSpotifyRunning { return false }
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                return player state as string
            end tell
        end if
        return "stopped"
        """
        let result = runAppleScript(script)
        return result == "playing"
    }
    
    func getSpotifyTrackName() -> String {
        if !isSpotifyRunning { return "" }
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is not stopped then
                    return name of current track
                end if
            end tell
        end if
        return "No track"
        """
        return runAppleScript(script)
    }
    
    func getSpotifyArtist() -> String {
        if !isSpotifyRunning { return "" }
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is not stopped then
                    return artist of current track
                end if
            end tell
        end if
        return ""
        """
        return runAppleScript(script)
    }
    
    func playPause() {
        if !isSpotifyRunning { return }
        let script = """
        tell application "Spotify"
            playpause
        end tell
        """
        _ = runAppleScript(script)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.updateStatus()
        }
    }
    
    func nextTrack() {
        if !isSpotifyRunning { return }
        let script = """
        tell application "Spotify"
            next track
        end tell
        """
        _ = runAppleScript(script)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateStatus()
        }
    }
    
    func previousTrack() {
        if !isSpotifyRunning { return }
        let script = """
        tell application "Spotify"
            previous track
        end tell
        """
        _ = runAppleScript(script)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateStatus()
        }
    }
    
    func openSpotify() {
        NSWorkspace.shared.launchApplication("Spotify")
    }
    
    private func runAppleScript(_ script: String) -> String {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue ?? ""
            }
        }
        return ""
    }
}

// MARK: - Two Line View
class TwoLineView: NSView {
    private var artistText: String = ""
    private var trackText: String = ""
    private let artistFont = NSFont.systemFont(ofSize: 9, weight: .regular)
    private let trackFont = NSFont.systemFont(ofSize: 11, weight: .medium)
    
    var artist: String {
        get { artistText }
        set {
            artistText = newValue
            needsDisplay = true
        }
    }
    
    var track: String {
        get { trackText }
        set {
            trackText = newValue
            needsDisplay = true
        }
    }
    
    func calculateWidth() -> CGFloat {
        let artistAttrs: [NSAttributedString.Key: Any] = [.font: artistFont]
        let trackAttrs: [NSAttributedString.Key: Any] = [.font: trackFont]
        
        let artistWidth = (artistText as NSString).size(withAttributes: artistAttrs).width
        let trackWidth = (trackText as NSString).size(withAttributes: trackAttrs).width
        
        return min(max(artistWidth, trackWidth) + 8, 152) // 180 - 28 for icon
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .right
        
        let artistAttrs: [NSAttributedString.Key: Any] = [
            .font: artistFont,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        let trackAttrs: [NSAttributedString.Key: Any] = [
            .font: trackFont,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        // Draw artist on top
        let artistRect = NSRect(x: 2, y: 10, width: bounds.width - 4, height: 12)
        (artistText as NSString).draw(in: artistRect, withAttributes: artistAttrs)
        
        // Draw track on bottom
        let trackRect = NSRect(x: 2, y: -1, width: bounds.width - 4, height: 14)
        (trackText as NSString).draw(in: trackRect, withAttributes: trackAttrs)
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var spotifyController: SpotifyController!
    var twoLineView: TwoLineView!
    var iconView: NSImageView!
    let maxWidth: CGFloat = 180
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        spotifyController = SpotifyController()
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Create two-line view on the left
            twoLineView = TwoLineView(frame: NSRect(x: 4, y: 0, width: 70, height: 22))
            button.addSubview(twoLineView)
            
            // Create icon view on the right
            iconView = NSImageView(frame: NSRect(x: 78, y: 2, width: 18, height: 18))
            iconView.imageScaling = .scaleProportionallyUpOrDown
            iconView.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Spotify")
            button.addSubview(iconView)
            
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Update menu bar icon based on state
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMenuBarIcon()
        }
    }
    
    @objc func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            spotifyController.openSpotify()
        }
    }
    
    func showContextMenu() {
        let menu = NSMenu()
        
        if spotifyController.isSpotifyRunning {
            let playPauseTitle = spotifyController.isPlaying ? "Pause" : "Play"
            let playPauseItem = NSMenuItem(title: playPauseTitle, action: #selector(playPause), keyEquivalent: "")
            playPauseItem.target = self
            menu.addItem(playPauseItem)
            
            let nextItem = NSMenuItem(title: "Next Track", action: #selector(nextTrack), keyEquivalent: "")
            nextItem.target = self
            menu.addItem(nextItem)
            
            let prevItem = NSMenuItem(title: "Previous Track", action: #selector(previousTrack), keyEquivalent: "")
            prevItem.target = self
            menu.addItem(prevItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    @objc func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                print("Failed to toggle launch at login: \(error)")
            }
        }
    }
    
    @objc func playPause() {
        spotifyController.playPause()
    }
    
    @objc func nextTrack() {
        spotifyController.nextTrack()
    }
    
    @objc func previousTrack() {
        spotifyController.previousTrack()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func updateMenuBarIcon() {
        // Hide if Spotify isn't running or no track is playing
        if !spotifyController.isSpotifyRunning {
            statusItem.isVisible = false
            return
        }
        
        let hasTrack = !spotifyController.currentTrack.isEmpty 
            && spotifyController.currentTrack != "Spotify not running"
            && spotifyController.currentTrack != "No track"
        
        if !hasTrack {
            statusItem.isVisible = false
            return
        }
        statusItem.isVisible = true
        
        // Update text
        twoLineView.artist = spotifyController.artist
        twoLineView.track = spotifyController.currentTrack
        
        // Update width dynamically
        let textWidth = twoLineView.calculateWidth()
        let totalWidth = min(textWidth + 28, maxWidth)
        statusItem.length = totalWidth
        
        twoLineView.frame = NSRect(x: 4, y: 0, width: textWidth, height: 22)
        iconView.frame = NSRect(x: totalWidth - 22, y: 2, width: 18, height: 18)
        
        // Update album art icon
        if let artwork = spotifyController.artworkImage {
            let size = NSSize(width: 18, height: 18)
            let resized = NSImage(size: size)
            resized.lockFocus()
            let rect = NSRect(origin: .zero, size: size)
            let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
            path.addClip()
            artwork.draw(in: rect, from: NSRect(origin: .zero, size: artwork.size), operation: .copy, fraction: 1.0)
            resized.unlockFocus()
            iconView.image = resized
        } else {
            iconView.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Spotify")
        }
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
