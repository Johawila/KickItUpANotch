//
//  OutlookEventMonitor.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import Foundation
import Observation

struct CalendarEvent {
    var title: String
    var timeUntil: String
    var secondsUntil: Double
}

@Observable
final class OutlookEventMonitor {
    var events: [CalendarEvent] = []

    private var timer: Timer?

    private static var icsURL: URL? {
        guard let raw = UserDefaults.standard.string(forKey: "outlookCalendarICSURL"), !raw.isEmpty else { return nil }
        return URL(string: raw)
    }

    init() {
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    deinit { timer?.invalidate() }

    // MARK: - Mock

    static func mock(scenario: MockScenario) -> OutlookEventMonitor {
        let monitor = OutlookEventMonitor(__noFetch: ())
        switch scenario {
        case .now:
            monitor.events = [
                CalendarEvent(title: "Frukostupdate MedHelp Care", timeUntil: "Now", secondsUntil: 0),
                CalendarEvent(title: "1:1 with Anna", timeUntil: "in 45m", secondsUntil: 2700),
                CalendarEvent(title: "Sprint Planning", timeUntil: "in 2h 30m", secondsUntil: 9000),
                CalendarEvent(title: "Quarterly Review", timeUntil: "in 4h", secondsUntil: 14400)
            ]
        case .critical:
            monitor.events = [
                CalendarEvent(title: "Frukostupdate MedHelp Care", timeUntil: "in 8m", secondsUntil: 480),
                CalendarEvent(title: "1:1 with Anna", timeUntil: "in 45m", secondsUntil: 2700),
                CalendarEvent(title: "Sprint Planning", timeUntil: "in 2h 30m", secondsUntil: 9000),
                CalendarEvent(title: "Quarterly Review", timeUntil: "in 4h", secondsUntil: 14400)
            ]
        case .warning:
            monitor.events = [
                CalendarEvent(title: "Frukostupdate MedHelp Care", timeUntil: "in 22m", secondsUntil: 1320),
                CalendarEvent(title: "1:1 with Anna", timeUntil: "in 1h 10m", secondsUntil: 4200),
                CalendarEvent(title: "Sprint Planning", timeUntil: "in 3h", secondsUntil: 10800),
                CalendarEvent(title: "Quarterly Review", timeUntil: "in 4h 30m", secondsUntil: 16200)
            ]
        case .normal:
            monitor.events = [
                CalendarEvent(title: "Frukostupdate MedHelp Care", timeUntil: "in 1h 15m", secondsUntil: 4500),
                CalendarEvent(title: "1:1 with Anna", timeUntil: "in 3h", secondsUntil: 10800),
                CalendarEvent(title: "Sprint Planning", timeUntil: "in 5h", secondsUntil: 18000),
                CalendarEvent(title: "Quarterly Review", timeUntil: "in 7h", secondsUntil: 25200)
            ]
        }
        return monitor
    }

    enum MockScenario {
        case now, critical, warning, normal
    }

    private init(__noFetch: Void) {}

    // MARK: - Fetch

    private func fetch() {
        guard let url = Self.icsURL else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let raw = String(data: data, encoding: .utf8) else { return }
            let parsed = Self.parse(ics: raw)
            DispatchQueue.main.async { self.events = parsed }
        }.resume()
    }

    // MARK: - ICS Parsing

    private static func parse(ics: String) -> [CalendarEvent] {
        let now = Date()
        let cutoff = now.addingTimeInterval(8 * 3600)

        // Unfold continuation lines (RFC 5545: lines folded with CRLF + whitespace)
        let unfolded = ics
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\n\t", with: "")

        let lines = unfolded.components(separatedBy: .newlines)

        var results: [CalendarEvent] = []
        var inEvent = false
        var summary = ""
        var dtstart: Date? = nil
        var dtend: Date? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                summary = ""
                dtstart = nil
                dtend = nil
            } else if trimmed == "END:VEVENT" {
                inEvent = false
                guard let start = dtstart, let end = dtend, !summary.isEmpty else { continue }
                let secs = start.timeIntervalSince(now)
                if start <= now && end > now {
                    results.append(CalendarEvent(title: summary, timeUntil: "Now", secondsUntil: 0))
                } else if start > now && start <= cutoff {
                    results.append(CalendarEvent(title: summary, timeUntil: formatSeconds(secs), secondsUntil: secs))
                }
            } else if inEvent {
                if trimmed.hasPrefix("SUMMARY") {
                    summary = extractValue(from: trimmed)
                } else if trimmed.hasPrefix("DTSTART") {
                    dtstart = parseDate(trimmed)
                } else if trimmed.hasPrefix("DTEND") {
                    dtend = parseDate(trimmed)
                }
            }
        }

        results.sort { $0.secondsUntil < $1.secondsUntil }

        let current = results.filter { $0.secondsUntil == 0 }
        let upcoming = results.filter { $0.secondsUntil > 0 }
        let upcomingLimit = current.isEmpty ? 3 : 2
        return current + Array(upcoming.prefix(upcomingLimit))
    }

    private static func extractValue(from line: String) -> String {
        guard let colonIdx = line.firstIndex(of: ":") else { return "" }
        return String(line[line.index(after: colonIdx)...])
    }

    private static func parseDate(_ line: String) -> Date? {
        // Skip all-day events (VALUE=DATE has no time component)
        guard !line.contains("VALUE=DATE") else { return nil }
        guard let colonIdx = line.firstIndex(of: ":") else { return nil }

        let params = String(line[line.startIndex..<colonIdx])
        let value = String(line[line.index(after: colonIdx)...])

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if value.hasSuffix("Z") {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.timeZone = TimeZone(identifier: "UTC")
        } else if let tzidRange = params.range(of: "TZID=") {
            let windowsTzid = String(params[tzidRange.upperBound...])
            let tzid = windowsToIANA[windowsTzid] ?? windowsTzid
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            formatter.timeZone = TimeZone(identifier: tzid) ?? .current
        } else {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            formatter.timeZone = .current
        }

        return formatter.date(from: value)
    }

    // Common Windows timezone ID → IANA mapping
    private static let windowsToIANA: [String: String] = [
        "W. Europe Standard Time":   "Europe/Stockholm",
        "Central Europe Standard Time": "Europe/Budapest",
        "Romance Standard Time":     "Europe/Paris",
        "Eastern Standard Time":     "America/New_York",
        "Central Standard Time":     "America/Chicago",
        "Mountain Standard Time":    "America/Denver",
        "Pacific Standard Time":     "America/Los_Angeles",
        "GMT Standard Time":         "Europe/London",
        "UTC":                       "UTC",
    ]

    private static func formatSeconds(_ secs: Double) -> String {
        if secs < 60   { return "Now" }
        if secs < 3600 { return "in \(Int(secs / 60))m" }
        let h = Int(secs / 3600)
        let m = Int(secs.truncatingRemainder(dividingBy: 3600) / 60)
        return m > 0 ? "in \(h)h \(m)m" : "in \(h)h"
    }
}
