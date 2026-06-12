//
//  ResultView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import SwiftUI

struct ResultView: View {

    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    if let result = vm.gameResult {
                        VStack(spacing: 12) {
                            Text(result.won ? "Escaped!" : "Game Over")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.9))

                            Text(result.won ? "You found the murderer." : reasonLabel(result.reason))
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        if let narration = vm.lastNarration {
                            Text(narration)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.white.opacity(0.55))
                                .multilineTextAlignment(.center)
                                .italic()
                                .lineSpacing(4)
                                .padding(.horizontal, 32)
                        }

                        HStack(spacing: 16) {
                            DarkStatCard(icon: "repeat", value: "\(result.turns)", label: "Turns")
                            DarkStatCard(icon: "bubble.left.and.bubble.right", value: "\(vm.turnCount)", label: "Events")
                        }
                        .padding(.horizontal, 24)
                    }

                    Button {
                        vm.stopGame()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14))
                            Text("Play Again")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
    }

    private func reasonLabel(_ reason: String) -> String {
        switch reason {
        case "wrong_deduction": return "Wrong accusation — the murderer walked free."
        case "turn_limit":      return "Time ran out."
        case "stalled":         return "The team got stuck."
        default:                return reason
        }
    }
}

struct DarkStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.white.opacity(0.4))
            Text(value)
                .font(.title.bold())
                .foregroundStyle(Color.white.opacity(0.9))
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
