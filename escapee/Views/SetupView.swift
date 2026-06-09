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
    @StateObject private var personaVM = PersonaViewModel()
    @State private var showPersonaPicker = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Gear icon top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.secondary)
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
                        .foregroundStyle(.primary)

                    Text("Two AI agents. One locked room.\nWill they make it out?")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                Spacer()

                // Buttons
                VStack(spacing: 10) {
                    // Start
                    Button {
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
                        .background(Color.primary)
                        .foregroundStyle(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

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
                        .background(Color.secondary.opacity(0.1))
                        .foregroundStyle(Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
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
