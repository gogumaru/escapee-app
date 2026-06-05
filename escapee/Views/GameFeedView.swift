//
//  GameFeedView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import SwiftUI

struct GameFeedView: View {
    @ObservedObject var vm: GameViewModel
    @State private var showStatePanel = false

    var body: some View {
        VStack(spacing: 0) {
            GameNavBar(vm: vm, onShowState: { showStatePanel.toggle() })

            Divider()

            if vm.filteredEvents.isEmpty {
                WaitingView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(vm.filteredEvents) { event in
                                EventRowView(event: event).id(event.id)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                    }
                    .onChange(of: vm.filteredEvents.count) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            Divider()

            // Bottom bar — turn count + play again
            HStack {
                Spacer()

                if !vm.isConnected && vm.hasEvents {
                    Button(action: { vm.replayGame() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("Play again")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.red.opacity(0.8))
                    }
                    Spacer()
                }

                Text("\(vm.turnCount) turns")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(.bar)
        }
        .sheet(isPresented: $showStatePanel) {
            StatePanelView(state: vm.currentState)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Navbar

struct GameNavBar: View {
    @ObservedObject var vm: GameViewModel
    let onShowState: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(vm.navigationTitle)
                    .font(.system(size: 16, weight: .medium))

                HStack(spacing: 5) {
                    Circle()
                        .fill(vm.isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(vm.isConnected
                         ? "\(agentCount) agents · live"
                         : "disconnected")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 16) {
                Button(action: onShowState) {
                    Image(systemName: "map")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                Button(action: { vm.stopGame() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var agentCount: Int {
        vm.currentState?.players.count ?? 2
    }
}

// MARK: - Waiting View

struct WaitingView: View {
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
            Text("Waiting for agents...")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
