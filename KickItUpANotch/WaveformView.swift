//
//  WaveformView.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import SwiftUI
import Observation

@Observable
final class WaveformMonitor {
    var bars: [CGFloat] = Array(repeating: 0.05, count: 28)
    private var timer: Timer?

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        bars = bars.map { _ in CGFloat.random(in: 0.03...0.08) }
    }

    private func tick() {
        bars = (0..<bars.count).map { i in
            let prev = i > 0 ? bars[i - 1] : CGFloat.random(in: 0.1...1.0)
            return (prev + CGFloat.random(in: 0.1...1.0)) / 2
        }
    }
}

struct WaveformView: View {
    var monitor: WaveformMonitor
    var isPlaying: Bool

    private let spotifyGreen = Color(red: 0.11, green: 0.73, blue: 0.33)

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<monitor.bars.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(isPlaying ? spotifyGreen : Color.white.opacity(0.15))
                    .frame(width: 3, height: max(3, monitor.bars[i] * 30))
            }
        }
        .animation(.easeInOut(duration: 0.12), value: monitor.bars)
        .onChange(of: isPlaying) { _, playing in
            playing ? monitor.start() : monitor.stop()
        }
        .onAppear {
            if isPlaying { monitor.start() }
        }
    }
}
