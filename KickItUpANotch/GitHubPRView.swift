//
//  GitHubPRView.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import SwiftUI
import Observation

struct GitHubPR: Identifiable {
    let id: Int
    let title: String
    let repo: String
    let status: Status

    enum Status {
        case reviewRequired, changesRequested, approved

        var color: Color {
            switch self {
            case .reviewRequired:  return .yellow
            case .changesRequested: return .red
            case .approved:        return .green
            }
        }

        var label: String {
            switch self {
            case .reviewRequired:   return "Review"
            case .changesRequested: return "Changes"
            case .approved:         return "Approved"
            }
        }
    }
}

// MARK: - Mock data (replace with real API later)

@Observable
final class GitHubMonitor {
    var prs: [GitHubPR] = [
        GitHubPR(id: 312, title: "Add dark mode support", repo: "frontend", status: .reviewRequired),
        GitHubPR(id: 298, title: "Fix race condition in auth", repo: "api", status: .changesRequested),
        GitHubPR(id: 287, title: "Migrate to Swift 6", repo: "ios-app", status: .approved),
        GitHubPR(id: 301, title: "Update CI pipeline", repo: "infra", status: .reviewRequired),
        GitHubPR(id: 276, title: "Refactor user service", repo: "api", status: .changesRequested),
    ]
}

// MARK: - Rolling view

struct GitHubPRTickerView: View {
    var monitor: GitHubMonitor
    @State private var currentIndex = 0
    @State private var opacity: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.pull")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text("PULL REQUESTS")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Text("\(monitor.prs.count) open")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }

            if !monitor.prs.isEmpty {
                let pr = monitor.prs[currentIndex]

                HStack(spacing: 5) {
                    Circle()
                        .fill(pr.status.color)
                        .frame(width: 5, height: 5)

                    Text("#\(pr.id)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))

                    Text(pr.title)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                HStack(spacing: 4) {
                    Image(systemName: "folder")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.3))
                    Text(pr.repo)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text(pr.status.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(pr.status.color.opacity(0.8))
                }
                .padding(.leading, 10)
            }
        }
        .opacity(opacity)
        .onAppear { startRolling() }
    }

    private func startRolling() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            guard monitor.prs.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.3)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                currentIndex = (currentIndex + 1) % monitor.prs.count
                withAnimation(.easeInOut(duration: 0.3)) { opacity = 1 }
            }
        }
    }
}
