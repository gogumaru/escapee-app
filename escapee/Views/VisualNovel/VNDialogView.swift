//
//  VNDialogView.swift
//  escapee
//
//  Created by Benedikta Anin on 09/06/26.
//


import SwiftUI

struct VNDialogView: View {
    let vnVM: VNGameViewModel
    @ObservedObject var gameVM: GameViewModel

    var body: some View {
        switch vnVM.currentEventType {
        case .narration:
            NarratorDialogView(text: vnVM.displayText)
        case .observation:
            ObservationDialogView(
                text: vnVM.displayText,
                playerName: vnVM.currentEvent?.player ?? "",
                color: vnVM.currentEvent.map {
                    AgentColor.from($0.playerId, order: gameVM.playerOrder)
                } ?? .system
            )
        case .system:
            SystemDialogView(text: vnVM.displayText)
        case .result:
            ResultDialogView(text: vnVM.displayText)
        default:
            AgentDialogView(
                event: vnVM.currentEvent,
                eventType: vnVM.currentEventType,
                text: vnVM.displayText,
                color: vnVM.currentEvent.map {
                    AgentColor.from($0.playerId, order: gameVM.playerOrder)
                } ?? .system
            )
        }
    }
}

// MARK: - Narrator

struct NarratorDialogView: View {
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Text("narrator")
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color.white.opacity(0.25))

            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .italic()
                .foregroundStyle(Color.white.opacity(0.65))
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.black.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Agent Dialog

struct AgentDialogView: View {
    let event: GameEvent?
    let eventType: VNEventType
    let text: String
    let color: AgentColor

    private var badgeLabel: String? {
        switch eventType {
        case .idea:       return "idea"
        case .reflection: return "reflection"
        default:          return nil
        }
    }

    private var borderColor: Color {
        switch eventType {
        case .idea:       return Color.purple.opacity(0.4)
        case .reflection: return Color.yellow.opacity(0.3)
        default:          return Color.white.opacity(0.1)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(event?.player ?? "")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color.name)

                if let badge = badgeLabel {
                    Text(badge)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            eventType == .idea
                                ? Color.purple.opacity(0.2)
                                : Color.yellow.opacity(0.15)
                        )
                        .foregroundStyle(
                            eventType == .idea
                                ? Color.purple.opacity(0.9)
                                : Color.yellow.opacity(0.9)
                        )
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().background(Color.white.opacity(0.06))

            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(
                    eventType == .reflection
                        ? Color.white.opacity(0.6)
                        : Color.white.opacity(0.9)
                )
                .italic(eventType == .reflection || eventType == .idea)
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color.black.opacity(0.75))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Observation

struct ObservationDialogView: View {
    let text: String
    let playerName: String
    let color: AgentColor

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("👁️").font(.system(size: 17, weight: .semibold))
            VStack(alignment: .leading, spacing: 3) {
                if !playerName.isEmpty {
                    Text(playerName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color.name)
                }
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - System

struct SystemDialogView: View {
    let text: String
    private var isProgress: Bool {
        text.contains("Progress") || text.contains("✓")
    }

    private var progressBody: String {
        text
            .replacingOccurrences(of: "✓ Progress! The team just achieved: ", with: "The team ")
            .replacingOccurrences(of: "✓ Progress! ", with: "The team ")
            .replacingOccurrences(of: "✓ ", with: "The team ")
    }

    var body: some View {
        if isProgress {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("🔔").font(.system(size: 18, weight: .semibold))
                    Text("Progress!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.green.opacity(0.9))
                }
                Text(progressBody)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.green.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.2), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            HStack(alignment: .top, spacing: 10) {
                Text("⚠️").font(.system(size: 16, weight: .semibold))
                Text(text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .lineSpacing(4)
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Result

struct ResultDialogView: View {
    let text: String
    private var isWon: Bool { text.contains("🎉") }

    var body: some View {
        VStack(spacing: 16) {
            Text("GAME OVER")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .tracking(2)

            Text(isWon ? "You won." : "You lost.")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isWon ? Color.green.opacity(0.9) : Color.red.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
}
