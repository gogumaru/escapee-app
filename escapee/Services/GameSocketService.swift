//
//  GameSocketService.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//

import Foundation
import Combine

// MARK: - Debug Logger

struct Log {
    static func ws(_ msg: String)    { print("🔌 [WebSocket] \(msg)") }
    static func parse(_ msg: String) { print("🔍 [Parse] \(msg)") }
    static func event(_ msg: String) { print("📨 [Event] \(msg)") }
    static func error(_ msg: String) { print("❌ [Error] \(msg)") }
    static func state(_ msg: String) { print("🗺️ [State] \(msg)") }
}

// MARK: - Event Kind

enum EventKind: String, Codable {
    case setup          = "setup"
    case speech         = "speech"
    case observation    = "observation"
    case discovery      = "discovery"
    case system         = "system"
    case narration      = "narration"
    case decision       = "decision"
    case prompt         = "prompt"
    case planner        = "planner"
    case state          = "state"
    case result         = "result"
    case humanDeduction = "human_deduction"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = EventKind(rawValue: raw) ?? .unknown
    }
}

// MARK: - Backend Message Types

struct BackendMessage: Decodable {
    let type: String
    let kind: String?
}

struct BackendEvent: Decodable {
    let kind: EventKind
    let actorId: String?
    let text: String?
    let turn: Int?
    let data: BackendEventData?

    enum CodingKeys: String, CodingKey {
        case kind
        case actorId = "actor_id"
        case text, turn, data
    }
}

struct BackendEventData: Decodable {
    let question: String?
    let attempt: Int?
    let maxAttempts: Int?
    let hint: String?

    enum CodingKeys: String, CodingKey {
        case question, attempt, hint
        case maxAttempts = "max_attempts"
    }
}

struct BackendResult: Decodable {
    let won: Bool
    let turns: Int
    let reason: String
}

// MARK: - Suspect & Deduction models

struct SuspectInfo: Codable, Identifiable {
    var id: String { name }
    let name: String
    let connectionToVictim: String?
    let apparentMotive: String?

    enum CodingKeys: String, CodingKey {
        case name
        case connectionToVictim = "connection_to_victim"
        case apparentMotive     = "apparent_motive"
    }

    init(name: String, connectionToVictim: String?, apparentMotive: String?) {
        self.name = name
        self.connectionToVictim = connectionToVictim
        self.apparentMotive = apparentMotive
    }
}

struct DeductionPrompt {
    let question: String
    let attempt: Int
    let maxAttempts: Int
    let hint: String
}

// MARK: - GameEvent (untuk UI)

struct GameEvent: Identifiable {
    let id: UUID = UUID()
    let kind: EventKind
    let player: String?
    let playerId: String?
    let text: String
    let turn: Int?
    let playerOrder: [String]

    var displayText: String { text }

    var agentColor: AgentColor {
        AgentColor.from(playerId, order: playerOrder)
    }

    static func from(_ event: BackendEvent, resolvedName: String? = nil, playerOrder: [String] = []) -> GameEvent {
        GameEvent(
            kind: event.kind,
            player: resolvedName ?? event.actorId,
            playerId: event.actorId,
            text: event.text ?? "",
            turn: event.turn,
            playerOrder: playerOrder
        )
    }

    static func synthetic(kind: EventKind, text: String) -> GameEvent {
        GameEvent(kind: kind, player: nil, playerId: nil, text: text, turn: nil, playerOrder: [])
    }
}

// MARK: - GameStateSnapshot

struct GameStateSnapshot: Decodable {
    let turn: Int
    let rooms: [String]
    let accessibleRooms: [String]
    let players: [PlayerState]
    let objects: [ObjectState]
    let finished: Bool
    let won: Bool

    enum CodingKeys: String, CodingKey {
        case turn, rooms, players, objects, finished, won
        case accessibleRooms = "accessible_rooms"
    }
}

struct PlayerState: Decodable, Identifiable {
    let id: String
    let name: String
    let room: String
    let inventory: [String]
}

struct ObjectState: Decodable, Identifiable {
    let id: String
    let description: String
    let state: String
    let room: String?
    let location: String
    let takeable: Bool
}

struct GameResult {
    let won: Bool
    let turns: Int
    let reason: String
}

