//
//  VolumeMonitor.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import Foundation
import Observation
import AppKit

@Observable
final class VolumeMonitor {
    var volume: Double = 0.5

    init() { fetchVolume() }

    private func fetchVolume() {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            guard let result = NSAppleScript(source: "return output volume of (get volume settings)")?
                    .executeAndReturnError(&error) else { return }
            let vol = Double(result.int32Value) / 100.0
            DispatchQueue.main.async { self.volume = vol }
        }
    }

    func set(_ value: Double) {
        volume = max(0, min(1, value))
        let vol = Int(volume * 100)
        DispatchQueue.global(qos: .userInitiated).async {
            NSAppleScript(source: "set volume output volume \(vol)")?.executeAndReturnError(nil)
        }
    }
}
