//
//  PersonaViewModel.swift
//  escapee
//
//  Created by Benedikta Anin on 08/06/26.
//


import Foundation
import Combine
import SwiftUI

@MainActor
class PersonaViewModel: ObservableObject {

    // MARK: - Published State

    /// Semua persona dari catalog
    @Published var catalog: [PersonaTemplate] = []

    /// Model list yang tersedia
    @Published var availableModels: [String] = []

    /// Default model dari server
    @Published var defaultModel: String = ""

    /// Personas yang dipilih user (max 4), dengan model override per persona
    @Published var selectedPersonas: [(persona: PersonaTemplate, model: String?)] = []

    /// Global model — dipakai kalau persona tidak punya model override
    @Published var globalModel: String = ""

    /// Loading / error state
    @Published var loadState: LoadState = .idle

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)

        var isLoading: Bool {
            if case .loading = self { return true }
            return false
        }

        var errorMessage: String? {
            if case .error(let msg) = self { return msg }
            return nil
        }
    }

    // MARK: - Private
    private let service = PersonaService.shared

    // MARK: - Fetch

    func fetchPersonas(host: String, port: Int) async {
        loadState = .loading

        do {
            let response = try await service.fetchPersonas(host: host, port: port)

            catalog         = response.catalog
            availableModels = response.models
            defaultModel    = response.defaultModel
            globalModel     = response.defaultModel

            // Pre-select roster default — match nama roster ke catalog
            if selectedPersonas.isEmpty {
                let rosterNames = Set(response.roster.map { $0.name })
                selectedPersonas = response.catalog
                    .filter { rosterNames.contains($0.name) }
                    .map { ($0, nil) }
            }

            loadState = .loaded
        } catch {
            loadState = .error(error.localizedDescription)
        }
    }

    // MARK: - Selection Management

    /// Toggle pilih/batal persona. Max 4.
    func toggleSelection(_ persona: PersonaTemplate) {
        if let index = selectedIndex(of: persona) {
            selectedPersonas.remove(at: index)
        } else {
            guard selectedPersonas.count < 4 else { return }
            selectedPersonas.append((persona, nil))
        }
    }

    /// Cek apakah persona sudah dipilih
    func isSelected(_ persona: PersonaTemplate) -> Bool {
        selectedIndex(of: persona) != nil
    }

    /// Set model override untuk persona tertentu
    func setModel(_ model: String?, for persona: PersonaTemplate) {
        guard let index = selectedIndex(of: persona) else { return }
        selectedPersonas[index].model = model
    }

    /// Model yang aktif untuk persona (override atau global)
    func activeModel(for persona: PersonaTemplate) -> String {
        guard let index = selectedIndex(of: persona) else { return globalModel }
        return selectedPersonas[index].model ?? globalModel
    }

    /// Reset ke roster default
    func resetToDefault() {
        selectedPersonas = catalog.prefix(2).map { ($0, nil) }
    }

    /// Urutan persona yang dipilih (untuk drag reorder nanti)
    func movePersona(from source: IndexSet, to destination: Int) {
        var arr = selectedPersonas
        arr.move(fromOffsets: source, toOffset: destination)
        selectedPersonas = arr
    }

    // MARK: - Build WebSocket URL

    func buildWebSocketURL(host: String, port: Int, narrate: Bool, rounds: Int) -> URL? {
        service.buildWebSocketURL(
            host: host,
            port: port,
            narrate: narrate,
            rounds: rounds,
            model: globalModel.isEmpty ? defaultModel : globalModel,
            selectedPersonas: selectedPersonas
        )
    }

    // MARK: - Helpers

    var canStartGame: Bool {
        !selectedPersonas.isEmpty && loadState == .loaded
    }

    var selectionSummary: String {
        selectedPersonas.map { $0.persona.name }.joined(separator: ", ")
    }

    var isAtMaxSelection: Bool {
        selectedPersonas.count >= 4
    }

    private func selectedIndex(of persona: PersonaTemplate) -> Int? {
        selectedPersonas.firstIndex(where: { $0.persona.key == persona.key })
    }
}