struct GameSetup {
    let scenario: String?
    let suspects: [SuspectInfo]
    let deductionQuestion: String?
}

struct AnyCodable: Decodable {
    init(from decoder: Decoder) throws {
        _ = try? decoder.singleValueContainer()
    }
}

// MARK: - GameSocketService

class GameSocketService: NSObject, ObservableObject {

    // MARK: Published
    @Published var events: [GameEvent] = []
    @Published var discoveries: [GameEvent] = []
    @Published var currentState: GameStateSnapshot?
    @Published var gameResult: GameResult?
    @Published var setup: GameSetup?
    @Published var deductionPrompt: DeductionPrompt?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastNarration: String? = nil

    enum ConnectionState: Equatable {
        case disconnected, connecting, connected
        case error(String)

        var label: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting:   return "Connecting..."
            case .connected:    return "Connected"
            case .error(let m): return "Error: \(m)"
            }
        }

        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected), (.connecting, .connecting), (.connected, .connected): return true
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    // MARK: Private
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private let decoder = JSONDecoder()
    private var messageCount = 0
    private var playerNames: [String: String] = [:]
    private(set) var playerOrder: [String] = []
    private(set) var lastURL: URL?

    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    // MARK: - Public API

    func connect(url: URL) {
        guard connectionState != .connected, connectionState != .connecting else { return }
        Log.ws("Connecting to: \(url)")
        lastURL = url
        reset()
        connectionState = .connecting
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        listenForMessages()
    }

    func disconnect() {
        Log.ws("Disconnecting...")
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
    }

    /// Kirim jawaban deduction ke server
    func sendDeduction(answer: String) {
        guard connectionState == .connected else {
            Log.error("Cannot send deduction — not connected")
            return
        }
        let payload: [String: String] = ["type": "deduction", "answer": answer]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        Log.ws("Sending deduction: \(answer)")
        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                Log.error("Send deduction failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private

    private func reset() {
        messageCount = 0
        playerNames = [:]
        playerOrder = []
        DispatchQueue.main.async {
            self.events = []
            self.discoveries = []
            self.currentState = nil
            self.gameResult = nil
            self.setup = nil
            self.deductionPrompt = nil
        }
    }

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                self.messageCount += 1
                if case .string(let text) = message {
                    Log.ws("Message #\(self.messageCount) (\(text.count) chars)")
                    self.handleRawMessage(text)
                } else if case .data(let data) = message,
                          let text = String(data: data, encoding: .utf8) {
                    self.handleRawMessage(text)
                }
                self.listenForMessages()

            case .failure(let error):
                let nsError = error as NSError
                if [57, 54].contains(nsError.code) {
                    Log.ws("Socket closed by server — normal")
                    DispatchQueue.main.async { self.connectionState = .disconnected }
                } else {
                    Log.error("Receive failed [\(nsError.code)]: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.connectionState = .error(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func handleRawMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        guard let meta = try? decoder.decode(BackendMessage.self, from: data) else {
            Log.error("Cannot read message type: \(text.prefix(100))")
            return
        }

        Log.parse("type=\(meta.type) kind=\(meta.kind ?? "-")")

        switch meta.type {
        case "event":  handleEventMessage(data, raw: text)
        case "state":  handleStateMessage(data)
        case "result": handleResultMessage(data)
        case "setup":  handleSetupMessage(data, raw: text)
        default:       Log.error("Unknown message type: \(meta.type)")
        }
    }

    private func handleEventMessage(_ data: Data, raw: String) {
        do {
            let backendEvent = try decoder.decode(BackendEvent.self, from: data)
            let resolvedName = playerNames[backendEvent.actorId ?? ""] ?? backendEvent.actorId
            let event = GameEvent.from(backendEvent, resolvedName: resolvedName, playerOrder: playerOrder)
            Log.event("kind=\(event.kind.rawValue) player=\(event.player ?? "nil") text=\(event.text.prefix(60))")

            DispatchQueue.main.async {
                switch event.kind {
                case .prompt, .planner, .decision:
                    break

                case .discovery:
                    // Simpan ke evidence log
                    self.discoveries.append(event)
                    self.events.append(event)

                case .humanDeduction:
                    // Trigger deduction UI
                    let eventData = backendEvent.data
                    let prompt = DeductionPrompt(
                        question: eventData?.question ?? event.text,
                        attempt:  eventData?.attempt ?? 1,
                        maxAttempts: eventData?.maxAttempts ?? 3,
                        hint: eventData?.hint ?? ""
                    )
                    self.deductionPrompt = prompt
                    Log.event("Human deduction triggered: \(prompt.question)")

                case .system:
                    let text = event.text
                    let skipPrefixes = [
                        "(progress gate)", "(planner override)", "(loop avoided)",
                        "(policy gate)", "(stall gate)", "CRITICAL:",
                        "OUT-OF-POLICY", "STALL MODE", "📋 Shared plan"
                    ]
                    if !skipPrefixes.contains(where: { text.hasPrefix($0) }) {
                        self.events.append(event)
                    }

                case .narration:
                    self.lastNarration = event.text
                    self.events.append(event)

                default:
                    self.events.append(event)
                }
            }
        } catch {
            Log.error("Failed to decode event: \(error)\nRaw: \(raw.prefix(200))")
        }
    }

    private func handleStateMessage(_ data: Data) {
        do {
            let snapshot = try decoder.decode(GameStateSnapshot.self, from: data)
            let playerInfo = snapshot.players.map { "\($0.name)@\($0.room)" }.joined(separator: ", ")
            Log.state("Turn \(snapshot.turn) | \(playerInfo) | Objects: \(snapshot.objects.count)")
            for player in snapshot.players {
                playerNames[player.id] = player.name
                if !playerOrder.contains(player.id) { playerOrder.append(player.id) }
            }
            DispatchQueue.main.async { self.currentState = snapshot }
        } catch {
            Log.error("Failed to decode state: \(error)")
        }
    }

    private func handleResultMessage(_ data: Data) {
        do {
            let result = try decoder.decode(BackendResult.self, from: data)
            Log.event("Result — won:\(result.won) turns:\(result.turns) reason:\(result.reason)")
            let emoji = result.won ? "🎉" : "💀"
            let reasonLabel: String
            switch result.reason {
            case "escaped":    reasonLabel = "The team escaped!"
            case "turn_limit": reasonLabel = "Turn limit reached (\(result.turns) turns)."
            case "stalled":    reasonLabel = "The team got stuck after \(result.turns) turns."
            default:           reasonLabel = result.reason
            }
            DispatchQueue.main.async {
                self.gameResult = GameResult(won: result.won, turns: result.turns, reason: result.reason)
                self.events.append(.synthetic(kind: .result, text: "\(emoji) Game Over — \(reasonLabel)"))
            }
        } catch {
            Log.error("Failed to decode result: \(error)")
        }
    }

    private func handleSetupMessage(_ data: Data, raw: String) {
        Log.event("Setup received")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        // Parse suspects
        var suspects: [SuspectInfo] = []
        if let suspectsData = try? JSONSerialization.data(withJSONObject: json["suspects"] as? [[String: Any]] ?? []) {
            suspects = (try? decoder.decode([SuspectInfo].self, from: suspectsData)) ?? []
        }

        let scenario = json["scenario"] as? String
        let deductionQuestion = json["deduction_question"] as? String
        let text = scenario ?? json["text"] as? String ?? json["message"] as? String ?? ""

        DispatchQueue.main.async {
            self.setup = GameSetup(
                scenario: scenario,
                suspects: suspects,
                deductionQuestion: deductionQuestion
            )
            // Setup tidak ditampilkan di feed — cukup update navigationTitle
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension GameSocketService: URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        Log.ws("✅ Connected")
        DispatchQueue.main.async { self.connectionState = .connected }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        let reasonStr = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "none"
        Log.ws("Connection closed — code: \(closeCode.rawValue), reason: \(reasonStr)")
        DispatchQueue.main.async {
            switch closeCode {
            case .normalClosure, .goingAway: self.connectionState = .disconnected
            default: self.connectionState = .error("Closed unexpectedly (code \(closeCode.rawValue))")
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Log.error("Task error: \(error.localizedDescription)")
        } else {
            Log.ws("Task completed normally")
        }
    }
}
