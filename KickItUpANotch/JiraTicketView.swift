//
//  JiraTicketView.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import SwiftUI
import Observation

struct JiraTicket: Identifiable {
    let id: String
    let summary: String
    let status: String
    let priority: Priority

    enum Priority { case high, medium, low }

    var priorityColor: Color {
        switch priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .green
        }
    }
}

// MARK: - Mock data (replace with real API later)

@Observable
final class JiraMonitor {
    var tickets: [JiraTicket] = [
        JiraTicket(id: "PROJ-421", summary: "Fix login timeout on Safari", status: "In Progress", priority: .high),
        JiraTicket(id: "PROJ-398", summary: "Update onboarding flow copy", status: "To Do", priority: .medium),
        JiraTicket(id: "PROJ-387", summary: "Add pagination to activity feed", status: "In Review", priority: .medium),
        JiraTicket(id: "PROJ-374", summary: "Investigate memory leak in dashboard", status: "To Do", priority: .high),
        JiraTicket(id: "PROJ-361", summary: "Write unit tests for auth module", status: "To Do", priority: .low),
    ]
}

// MARK: - Rolling ticker view

struct JiraTickerView: View {
    var monitor: JiraMonitor
    @State private var currentIndex = 0
    @State private var opacity: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: "ticket")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("JIRA")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
            }

            if !monitor.tickets.isEmpty {
                let ticket = monitor.tickets[currentIndex]

                HStack(spacing: 5) {
                    Circle()
                        .fill(ticket.priorityColor)
                        .frame(width: 5, height: 5)

                    Text(ticket.id)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))

                    Text(ticket.summary)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Text(ticket.status)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.leading, 10)
            }
        }
        .opacity(opacity)
        .onAppear { startRolling() }
    }

    private func startRolling() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            guard monitor.tickets.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.3)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                currentIndex = (currentIndex + 1) % monitor.tickets.count
                withAnimation(.easeInOut(duration: 0.3)) { opacity = 1 }
            }
        }
    }
}
