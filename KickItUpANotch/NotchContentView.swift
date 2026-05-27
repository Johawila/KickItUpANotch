//
//  NotchContentView.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import SwiftUI

struct NotchContentView: View {
    var state: NotchState
    @State private var spotify   = SpotifyMonitor()
    @State private var stats     = SystemStatsMonitor()
    @State private var volume    = VolumeMonitor()
    @State private var brightness = BrightnessMonitor()
    @State private var outlook   = OutlookEventMonitor()
    @State private var waveform  = WaveformMonitor()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if state.isExpanded {
                    HStack(alignment: .top, spacing: 0) {

                        RightPanel(stats: stats, outlook: outlook)
                            .frame(maxWidth: .infinity)

                        panelDivider

                        ControlsPanel(volume: volume, brightness: brightness)
                            .frame(width: 100)

                        panelDivider

                        VStack {
                            Spacer(minLength: 0)
                            NowPlayingPanel(spotify: spotify, waveform: waveform)
                            Spacer(minLength: 0)
                        }
                        .frame(width: 200)
                    }
                    .padding(.top, 44)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.opacity)
                }
                Spacer(minLength: 0)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.isExpanded)
    }

    private var panelDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 80)
    }
}

// MARK: - Now Playing

private struct NowPlayingPanel: View {
    var spotify: SpotifyMonitor
    var waveform: WaveformMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Group {
                    if let art = spotify.albumArt {
                        Image(nsImage: art)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.white.opacity(0.08)
                            .overlay(
                                Image(systemName: "music.note")
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(spotify.trackName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(spotify.artistName)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 20) {
                        Button(action: { spotify.previousTrack() }) {
                            Image(systemName: "backward.fill")
                        }
                        Button(action: { spotify.playPause() }) {
                            Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16))
                        }
                        Button(action: { spotify.nextTrack() }) {
                            Image(systemName: "forward.fill")
                        }
                    }
                    .buttonStyle(NotchButtonStyle())
                }
            }

            WaveformView(monitor: waveform, isPlaying: spotify.isPlaying)
                .frame(height: 26)
        }
    }
}

// MARK: - Volume & Brightness

private struct ControlsPanel: View {
    var volume: VolumeMonitor
    var brightness: BrightnessMonitor

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            VerticalSliderColumn(
                icon: "speaker.wave.2.fill",
                value: Binding(get: { volume.volume }, set: { volume.set($0) }),
                color: NSColor.white
            )
            VerticalSliderColumn(
                icon: "sun.max.fill",
                value: Binding(get: { brightness.brightness }, set: { brightness.set($0) }),
                color: NSColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
            )
            Spacer()
        }
    }
}

private struct VerticalSliderColumn: View {
    let icon: String
    @Binding var value: Double
    let color: NSColor

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))

            ScrollableSlider(value: $value, color: color, vertical: true)
                .frame(width: 20)
                .frame(maxHeight: .infinity)

        }
    }
}

// MARK: - Right Panel (Stats + Jira + GitHub)

private struct RightPanel: View {
    var stats: SystemStatsMonitor
    var outlook: OutlookEventMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                StatPill(label: "CPU", value: stats.cpuUsage, color: cpuColor(stats.cpuUsage))
                StatPill(label: "RAM", value: stats.ramUsage, color: .blue)
                StatPill(label: stats.isCharging ? "BAT⚡" : "BAT", value: stats.batteryLevel, color: batteryColor(stats.batteryLevel))
            }

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 3)

            OutlookEventView(monitor: outlook)
        }
        .padding(.horizontal, 12)
    }

    private func cpuColor(_ v: Double) -> Color { v > 0.8 ? .red : v > 0.5 ? .orange : .green }
    private func batteryColor(_ v: Double) -> Color { v < 0.2 ? .red : v < 0.4 ? .orange : .green }
}


private struct StatPill: View {
    let label: String
    let value: Double
    let color: Color
    var showPercent: Bool = true

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
            if showPercent {
                Text("\(Int(value * 100))%")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
                .frame(width: 34, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(1, value)))
                }
            }
            .frame(height: 4)

            Text("\(Int(value * 100))%")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Outlook Event

private struct OutlookEventView: View {
    var monitor: OutlookEventMonitor
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if monitor.events.isEmpty {
                Text("No upcoming events")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
            } else {
                ForEach(Array(monitor.events.prefix(3).enumerated()), id: \.offset) { index, event in
                    EventRow(event: event, isPrimary: index == 0, pulse: $pulse)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EventRow: View {
    let event: CalendarEvent
    let isPrimary: Bool
    @Binding var pulse: Bool

    private var urgencyColor: Color {
        guard isPrimary else { return .white.opacity(0) }
        if event.secondsUntil <= 0      { return .orange }
        if event.secondsUntil < 15 * 60 { return .red }
        if event.secondsUntil < 30 * 60 { return .orange }
        return .white.opacity(0.55)
    }

    private var isUrgent: Bool { isPrimary && event.secondsUntil < 15 * 60 }
    private var titleOpacity: Double { isPrimary ? 1.0 : 0.4 }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                if isUrgent {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 5, height: 5)
                        .opacity(pulse ? 1 : 0.2)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                pulse = true
                            }
                        }
                }
                Text(event.timeUntil)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(isPrimary ? urgencyColor : .white.opacity(0.3))
            }
            Text(event.title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(titleOpacity))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Microsoft Outlook.app"))
        }
    }
}

#Preview("Now") {
    OutlookEventView(monitor: .mock(scenario: .now))
        .frame(width: 170)
        .padding()
        .background(Color.black)
}

#Preview("Critical < 15m") {
    OutlookEventView(monitor: .mock(scenario: .critical))
        .frame(width: 170)
        .padding()
        .background(Color.black)
}

#Preview("Warning < 30m") {
    OutlookEventView(monitor: .mock(scenario: .warning))
        .frame(width: 170)
        .padding()
        .background(Color.black)
}

#Preview("Normal") {
    OutlookEventView(monitor: .mock(scenario: .normal))
        .frame(width: 170)
        .padding()
        .background(Color.black)
}

// MARK: - Button Style

private struct NotchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white.opacity(0.4) : .white)
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
