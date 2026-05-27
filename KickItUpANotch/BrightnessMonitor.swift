//
//  BrightnessMonitor.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import Foundation
import CoreGraphics
import Observation

@Observable
final class BrightnessMonitor {
    var brightness: Double = 0.5

    private typealias GetFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private var handle: UnsafeMutableRawPointer?
    private var getFunc: GetFunc?
    private var setFunc: SetFunc?

    init() {
        let path = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
        handle = dlopen(path, RTLD_LAZY)
        if let h = handle {
            if let sym = dlsym(h, "DisplayServicesGetBrightness") {
                getFunc = unsafeBitCast(sym, to: GetFunc.self)
            }
            if let sym = dlsym(h, "DisplayServicesSetBrightness") {
                setFunc = unsafeBitCast(sym, to: SetFunc.self)
            }
        }
        brightness = Double(read())
    }

    deinit {
        if let h = handle { dlclose(h) }
    }

    private func read() -> Float {
        var value: Float = 0.5
        getFunc?(CGMainDisplayID(), &value)
        return value
    }

    func set(_ value: Double) {
        brightness = max(0, min(1, value))
        setFunc?(CGMainDisplayID(), Float(brightness))
    }
}
