//
//  EventRowView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import SwiftUI

// MARK: - Agent Colors
// Deterministik per player ID — konsisten sepanjang game

struct AgentColor {
    let bubble: Color
    let text: Color
    let name: Color
    let avatar: Color

    static func from(_ playerId: String?) -> AgentColor {
        guard let id = playerId else { return .system }
        // Pakai first char + length supaya player_1 vs player_2 selalu beda warna
        let seed = (id.unicodeScalars.first?.value ?? 0) + UInt32(id.count)
        let palette: [AgentColor] = [.alex, .riley, .charlie, .dana]
        let index = Int(seed) % palette.count
        return palette[index]
    }

    // Biru — player pertama
    static let alex = AgentColor(
        bubble: Color(red: 0.05, green: 0.13, blue: 0.25),
        text:   Color(red: 0.86, green: 0.93, blue: 1.0),
        name:   Color(red: 0.37, green: 0.51, blue: 0.98),
        avatar: Color(red: 0.23, green: 0.38, blue: 0.62)
    )
    // Ungu — player kedua
    static let riley = AgentColor(
        bubble: Color(red: 0.10, green: 0.05, blue: 0.21),
        text:   Color(red: 0.93, green: 0.91, blue: 1.0),
        name:   Color(red: 0.66, green: 0.33, blue: 0.97),
        avatar: Color(red: 0.37, green: 0.20, blue: 0.55)
    )
    // Teal — player ketiga
    static let charlie = AgentColor(
        bubble: Color(red: 0.04, green: 0.18, blue: 0.18),
        text:   Color(red: 0.86, green: 0.97, blue: 0.97),
        name:   Color(red: 0.20, green: 0.75, blue: 0.70),
        avatar: Color(red: 0.10, green: 0.40, blue: 0.38)
    )
    // Amber — player keempat
    static let dana = AgentColor(
        bubble: Color(red: 0.20, green: 0.14, blue: 0.03),
        text:   Color(red: 1.0, green: 0.95, blue: 0.86),
        name:   Color(red: 0.90, green: 0.65, blue: 0.20),
        avatar: Color(red: 0.50, green: 0.35, blue: 0.05)
    )
    // System — abu
    static let system = AgentColor(
        bubble: Color.white.opacity(0.05),
        text:   Color.white.opacity(0.5),
        name:   Color.white.opacity(0.3),
        avatar: Color.white.opacity(0.1)
    )
}

// MARK: - EventRowView

struct EventRowView: View {
    let event: GameEvent

    // Semua bubble di kiri
    private var isRight: Bool { false }

    private var agentColor: AgentColor {
        .from(event.player)
    }

    var body: some View {
        Group {
            switch event.kind {
            case .narration:
                NarratorRow(text: event.displayText)

            case .speech:
                AgentBubbleRow(event: event, isRight: isRight, color: agentColor)

            case .observation:
                ObservationRow(text: event.displayText, player: event.player)

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

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Text("👁️")
                .font(.system(size: 12))
                .padding(.top, 1)
            Group {
                if let player {
                    Text(player + " ")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AgentColor.from(player).name)
                    + Text(text)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                } else {
                    Text(text)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }
            .lineSpacing(3)
        }
        .padding(.horizontal, 6)
    }
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

            Group {
                if isProgress {
                    Text("progress  ")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.green)
                    + Text(text
                        .replacingOccurrences(of: "✓ Progress! The team just achieved: ", with: "")
                        .replacingOccurrences(of: "✓ ", with: ""))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                } else {
                    Text(text)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }
            .lineSpacing(3)
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
