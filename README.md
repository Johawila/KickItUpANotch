# KickItUpANotch

A macOS app that lives inside the notch. Hover to expand it — no menu bar icon, no dock icon, nothing visible until you need it.

Requires a MacBook with a notch (MacBook Pro 2021+).

---

## What's in the expanded view

**Now Playing** — Spotify track name, artist, and album art fetched from iTunes. Play/pause, previous, and next controls. Animated waveform while music is playing.

**Volume & Brightness** — Vertical scroll sliders. Scroll or drag to adjust either without leaving the notch.

**System stats** — CPU, RAM, and battery as compact pills with color coding (green → orange → red as usage rises).

**Calendar** — Next three Outlook events from your calendar. The nearest event shows time remaining; under 30 minutes it turns orange, under 15 minutes it pulses red. Tap to open Outlook.

---

## Interaction

- **Hover** — expands with a spring animation
- **Move away** — collapses, content fades out first then the frame contracts
- **Right-click** — toggles the whole thing on/off (useful during screen sharing)

---

## Setup

1. Build and run in Xcode (macOS 14+, no App Store).
2. Grant Outlook calendar access when prompted.
3. Spotify integration works automatically via AppleScript — no API keys needed.

---

## Tech

- Swift / SwiftUI + AppKit
- `NSWindow` at `.statusBar` level, geometry matched to the physical notch via `auxiliaryTopLeftArea` / `auxiliaryTopRightArea`
- Spotify via AppleScript + `DistributedNotificationCenter`
- Outlook events via `EventKit`
- iTunes Search API for album art
- No third-party dependencies
