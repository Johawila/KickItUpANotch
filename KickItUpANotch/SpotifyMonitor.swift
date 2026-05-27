//
//  SpotifyMonitor.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import Foundation
import AppKit
import Observation

@Observable
final class SpotifyMonitor {
    var trackName: String = "Nothing playing"
    var artistName: String = ""
    var isPlaying: Bool = false
    var albumArt: NSImage? = nil

    init() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, let info = notification.userInfo else { return }
            self.trackName = info["Name"] as? String ?? "Nothing playing"
            self.artistName = info["Artist"] as? String ?? ""
            self.isPlaying = (info["Player State"] as? String) == "Playing"
            self.fetchAlbumArt(artist: self.artistName, track: self.trackName)
        }

        fetchInitialState()
    }

    private func fetchInitialState() {
        DispatchQueue.global(qos: .userInitiated).async {
            let source = """
            tell application "Spotify"
                if it is running then
                    set t to name of current track
                    set a to artist of current track
                    set s to player state as string
                    return t & "|" & a & "|" & s
                end if
            end tell
            """
            var error: NSDictionary?
            guard let result = NSAppleScript(source: source)?.executeAndReturnError(&error),
                  let raw = result.stringValue else { return }
            let parts = raw.components(separatedBy: "|")
            guard parts.count >= 3 else { return }
            let track = parts[0]
            let artist = parts[1]
            let playing = parts[2].lowercased().contains("playing")
            DispatchQueue.main.async {
                self.trackName = track
                self.artistName = artist
                self.isPlaying = playing
            }
            self.fetchAlbumArt(artist: artist, track: track)
        }
    }

    private func fetchAlbumArt(artist: String, track: String) {
        let query = "\(artist) \(track)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(query)&entity=song&limit=1") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  let first = results.first,
                  let artString = first["artworkUrl100"] as? String,
                  let artURL = URL(string: artString.replacingOccurrences(of: "100x100bb", with: "300x300bb")),
                  let imageData = try? Data(contentsOf: artURL),
                  let image = NSImage(data: imageData) else { return }
            DispatchQueue.main.async { self?.albumArt = image }
        }.resume()
    }

    func playPause() { runCommand("playpause") }
    func nextTrack() { runCommand("next track") }
    func previousTrack() { runCommand("previous track") }

    private func runCommand(_ command: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            NSAppleScript(source: "tell application \"Spotify\" to \(command)")?.executeAndReturnError(nil)
        }
    }
}
