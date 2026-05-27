//
//  NotchWindow.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import AppKit
import SwiftUI

class NotchWindow: NSWindow {

    // MARK: - Geometry

    private let collapsedHeight: CGFloat = 32
    private let expandedHeight: CGFloat = 210
    private let expandedWidth: CGFloat = 580
    private let cornerRadius: CGFloat = 16
    private let expandDuration: TimeInterval = 0.45
    private let collapseDuration: TimeInterval = 0.35

    private var isAnimating = false
    private let state = NotchState()

    // MARK: - Init

    init() {
        let screen = NSScreen.main!
        let notchWidth = NotchWindow.calcNotchWidth(screen: screen)
        let collapsedFrame = NotchWindow.calcCollapsedRect(screen: screen, width: notchWidth, height: 32)

        super.init(
            contentRect: collapsedFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configure()
        setContentView()
    }

    // MARK: - Configuration

    private func configure() {
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        ignoresMouseEvents = false
        isMovable = false
    }

    private func setContentView() {
        let host = NSHostingView(rootView: NotchContentView(state: state))
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.black.cgColor
        host.layer?.cornerRadius = cornerRadius
        host.layer?.masksToBounds = true
        host.translatesAutoresizingMaskIntoConstraints = false
        contentView = host
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: host.superview!.topAnchor),
            host.bottomAnchor.constraint(equalTo: host.superview!.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: host.superview!.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: host.superview!.trailingAnchor)
        ])
        setupTrackingArea()
    }

    // MARK: - Tracking

    private func setupTrackingArea() {
        guard let cv = contentView else { return }
        // Remove all existing tracking areas
        cv.trackingAreas.forEach { cv.removeTrackingArea($0) }
        let area = NSTrackingArea(
            rect: cv.bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        cv.addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        guard state.isEnabled else { return }
        expand()
    }

    override func mouseExited(with event: NSEvent) {
        guard state.isEnabled else { return }
        collapse()
    }

    override func rightMouseDown(with event: NSEvent) {
        if state.isEnabled {
            collapse()
            state.isEnabled = false
        } else {
            state.isEnabled = true
        }
    }

    // MARK: - Expand / Collapse

    private func expand() {
        guard !state.isExpanded, !isAnimating else { return }
        isAnimating = true

        let screen = NSScreen.main!
        let targetFrame = expandedRect(screen: screen)

        // Frame expands first
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = expandDuration
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.4, 0.4, 1.0)
            animator().setFrame(targetFrame, display: true)
        } completionHandler: {
            self.isAnimating = false
            self.setupTrackingArea()
        }

        // Content fades in after frame is mostly open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.state.isExpanded = true
        }
    }

    private func collapse() {
        guard state.isExpanded, !isAnimating else { return }
        isAnimating = true

        // Content fades out first (takes 0.25s per the SwiftUI animation)
        state.isExpanded = false

        let screen = NSScreen.main!
        let notchWidth = NotchWindow.calcNotchWidth(screen: screen)
        let targetFrame = NotchWindow.calcCollapsedRect(screen: screen, width: notchWidth, height: collapsedHeight)

        // Wait for content to finish fading, then collapse the frame
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = self.collapseDuration
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().setFrame(targetFrame, display: true)
            } completionHandler: {
                self.isAnimating = false
            }
        }
    }

    // MARK: - Geometry Helpers

    private static func calcNotchWidth(screen: NSScreen) -> CGFloat {
        let fullWidth = screen.frame.width
        let leftArea = screen.auxiliaryTopLeftArea?.width ?? 0
        let rightArea = screen.auxiliaryTopRightArea?.width ?? 0
        let notch = fullWidth - leftArea - rightArea
        return notch > 0 ? notch : 200
    }

    private static func calcCollapsedRect(screen: NSScreen, width: CGFloat, height: CGFloat) -> NSRect {
        let screenFrame = screen.frame
        let x = screenFrame.midX - width / 2
        let y = screenFrame.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func expandedRect(screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let x = screenFrame.midX - expandedWidth / 2
        let y = screenFrame.maxY - expandedHeight
        return NSRect(x: x, y: y, width: expandedWidth, height: expandedHeight)
    }
}
	
