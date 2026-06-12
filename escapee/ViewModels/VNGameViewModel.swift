//
//  VNGameViewModel.swift
//  escapee
//
//  Created by Benedikta Anin on 09/06/26.
//


import Foundation
import Combine

@MainActor
class VNGameViewModel: ObservableObject {

    // MARK: - Published
    @Published var currentEvent: GameEvent?
    @Published var currentIndex: Int = 0
    @Published var isAutoPlay: Bool = false
    @Published var allEvents: [GameEvent] = []
    @Published var activeCharacters: [String] = []
    @Published var currentRoom: String = ""

    // MARK: - Private
    private var autoPlayTask: Task<Void, Never>?
    private let autoPlayDelay: Double = 3.0
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {}

    func bind(to gameViewModel: GameViewModel) {
        cancellables.removeAll()

        gameViewModel.$filteredEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] events in
                guard let self else { return }
                let newEvents = events.filter { event in
                    !self.allEvents.contains(where: { $0.id == event.id })
                }
                self.allEvents = events

                if self.currentEvent == nil && !events.isEmpty {
                    self.currentIndex = 0
                    self.currentEvent = events[0]
                    self.updateCharacter(for: events[0])
                }

                if self.isAutoPlay && !newEvents.isEmpty {
                    self.scheduleAutoPlay()
                }
            }
            .store(in: &cancellables)

        gameViewModel.$currentState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self, let state else { return }
                if let firstPlayer = state.players.first {
                    self.currentRoom = firstPlayer.room
                }
            }
            .store(in: &cancellables)
    }

    func reset() {
        cancellables.removeAll()
        autoPlayTask?.cancel()
        autoPlayTask = nil
        isAutoPlay = false
        currentIndex = 0
        currentEvent = nil
        allEvents = []
        activeCharacters = []
        currentRoom = ""
    }

    // MARK: - Navigation
    // Next dan prev loncat ke "anchor event" berikutnya
    // Anchor = speech, narration, result, atau progress (system dengan ✓)
    // Observation dan system biasa di-skip

    private func isAnchor(_ event: GameEvent) -> Bool {
        switch event.kind {
        case .speech, .narration, .result:
            return true
        case .system:
            // Hanya progress yang jadi anchor
            return event.displayText.contains("Progress") || event.displayText.contains("✓")
        default:
            return false
        }
    }

    func nextEvent() {
        // Cari anchor berikutnya setelah currentIndex
        let nextAnchorIndex = (currentIndex + 1..<allEvents.count)
            .first { isAnchor(allEvents[$0]) }

        guard let targetIndex = nextAnchorIndex else { return }

        // Set semua events antara currentIndex dan targetIndex ke currentEvent
        // untuk character update yang benar
        for i in (currentIndex + 1)...targetIndex {
            updateCharacter(for: allEvents[i])
        }

        currentIndex = targetIndex
        currentEvent = allEvents[targetIndex]
    }

    func jumpToLast() {
        guard !allEvents.isEmpty else { return }
        let lastAnchor = (0..<allEvents.count).reversed().first { isAnchor(allEvents[$0]) }
        let target = lastAnchor ?? allEvents.count - 1
        if currentIndex + 1 <= target {
            for i in (currentIndex + 1)...target {
                updateCharacter(for: allEvents[i])
            }
        }
        currentIndex = target
        currentEvent = allEvents[target]
    }

    func prevEvent() {
        // Cari anchor sebelumnya
        let prevAnchorIndex = (0..<currentIndex).reversed()
            .first { isAnchor(allEvents[$0]) }

        guard let targetIndex = prevAnchorIndex else { return }

        currentIndex = targetIndex
        currentEvent = allEvents[targetIndex]
        updateCharacter(for: allEvents[targetIndex])
    }

    var hasNext: Bool {
        guard currentIndex < allEvents.count, currentIndex + 1 < allEvents.count else { return false }
        return (currentIndex + 1..<allEvents.count).contains { isAnchor(allEvents[$0]) }
    }

    var hasPrev: Bool {
        guard currentIndex > 0, currentIndex <= allEvents.count else { return false }
        return (0..<min(currentIndex, allEvents.count)).contains { isAnchor(allEvents[$0]) }
    }

    // MARK: - Auto Play

    func toggleAutoPlay() {
        isAutoPlay.toggle()
        if isAutoPlay {
            scheduleAutoPlay()
        } else {
            autoPlayTask?.cancel()
            autoPlayTask = nil
        }
    }

    private func scheduleAutoPlay() {
        autoPlayTask?.cancel()
        autoPlayTask = Task {
            while isAutoPlay {
                try? await Task.sleep(nanoseconds: UInt64(autoPlayDelay * 1_000_000_000))
                guard !Task.isCancelled else { break }
                if hasNext {
                    nextEvent()
                } else {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
    }

    // MARK: - Character Update

    private func updateCharacter(for event: GameEvent) {
        guard let playerId = event.playerId, !playerId.isEmpty else { return }

        switch event.kind {
        case .speech:
            activeCharacters = [playerId]
        case .observation:
            if activeCharacters.isEmpty {
                activeCharacters = [playerId]
            }
        default:
            break
        }
    }

    // MARK: - Helpers

    func isSpeaking(_ characterId: String) -> Bool {
        currentEvent?.player == characterId
    }

    func roomColor(for room: String) -> (primary: String, secondary: String) {
        let name = room.lowercased()
        if name.contains("library") || name.contains("study") {
            return ("#2d1a08", "#1a0f05")
        } else if name.contains("parlor") || name.contains("living") {
            return ("#1a0805", "#0f0502")
        } else if name.contains("hidden") || name.contains("secret") {
            return ("#0a0515", "#05020d")
        } else if name.contains("corridor") || name.contains("hall") {
            return ("#0a1a1a", "#050d0d")
        } else if name.contains("room_1") {
            return ("#1a1408", "#0f0d05")
        } else if name.contains("room_2") {
            return ("#0f1a0f", "#080d08")
        } else if name.contains("room_3") {
            return ("#1a0f1a", "#0d080d")
        } else if name.contains("room_4") {
            return ("#1a0808", "#0d0505")
        }
        return ("#1a1008", "#0f0a05")
    }

    var currentEventType: VNEventType {
        guard let event = currentEvent else { return .system }
        let text = event.displayText.lowercased()

        switch event.kind {
        case .narration:
            return .narration
        case .speech:
            if text.hasPrefix("(idea)") { return .idea }
            if text.hasPrefix("(reflection)") { return .reflection }
            return .speech
        case .observation:
            return .observation
        case .system:
            return .system
        case .result:
            return .result
        default:
            return .system
        }
    }

    var displayText: String {
        guard let event = currentEvent else { return "" }
        var text = event.displayText
        text = text.replacingOccurrences(of: "(idea) ", with: "")
        text = text.replacingOccurrences(of: "(reflection) ", with: "")
        text = text.replacingOccurrences(of: "(idea)", with: "")
        text = text.replacingOccurrences(of: "(reflection)", with: "")
        if text.hasPrefix("You ") { text = String(text.dropFirst(4)) }
        return text
    }
}

// MARK: - VN Event Type

enum VNEventType {
    case narration
    case speech
    case idea
    case reflection
    case observation
    case system
    case result
}
