//
//  VNGameView.swift
//  escapee
//
//  Created by Benedikta Anin on 09/06/26.
//


import SwiftUI

struct VNGameView: View {
    @ObservedObject var gameVM: GameViewModel
    @StateObject private var vnVM: VNGameViewModel
    @State private var showStatePanel = false

    init(gameVM: GameViewModel) {
        self.gameVM = gameVM
        self._vnVM = StateObject(wrappedValue: VNGameViewModel(gameViewModel: gameVM))
    }

    private var showCharacter: Bool {
        vnVM.currentEventType != .narration && vnVM.currentEventType != .result
    }

    var body: some View {
        ZStack {
            // Background
            RoomBackground(room: vnVM.currentRoom, vnVM: vnVM)
                .ignoresSafeArea()

            // Gradient bawah
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.97)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 420)
                .ignoresSafeArea()
            }
            .allowsHitTesting(false)

            // Gradient atas — cover navbar area
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.7), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .ignoresSafeArea()
                Spacer()
            }
            .allowsHitTesting(false)

            // Karakter — sembunyikan saat narasi & result
            if showCharacter,
               let speakerId = vnVM.activeCharacters.first,
               let player = gameVM.currentState?.players.first(where: { $0.id == speakerId }) {
                VStack {
                    Spacer()
                    VNCharacterView(
                        playerId: speakerId,
                        playerName: player.name,
                        isSpeaking: true,
                        agentColor: AgentColor.from(speakerId, order: gameVM.playerOrder)
                    )
                }
                .ignoresSafeArea()
            }

            // Main layout
            VStack(spacing: 0) {
                VNNavBar(gameVM: gameVM, onShowState: { showStatePanel.toggle() })
                    .padding(.top, 52)

                if vnVM.currentEventType == .result {
                    // Result — tengah layar
                    Spacer()
                    VNDialogView(vnVM: vnVM, gameVM: gameVM)
                        .padding(.horizontal, 14)
                    Spacer()
                    VNControlsView(vnVM: vnVM)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                } else if vnVM.currentEventType == .narration {
                    // Narasi — di atas
                    VNDialogView(vnVM: vnVM, gameVM: gameVM)
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                    Spacer()
                    VNControlsView(vnVM: vnVM)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                } else if vnVM.currentEventType == .system {
                    // System — di atas
                    VNDialogView(vnVM: vnVM, gameVM: gameVM)
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                    Spacer()
                    VNControlsView(vnVM: vnVM)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                } else {
                    // Speech & observation — di bawah
                    Spacer()
                    VNDialogView(vnVM: vnVM, gameVM: gameVM)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                    VNControlsView(vnVM: vnVM)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
            }
        }
        .sheet(isPresented: $showStatePanel) {
            StatePanelView(state: gameVM.currentState)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Room Background

struct RoomBackground: View {
    let room: String
    let vnVM: VNGameViewModel

    var body: some View {
        let colors = vnVM.roomColor(for: room)
        LinearGradient(
            colors: [
                Color(hex: colors.primary) ?? Color(red: 0.1, green: 0.06, blue: 0.02),
                Color(hex: colors.secondary) ?? Color(red: 0.06, green: 0.04, blue: 0.01)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Navbar

struct VNNavBar: View {
    @ObservedObject var gameVM: GameViewModel
    let onShowState: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Escapee")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.9))
                HStack(spacing: 5) {
                    Circle()
                        .fill(gameVM.isConnected ? Color.green : Color.red)
                        .frame(width: 5, height: 5)
                    Text(gameVM.isConnected ? "\(agentCount) agents · live" : "disconnected")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onShowState) {
                    Image(systemName: "map")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
                Button(action: { gameVM.stopGame() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var agentCount: Int {
        gameVM.currentState?.players.count ?? 0
    }
}

// MARK: - Controls

struct VNControlsView: View {
    @ObservedObject var vnVM: VNGameViewModel

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Text("AUTO")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(vnVM.isAutoPlay ? Color.white.opacity(0.9) : Color.white.opacity(0.4))
                Toggle("", isOn: Binding(
                    get: { vnVM.isAutoPlay },
                    set: { _ in vnVM.toggleAutoPlay() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .indigo))
                .labelsHidden()
            }

            Spacer()

            Button(action: { vnVM.prevEvent() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(vnVM.hasPrev ? Color.white.opacity(0.5) : Color.white.opacity(0.15))
                    .frame(width: 44, height: 44)
            }
            .disabled(!vnVM.hasPrev)

            Button(action: { vnVM.nextEvent() }) {
                ZStack {
                    Circle()
                        .fill(vnVM.hasNext && !vnVM.isAutoPlay
                              ? Color.white.opacity(0.15)
                              : Color.white.opacity(0.05))
                        .frame(width: 48, height: 48)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(vnVM.hasNext && !vnVM.isAutoPlay
                                         ? Color.white.opacity(0.9)
                                         : Color.white.opacity(0.2))
                }
            }
            .disabled(!vnVM.hasNext || vnVM.isAutoPlay)
        }
    }
}

// MARK: - Color hex helper

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let val = UInt64(h, radix: 16) else { return nil }
        self.init(
            red:   Double((val >> 16) & 0xFF) / 255,
            green: Double((val >> 8)  & 0xFF) / 255,
            blue:  Double(val         & 0xFF) / 255
        )
    }
}
