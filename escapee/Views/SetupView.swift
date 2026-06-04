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

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // Hero
                VStack(spacing: 8) {
                    Text("🔐")
                        .font(.system(size: 64))
                    Text("Escapee")
                        .font(.largeTitle.bold())
                    Text("Multi-LLM Agent Escape Room")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                // Connection settings
                VStack(alignment: .leading, spacing: 16) {
                    Label("Backend Connection", systemImage: "network")
                        .font(.headline)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Host")
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)
                            TextField("localhost", text: $settings.host)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                        }

                        HStack {
                            Text("Port")
                                .foregroundStyle(.secondary)
                                .frame(width: 60, alignment: .leading)
                            TextField("8000", value: $settings.port, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }

                        Toggle("Narration (GM storyteller)", isOn: $settings.narrate)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Start button
                Button {
                    vm.startGame(
                        host: settings.host,
                        port: settings.port,
                        narrate: settings.narrate
                    )
                } label: {
                    Label("Start Game", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Tip
                Text("Pastikan backend Escapee sudah jalan di komputer kamu.\nSimulator: gunakan localhost. Device fisik: gunakan IP Mac di WiFi yang sama.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
        }
    }
}