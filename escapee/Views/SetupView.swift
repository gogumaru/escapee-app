//
//  SetupView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//

import SwiftUI

struct SetupView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var settings: SettingsStore
    @ObservedObject var vnVM: VNGameViewModel
    @StateObject private var personaVM = PersonaViewModel()
    @State private var showPersonaPicker = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Gear icon top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .padding(16)
                    }
                }
                Spacer()
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(spacing: 14) {
                    Text("🚪")
                        .font(.system(size: 64))

                    Text("escapee")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))

                    Text("The agents need you.\nWill you make it out?")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                // Buttons
                VStack(spacing: 10) {
                    // Start
                    Button {
                        vnVM.reset()
                        if let url = personaVM.buildWebSocketURL(
                            host: settings.host,
                            port: settings.port,
                            narrate: settings.narrate,
                            rounds: settings.rounds
                        ) {
                            vm.startGame(url: url)
                        } else {
                            vm.startGame(host: settings.host, port: settings.port, narrate: settings.narrate)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start game")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Debug: jump to deduction
                    #if DEBUG
                    Button {
                        vnVM.reset()
                        if let session = DebugSession.load() {
                            session.apply(to: vm)
                            vnVM.bind(to: vm)
                        } else {
                            vm.phase = .deduction
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "ant")
                                .font(.system(size: 14))
                            Text(DebugSession.load() != nil ? "Debug: Last Deduction" : "Debug: Deduction")
                                .font(.system(size: 14))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.orange.opacity(0.12))
                        .foregroundStyle(Color.orange.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    #endif

                    // Choose agents
                    Button {
                        Task {
                            await personaVM.fetchPersonas(host: settings.host, port: settings.port)
                            showPersonaPicker = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2")
                                .font(.system(size: 14))
                            Text(personaVM.selectionSummary.isEmpty ? "Choose agents" : personaVM.selectionSummary)
                                .font(.system(size: 14))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.07))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        // Persona picker sheet
        .sheet(isPresented: $showPersonaPicker) {
            PersonaPickerView(
                personaVM: personaVM,
                settings: settings,
                onStart: { url in
                    showPersonaPicker = false
                    vm.startGame(url: url)
                },
                onDismiss: { showPersonaPicker = false }
            )
        }
        // Settings sheet
        .sheet(isPresented: $showSettings) {
            SettingsSheetView(settings: settings)
        }
    }
}

// MARK: - Settings Sheet

struct SettingsSheetView: View {
    @ObservedObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend") {
                    HStack {
                        Text("Host")
                        Spacer()
                        TextField("localhost", text: $settings.host)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                    HStack {
                        Text("Port")
                        Spacer()
                        TextField("8000", value: $settings.port, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Game") {
                    HStack {
                        Text("Max rounds")
                        Spacer()
                        TextField("75", value: $settings.rounds, format: .number)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    Toggle("Narration", isOn: $settings.narrate)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
