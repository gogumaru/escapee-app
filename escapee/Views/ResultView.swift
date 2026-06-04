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
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 40)

                // Result emoji + title
                if let result = vm.gameResult {
                    VStack(spacing: 12) {
                        Text(result.won ? "🎉" : "💀")
                            .font(.system(size: 80))

                        Text(result.won ? "Escaped!" : "Game Over")
                            .font(.largeTitle.bold())

                        Text(result.reason)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Stats
                    HStack(spacing: 24) {
                        StatCard(
                            icon: "repeat",
                            value: "\(result.turns)",
                            label: "Turns"
                        )
                        StatCard(
                            icon: "bubble.left.and.bubble.right",
                            value: "\(vm.turnCount)",
                            label: "Events"
                        )
                    }
                    .padding(.horizontal)
                }

                // Replay button
                Button {
                    vm.stopGame()
                } label: {
                    Label("Play Again", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}