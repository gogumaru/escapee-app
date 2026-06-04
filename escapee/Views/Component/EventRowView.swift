//
//  EventRowView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import SwiftUI

struct EventRowView: View {

    let event: GameEvent

    var body: some View {
        HStack(alignment: .top, spacing: 10) {

            // Kind indicator
            Text(icon(for: event.kind))
                .font(.system(size: 18))
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {

                // Header: player name + badge
                HStack(spacing: 6) {
                    if let player = event.player {
                        Text(player)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(playerColor(for: event.player))
                    }

                    BadgeView(
                        label: badgeLabel(for: event.kind),
                        color: badgeColor(for: event.kind)
                    )

                    Spacer()
                }

                // Event text
                Text(event.displayText)
                    .font(font(for: event.kind))
                    .foregroundStyle(textColor(for: event.kind))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(background(for: event.kind))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func icon(for kind: EventKind) -> String {
        switch kind {
        case .narration:   return "📖"
        case .speech:      return "💬"
        case .observation: return "👁️"
        case .system:      return "⚙️"
        case .decision:    return "🧠"
        case .result:      return "🏁"
        case .setup:       return "🎮"
        default:           return "•"
        }
    }

    private func badgeLabel(for kind: EventKind) -> String {
        switch kind {
        case .narration:   return "Story"
        case .speech:      return "Agent"
        case .observation: return "World"
        case .system:      return "System"
        case .decision:    return "Think"
        case .result:      return "Result"
        case .setup:       return "Setup"
        default:           return "—"
        }
    }

    private func badgeColor(for kind: EventKind) -> Color {
        switch kind {
        case .narration:   return .orange
        case .speech:      return .blue
        case .observation: return .green
        case .system:      return .gray
        case .decision:    return .purple
        case .result:      return .red
        default:           return .gray
        }
    }

    private func font(for kind: EventKind) -> Font {
        switch kind {
        case .narration: return .body.italic()
        case .decision:  return .caption
        default:         return .body
        }
    }

    private func textColor(for kind: EventKind) -> Color {
        switch kind {
        case .narration: return .primary
        case .system:    return .secondary
        case .decision:  return .secondary
        default:         return .primary
        }
    }

    private func background(for kind: EventKind) -> Color {
        switch kind {
        case .narration:   return .orange.opacity(0.06)
        case .speech:      return .blue.opacity(0.06)
        case .observation: return .green.opacity(0.06)
        case .system:      return .clear
        case .decision:    return .purple.opacity(0.04)
        case .result:      return .red.opacity(0.08)
        default:           return .clear
        }
    }

    private func playerColor(for player: String?) -> Color {
        guard let player else { return .secondary }
        // Deterministik: hash nama player ke warna
        let colors: [Color] = [.blue, .purple, .teal, .orange, .pink, .indigo]
        let index = abs(player.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
