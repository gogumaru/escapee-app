//
//  EventRowView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//

import SwiftUI

// MARK: - EventRowView

struct EventRowView: View {
    let event: GameEvent

    // Semua bubble di kiri
    private var isRight: Bool { false }

    private var agentColor: AgentColor {
        event.agentColor
    }

    var body: some View {
        Group {
            switch event.kind {
            case .narration:
                NarratorRow(text: event.displayText)

            case .speech:
                AgentBubbleRow(event: event, isRight: isRight, color: agentColor)

            case .observation:
                ObservationRow(text: event.displayText, player: event.player, event: event)

            case .system:
                SystemRow(
                    text: event.displayText,
                    isProgress: event.displayText.contains("Progress") || event.displayText.contains("✓")
                )

            case .result:
                ResultRow(text: event.displayText)

            default:
                // decision, unknown, dll — tampilkan sebagai system
                if !event.displayText.isEmpty {
                    SystemRow(text: event.displayText, isProgress: false)
                }
            }
        }
    }
}

// MARK: - Narrator

struct NarratorRow: View {
    let text: String

    var body: some View {
        VStack(spacing: 5) {
            Text("narrator")
                .font(.system(size: 10, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(.tertiary)

            Text(text)
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Agent Bubble

struct AgentBubbleRow: View {
    let event: GameEvent
    let isRight: Bool
    let color: AgentColor

    private var initials: String {
        guard let name = event.player else { return "?" }
        return name
            .split(separator: "_")
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }

    var body: some View {
        VStack(alignment: isRight ? .trailing : .leading, spacing: 3) {
            // Header: avatar + name + turn — selalu kiri
            HStack(spacing: 5) {
                avatarView
                nameView
                Spacer()
            }
            .padding(.horizontal, 6)

            // Bubble — selalu kiri, pojok kiri atas tajam
            HStack {
                Text(event.displayText)
                    .font(.system(size: 14))
                    .foregroundStyle(color.text)
                    .lineSpacing(3)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(color.bubble)
                    .clipShape(RoundedCorners(tl: 4, tr: 16, bl: 16, br: 16))
                Spacer(minLength: 60)
            }
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle().fill(color.avatar).frame(width: 20, height: 20)
            Text(initials)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(color.name)
        }
    }

    private var nameView: some View {
        HStack(spacing: 4) {
            Text(event.player ?? "")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color.name)
            if let turn = event.turn {
                Text("· turn \(turn)")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.18))
            }
        }
    }
}

// MARK: - Observation

struct ObservationRow: View {
    let text: String
    let player: String?
    let event: GameEvent

    private var cleanText: String {
        guard text.hasPrefix("You ") else { return text }
        return String(text.dropFirst(4))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Text("👁️")
                .font(.system(size: 12))
                .padding(.top, 1)
            if let player {
                Text(attributedObservation(player: player, text: cleanText, nameColor: event.agentColor.name))
                    .font(.system(size: 12))
                    .lineSpacing(3)
            } else {
                Text(cleanText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 6)
    }
}

private func attributedProgress(text: String) -> AttributedString {
    var result = AttributedString("progress  \(text)")
    if let range = result.range(of: "progress") {
        result[range].foregroundColor = UIColor.systemGreen
        result[range].font = .systemFont(ofSize: 12, weight: .medium)
    }
    if let range = result.range(of: "  \(text)") {
        result[range].foregroundColor = UIColor.secondaryLabel
    }
    return result
}

private func attributedObservation(player: String, text: String, nameColor: Color) -> AttributedString {
    var result = AttributedString("\(player) \(text)")
    // Default semua ke secondary
    result.foregroundColor = UIColor.secondaryLabel
    // Override nama agent dengan warna accent
    if let range = result.range(of: player) {
        result[range].foregroundColor = UIColor(nameColor)
        result[range].font = .systemFont(ofSize: 12, weight: .medium)
    }
    return result
}

// MARK: - System

struct SystemRow: View {
    let text: String
    let isProgress: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Group {
                if isProgress {
                    Text("🔔").font(.system(size: 12))
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.top, 1)

            if isProgress {
                let clean = text
                    .replacingOccurrences(of: "✓ Progress! The team just achieved: ", with: "")
                    .replacingOccurrences(of: "✓ ", with: "")
                Text(attributedProgress(text: clean))
                    .font(.system(size: 12))
                    .lineSpacing(3)
            } else {
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }
}

// MARK: - Result

struct ResultRow: View {
    let text: String

    private var isWon: Bool { text.contains("🎉") }

    var body: some View {
        HStack(spacing: 12) {
            Text(isWon ? "🎉" : "💀")
                .font(.system(size: 26))

            VStack(alignment: .leading, spacing: 3) {
                Text(isWon ? "Escaped!" : "Game over")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isWon ? Color.green.opacity(0.9) : Color(red: 0.97, green: 0.45, blue: 0.45))
                Text(text.replacingOccurrences(of: "🎉 Game Over — ", with: "")
                        .replacingOccurrences(of: "💀 Game Over — ", with: ""))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isWon
                ? Color.green.opacity(0.07)
                : Color(red: 0.37, green: 0.06, blue: 0.06)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isWon ? Color.green.opacity(0.15) : Color.red.opacity(0.2),
                    lineWidth: 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.vertical, 4)
    }
}

// MARK: - Custom Corner Radius Shape

struct RoundedCorners: Shape {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var bl: CGFloat = 0
    var br: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.size.width
        let h = rect.size.height
        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}
