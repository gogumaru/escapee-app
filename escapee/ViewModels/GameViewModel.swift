//
//  GameViewModel.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//

import Foundation
import Combine

// MARK: - Game Phase

enum GamePhase {
    case idle           // Belum konek
    case connecting     // Sedang konek ke backend
    case setup          // Terima info scenario, belum mulai
    case playing        // Game sedang berjalan
    case finished       // Game selesai (won/lost)
    case error(String)  // Koneksi/parse error
}

// MARK: - Feed Filter

enum FeedFilter: String, CaseIterable {
    case all        = "All"
    case story      = "Story"      // narration
    case agents     = "Agents"     // speech + decision
    case system     = "System"     // observation + system
}

// MARK: - GameViewModel

@MainActor
class GameViewModel: ObservableObject {

    // MARK: Published — UI reads these

    /// Semua event untuk ditampilkan di feed
    @Published var filteredEvents: [GameEvent] = []

    /// Phase game saat ini
    @Published var phase: GamePhase = .idle

    /// State dunia (room, inventory, exits)
    @Published var currentState: GameStateSnapshot?

    /// Hasil akhir game
    @Published var gameResult: GameResult?

    /// Info setup (scenario, players)
    @Published var setup: GameSetup?

    /// Filter feed aktif
    @Published var activeFilter: FeedFilter = .all {
        didSet { applyFilter() }
    }

    /// Status koneksi sebagai string
    var connectionLabel: String {
        service.connectionState.label
    }

    var isConnected: Bool {
        if case .connected = service.connectionState { return true }
        return false
    }

    // MARK: Private

    private let service: GameSocketService
    private var cancellables = Set<AnyCancellable>()
    private var allEvents: [GameEvent] = []

    // MARK: Init

    init(service: GameSocketService = GameSocketService()) {
        self.service = service
        bindService()
    }

    // MARK: - Public Actions

    /// Konek ke backend dan mulai game
    func startGame(host: String, port: Int, narrate: Bool = true) {
        phase = .connecting
        service.connect(host: host, port: port, narrate: narrate)
    }

    /// Stop game dan disconnect — balik ke setup screen
    func stopGame() {
        service.disconnect()
        phase = .idle
        allEvents = []
        filteredEvents = []
        currentState = nil
        gameResult = nil
        setup = nil
    }

    /// Langsung reconnect dengan settings yang sama
    func replayGame() {
        let lastHost = service.lastHost
        let lastPort = service.lastPort
        let lastNarrate = service.lastNarrate
        stopGame()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startGame(host: lastHost, port: lastPort, narrate: lastNarrate)
        }
    }

    /// Ganti filter feed
    func setFilter(_ filter: FeedFilter) {
        activeFilter = filter
    }

    // MARK: - Private: Bind Service

    private func bindService() {

        // Pantau semua events baru
        service.$events
            .receive(on: RunLoop.main)
            .sink { [weak self] events in
                guard let self else { return }
                self.allEvents = events
                self.applyFilter()
            }
            .store(in: &cancellables)

        // Pantau state dunia
        service.$currentState
            .receive(on: RunLoop.main)
            .assign(to: &$currentState)

        // Pantau game result
        service.$gameResult
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                guard let self else { return }
                self.gameResult = result
                // Tidak langsung pindah ke .finished —
                // pesan akhir akan ditampilkan di feed via synthetic event
            }
            .store(in: &cancellables)

        // Pantau setup info
        service.$setup
            .receive(on: RunLoop.main)
            .sink { [weak self] setup in
                guard let self else { return }
                self.setup = setup
                if setup != nil, case .connecting = self.phase {
                    self.phase = .setup
                }
            }
            .store(in: &cancellables)

        // Pantau connection state
        service.$connectionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .connected:
                    if case .connecting = self.phase {
                        self.phase = .playing
                    }
                case .disconnected:
                    guard case .playing = self.phase else { break }
                    // Tetap di feed — jangan pindah screen
                    // GameSocketService sudah inject synthetic event ke feed
                    break
                case .error(let msg):
                    self.phase = .error(msg)
                case .connecting:
                    self.phase = .connecting
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private: Filter Logic

    private func applyFilter() {
        switch activeFilter {
        case .all:
            filteredEvents = allEvents
        case .story:
            filteredEvents = allEvents.filter { $0.kind == .narration }
        case .agents:
            filteredEvents = allEvents.filter {
                $0.kind == .speech || $0.kind == .decision
            }
        case .system:
            filteredEvents = allEvents.filter {
                $0.kind == .observation || $0.kind == .system
            }
        }
    }
}

// MARK: - Computed Helpers untuk UI

extension GameViewModel {

    /// Judul yang tampil di navigation bar
    var navigationTitle: String {
        setup?.scenario ?? "Escapee"
    }

    /// Warna badge per event kind
    func badgeColor(for kind: EventKind) -> String {
        switch kind {
        case .narration:   return "orange"
        case .speech:      return "blue"
        case .observation: return "green"
        case .system:      return "gray"
        case .decision:    return "purple"
        case .result:      return "red"
        default:           return "gray"
        }
    }

    /// Label singkat per event kind untuk badge
    func badgeLabel(for kind: EventKind) -> String {
        switch kind {
        case .narration:   return "Story"
        case .speech:      return "Agent"
        case .observation: return "World"
        case .system:      return "System"
        case .decision:    return "Think"
        case .result:      return "Result"
        default:           return "—"
        }
    }

    /// Apakah ada event yang masuk (game aktif)
    var hasEvents: Bool { !allEvents.isEmpty }

    /// Turn count — dari state snapshot (paling akurat) atau result
    var turnCount: Int {
        gameResult?.turns ?? currentState?.turn ?? allEvents.filter { $0.kind == .observation }.count
    }
}
