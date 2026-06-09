//
//  PersonaPickerView.swift
//  escapee
//
//  Created by Benedikta Anin on 09/06/26.
//


import SwiftUI

struct PersonaPickerView: View {
    @ObservedObject var personaVM: PersonaViewModel
    @ObservedObject var settings: SettingsStore
    let onStart: (URL) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // Navbar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Choose agents")
                        .font(.system(size: 16, weight: .medium))
                    Text("Select 1–4 characters to play")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            // Content
            Group {
                switch personaVM.loadState {
                case .loading:
                    VStack(spacing: 14) {
                        Spacer()
                        ProgressView()
                        Text("Loading agents...")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                case .error(let msg):
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Could not load agents")
                            .font(.system(size: 15, weight: .medium))
                        Text(msg)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Retry") {
                            Task { await personaVM.fetchPersonas(host: settings.host, port: settings.port) }
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }

                case .idle, .loaded:
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(personaVM.catalog) { persona in
                                PersonaCardView(
                                    persona: persona,
                                    isSelected: personaVM.isSelected(persona),
                                    isDisabled: !personaVM.isSelected(persona) && personaVM.isAtMaxSelection
                                ) {
                                    personaVM.toggleSelection(persona)
                                }
                            }
                        }
                        .padding(14)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Model selector + Start button
            VStack(spacing: 10) {
                // Model picker
                HStack(spacing: 10) {
                    Text("Model")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Picker("", selection: $personaVM.globalModel) {
                        ForEach(personaVM.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Start button
                Button {
                    if let url = personaVM.buildWebSocketURL(
                        host: settings.host,
                        port: settings.port,
                        narrate: settings.narrate,
                        rounds: settings.rounds
                    ) {
                        onStart(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        Text("Start game")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(personaVM.canStartGame ? Color.blue : Color.secondary.opacity(0.2))
                    .foregroundStyle(personaVM.canStartGame ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!personaVM.canStartGame)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Persona Card

struct PersonaCardView: View {
    let persona: PersonaTemplate
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {

                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarBackground)
                        .frame(width: 44, height: 44)
                    Text(initials)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(avatarForeground)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(persona.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(persona.role)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    // Skills
                    FlowTagLayout(items: persona.skillList) { skill in
                        Text(skill)
                            .font(.system(size: 11))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.1))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 2)
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.blue : Color.secondary.opacity(0.3),
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                        .background(
                            Circle().fill(isSelected ? Color.blue.opacity(0.1) : .clear)
                        )
                        .frame(width: 22, height: 22)

                    Image(systemName: isSelected ? "checkmark" : "plus")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
            }
            .padding(14)
            .background(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue.opacity(0.5) : Color.secondary.opacity(0.15),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isDisabled ? 0.4 : 1.0)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }

    // MARK: Avatar color — deterministik dari key

    private var colorIndex: Int { abs(persona.key.hashValue) % 4 }

    private var avatarBackground: Color {
        let colors: [Color] = [
            Color(red: 0.71, green: 0.83, blue: 0.96),
            Color(red: 0.81, green: 0.80, blue: 0.96),
            Color(red: 0.62, green: 0.88, blue: 0.79),
            Color(red: 0.98, green: 0.78, blue: 0.46)
        ]
        return colors[colorIndex]
    }

    private var avatarForeground: Color {
        let colors: [Color] = [
            Color(red: 0.05, green: 0.27, blue: 0.49),
            Color(red: 0.24, green: 0.20, blue: 0.54),
            Color(red: 0.03, green: 0.31, blue: 0.25),
            Color(red: 0.39, green: 0.22, blue: 0.02)
        ]
        return colors[colorIndex]
    }

    private var initials: String {
        persona.name
            .split(separator: " ")
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }
}

// MARK: - Flow Tag Layout

struct FlowTagLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 4)], spacing: 4) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}
