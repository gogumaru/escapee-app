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
    case idle
    case connecting
    case setup
    case playing
    case deduction   // Human deduction phase
    case finished
    case error(String)
}

// MARK: - Feed Filter

enum FeedFilter: String, CaseIterable {
    case all    = "All"
    case story  = "Story"
    case agents = "Agents"
    case system = "System"
}

// MARK: - GameViewModel

@MainActor
class GameViewModel: ObservableObject {

    @Published var filteredEvents: [GameEvent] = []
    @Published var phase: GamePhase = .idle
    @Published var currentState: GameStateSnapshot?
    @Published var gameResult: GameResult?
    @Published var setup: GameSetup?
    @Published var deductionPrompt: DeductionPrompt?
    @Published var discoveries: [GameEvent] = []
    @Published var activeFilter: FeedFilter = .all { didSet { applyFilter() } }

    var connectionLabel: String { service.connectionState.label }
    var isConnected: Bool {
        if case .connected = service.connectionState { return true }
        return false
    }

    private let service: GameSocketService
    private var cancellables = Set<AnyCancellable>()
    private var allEvents: [GameEvent] = []

    init(service: GameSocketService = GameSocketService()) {
        self.service = service
        bindService()
    }

    // MARK: - Public Actions

    func startGame(url: URL) {
        phase = .connecting
        service.connect(url: url)
    }

    func startGame(host: String, port: Int, narrate: Bool = true) {
        let url = PersonaService.shared.buildWebSocketURL(
            host: host, port: port, narrate: narrate,
            rounds: 75, model: "qwen2.5:7b", selectedPersonas: []
        )
        if let url { phase = .connecting; service.connect(url: url) }
    }

    func stopGame() {
        service.disconnect()
        phase = .idle
        allEvents = []
        filteredEvents = []
        currentState = nil
        gameResult = nil
        setup = nil
        deductionPrompt = nil
        discoveries = []
    }

    func replayGame() {
        guard let lastURL = service.lastURL else { return }
        stopGame()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startGame(url: lastURL)
        }
    }

    func setFilter(_ filter: FeedFilter) { activeFilter = filter }

    /// Kirim jawaban deduction
    func submitDeduction(answer: String) {
        service.sendDeduction(answer: answer)
    }

    // MARK: - Bind Service

    private func bindService() {
        service.$events
            .receive(on: RunLoop.main)
            .sink { [weak self] events in
                guard let self else { return }
                self.allEvents = events
                self.applyFilter()
            }
            .store(in: &cancellables)

        service.$discoveries
            .receive(on: RunLoop.main)
            .assign(to: &$discoveries)

        service.$currentState
            .receive(on: RunLoop.main)
            .assign(to: &$currentState)

        service.$gameResult
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                guard let self else { return }
                self.gameResult = result
                if result != nil {
                    self.phase = .playing
                }
            }
            .store(in: &cancellables)

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

        service.$deductionPrompt
            .receive(on: RunLoop.main)
            .sink { [weak self] prompt in
                guard let self else { return }
                if prompt != nil {
                    self.deductionPrompt = prompt
                    self.phase = .deduction
                }
            }
            .store(in: &cancellables)

        service.$connectionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .connected:
                    if case .connecting = self.phase { self.phase = .playing }
                case .disconnected:
                    guard case .playing = self.phase else { break }
                    break
                case .error(let msg):
                    self.phase = .error(msg)
                case .connecting:
                    self.phase = .connecting
                }
            }
            .store(in: &cancellables)
    }

    private func applyFilter() {
        switch activeFilter {
        case .all:    filteredEvents = allEvents
        case .story:  filteredEvents = allEvents.filter { $0.kind == .narration }
        case .agents: filteredEvents = allEvents.filter { $0.kind == .speech || $0.kind == .decision }
        case .system: filteredEvents = allEvents.filter { $0.kind == .observation || $0.kind == .system }
        }
    }
}

// MARK: - Helpers

extension GameViewModel {
    var navigationTitle: String { setup?.scenario ?? "Escapee" }
    var hasEvents: Bool { !allEvents.isEmpty }
    var playerOrder: [String] { service.playerOrder }

    func playerName(for actorId: String?) -> String? {
        guard let id = actorId else { return nil }
        return currentState?.players.first(where: { $0.id == id })?.name ?? id
    }

    var turnCount: Int {
        gameResult?.turns ?? currentState?.turn ?? allEvents.filter { $0.kind == .observation }.count
    }

    func badgeColor(for kind: EventKind) -> String {
        switch kind {
        case .narration: return "orange"
        case .speech:    return "blue"
        case .observation, .discovery: return "green"
        case .system:    return "gray"
        case .decision:  return "purple"
        case .result:    return "red"
        default:         return "gray"
        }
    }

    func badgeLabel(for kind: EventKind) -> String {
        switch kind {
        case .narration:  return "Story"
        case .speech:     return "Agent"
        case .observation: return "World"
        case .discovery:  return "Clue"
        case .system:     return "System"
        case .decision:   return "Think"
        case .result:     return "Result"
        default:          return "—"
        }
    }
}
