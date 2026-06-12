//
//  DebugSession.swift
//  escapee
//

import Foundation

struct DebugSession: Codable {
    struct Event: Codable {
        let kind: String
        let player: String?
        let playerId: String?
        let text: String
        let turn: Int?
        let playerOrder: [String]
    }

    struct Suspect: Codable {
        let name: String
        let connectionToVictim: String?
        let apparentMotive: String?
    }

    let events: [Event]
    let suspects: [Suspect]
    let deductionQuestion: String
    let deductionAttempt: Int
    let deductionMaxAttempts: Int
    let deductionHint: String
    let discoveries: [Event]

    static let userDefaultsKey = "debug_last_session"

    static func save(from gameVM: GameViewModel) {
        let session = DebugSession(
            events: gameVM.filteredEvents.map {
                Event(kind: $0.kind.rawValue, player: $0.player, playerId: $0.playerId,
                      text: $0.text, turn: $0.turn, playerOrder: $0.playerOrder)
            },
            suspects: (gameVM.setup?.suspects ?? []).map {
                Suspect(name: $0.name, connectionToVictim: $0.connectionToVictim,
                        apparentMotive: $0.apparentMotive)
            },
            deductionQuestion: gameVM.deductionPrompt?.question ?? "Who is the murderer?",
            deductionAttempt: gameVM.deductionPrompt?.attempt ?? 1,
            deductionMaxAttempts: gameVM.deductionPrompt?.maxAttempts ?? 3,
            deductionHint: gameVM.deductionPrompt?.hint ?? "",
            discoveries: gameVM.discoveries.map {
                Event(kind: $0.kind.rawValue, player: $0.player, playerId: $0.playerId,
                      text: $0.text, turn: $0.turn, playerOrder: $0.playerOrder)
            }
        )
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    static func load() -> DebugSession? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let session = try? JSONDecoder().decode(DebugSession.self, from: data)
        else { return nil }
        return session
    }

    func apply(to gameVM: GameViewModel) {
        let prompt = DeductionPrompt(
            question: deductionQuestion,
            attempt: deductionAttempt,
            maxAttempts: deductionMaxAttempts,
            hint: deductionHint
        )
        let suspectInfos = suspects.map {
            SuspectInfo(name: $0.name, connectionToVictim: $0.connectionToVictim,
                        apparentMotive: $0.apparentMotive)
        }
        let gameEvents = events.compactMap { e -> GameEvent? in
            guard let kind = EventKind(rawValue: e.kind) else { return nil }
            return GameEvent(kind: kind, player: e.player, playerId: e.playerId,
                             text: e.text, turn: e.turn, playerOrder: e.playerOrder)
        }
        let discoveryEvents = discoveries.compactMap { e -> GameEvent? in
            guard let kind = EventKind(rawValue: e.kind) else { return nil }
            return GameEvent(kind: kind, player: e.player, playerId: e.playerId,
                             text: e.text, turn: e.turn, playerOrder: e.playerOrder)
        }
        gameVM.loadDebugSession(
            events: gameEvents,
            suspects: suspectInfos,
            discoveries: discoveryEvents,
            prompt: prompt
        )
    }
}
