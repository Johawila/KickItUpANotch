//
//  ScrollableSlider.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import SwiftUI
import AppKit

struct ScrollableSlider: NSViewRepresentable {
    @Binding var value: Double
    var color: NSColor = .white
    var vertical: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator(binding: $value) }

    func makeNSView(context: Context) -> SliderNSView {
        let v = SliderNSView()
        v.coordinator = context.coordinator
        v.fillColor = color
        v.vertical = vertical
        v.value = value
        return v
    }

    func updateNSView(_ nsView: SliderNSView, context: Context) {
        nsView.value = value
        nsView.fillColor = color
        nsView.vertical = vertical
        nsView.needsDisplay = true
    }

    final class Coordinator {
        var binding: Binding<Double>
        init(binding: Binding<Double>) { self.binding = binding }
        func update(_ v: Double) { binding.wrappedValue = max(0, min(1, v)) }
    }
}

final class SliderNSView: NSView {
    var value: Double = 0.5 { didSet { needsDisplay = true } }
    var fillColor: NSColor = .white
    var vertical: Bool = false
    weak var coordinator: ScrollableSlider.Coordinator?

    private let trackW: CGFloat = 5
    private let thumbD: CGFloat = 11

    override func draw(_ dirtyRect: NSRect) {
        vertical ? drawVertical() : drawHorizontal()
    }

    private func drawHorizontal() {
        let inset = thumbD / 2
        let trackY = (bounds.height - trackW) / 2
        let trackRect = NSRect(x: inset, y: trackY, width: bounds.width - thumbD, height: trackW)

        NSColor.white.withAlphaComponent(0.15).setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: trackW / 2, yRadius: trackW / 2).fill()

        let fillRect = NSRect(x: trackRect.minX, y: trackRect.minY,
                              width: trackRect.width * CGFloat(value), height: trackW)
        fillColor.setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: trackW / 2, yRadius: trackW / 2).fill()

        let thumbX = trackRect.minX + trackRect.width * CGFloat(value) - thumbD / 2
        let thumbRect = NSRect(x: thumbX, y: (bounds.height - thumbD) / 2, width: thumbD, height: thumbD)
        NSColor.white.setFill()
        NSBezierPath(ovalIn: thumbRect).fill()
    }

    private func drawVertical() {
        let inset = thumbD / 2
        let trackX = (bounds.width - trackW) / 2
        let trackRect = NSRect(x: trackX, y: inset, width: trackW, height: bounds.height - thumbD)

        NSColor.white.withAlphaComponent(0.15).setFill()
        NSBezierPath(roundedRect: trackRect, xRadius: trackW / 2, yRadius: trackW / 2).fill()

        let fillH = trackRect.height * CGFloat(value)
        let fillRect = NSRect(x: trackRect.minX, y: trackRect.minY, width: trackW, height: fillH)
        fillColor.setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: trackW / 2, yRadius: trackW / 2).fill()

        let thumbY = trackRect.minY + trackRect.height * CGFloat(value) - thumbD / 2
        let thumbRect = NSRect(x: (bounds.width - thumbD) / 2, y: thumbY, width: thumbD, height: thumbD)
        NSColor.white.setFill()
        NSBezierPath(ovalIn: thumbRect).fill()
    }

    override func mouseDown(with event: NSEvent) { applyMouse(event) }
    override func mouseDragged(with event: NSEvent) { applyMouse(event) }

    private func applyMouse(_ event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        let inset = thumbD / 2
        if vertical {
            let trackH = bounds.height - thumbD
            coordinator?.update(Double((pt.y - inset) / trackH))
        } else {
            let trackW = bounds.width - thumbD
            coordinator?.update(Double((pt.x - inset) / trackW))
        }
    }

    override func scrollWheel(with event: NSEvent) {
        let raw = Double(event.scrollingDeltaY) / 200
        // isDirectionInvertedFromDevice = true means natural scrolling is ON
        // Natural: scroll up → positive deltaY → should increase value
        // Traditional: scroll up → negative deltaY → should also increase value
        let delta = event.isDirectionInvertedFromDevice ? -raw : raw
        coordinator?.update(value + delta)
    }
}
