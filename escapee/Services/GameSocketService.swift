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
    case setup       = "setup"
    case speech      = "speech"
    case observation = "observation"
    case system      = "system"
    case narration   = "narration"
    case decision    = "decision"
    case prompt      = "prompt"
    case planner     = "planner"
    case state       = "state"
    case result      = "result"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = EventKind(rawValue: raw) ?? .unknown
    }
}

// MARK: - Backend Message Types
// Backend kirim 3 jenis pesan berbeda:
// 1. {"type": "event", "kind": "speech/observation/...", "actor_id": ..., "text": ...}
// 2. {"type": "state", "turn": ..., "players": [...], "objects": [...]}
// 3. {"type": "result", "won": ..., "turns": ..., "reason": ...}

struct BackendMessage: Decodable {
    let type: String   // "event" | "state" | "result" | "setup"
    let kind: String?  // hanya ada kalau type == "event"
}

// Event dari backend (type = "event")
struct BackendEvent: Decodable {
    let kind: EventKind
    let actorId: String?
    let text: String?
    let turn: Int?
    let data: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case kind
        case actorId = "actor_id"
        case text, turn, data
    }
}

// Result dari backend (type = "result")
struct BackendResult: Decodable {
    let won: Bool
    let turns: Int
    let reason: String
}

// MARK: - GameEvent (untuk UI)

struct GameEvent: Identifiable {
    let id: UUID = UUID()
    let kind: EventKind
    let player: String?
    let text: String
    let turn: Int?

    var displayText: String { text }

    static func from(_ event: BackendEvent, resolvedName: String? = nil) -> GameEvent {
        GameEvent(
            kind: event.kind,
            player: resolvedName ?? event.actorId,
            text: event.text ?? "",
            turn: event.turn
        )
    }

    static func synthetic(kind: EventKind, text: String) -> GameEvent {
        GameEvent(kind: kind, player: nil, text: text, turn: nil)
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
}

// MARK: - AnyCodable (untuk field data yang bisa null)

struct AnyCodable: Decodable {
    init(from decoder: Decoder) throws {
        // Terima apapun tanpa error
        _ = try? decoder.singleValueContainer()
    }
}


// MARK: - GameSocketService

class GameSocketService: NSObject, ObservableObject {

    // MARK: Published
    @Published var events: [GameEvent] = []
    @Published var currentState: GameStateSnapshot?
    @Published var gameResult: GameResult?
    @Published var setup: GameSetup?
    @Published var connectionState: ConnectionState = .disconnected

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
    private var playerNames: [String: String] = [:]  // player_1 → "Alex Quinn"

    // Simpan settings terakhir untuk replay
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

    // MARK: - Private

    private func reset() {
        messageCount = 0
        DispatchQueue.main.async {
            self.events = []
            self.currentState = nil
            self.gameResult = nil
            self.setup = nil
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
                let normalCodes = [57, 54]
                if normalCodes.contains(nsError.code) {
                    Log.ws("Socket closed by server (code \(nsError.code)) — normal")
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

        // Peek tipe pesan dulu
        guard let meta = try? decoder.decode(BackendMessage.self, from: data) else {
            Log.error("Cannot read message type: \(text.prefix(100))")
            return
        }

        Log.parse("type=\(meta.type) kind=\(meta.kind ?? "-")")

        switch meta.type {
        case "event":
            handleEventMessage(data, raw: text)
        case "state":
            handleStateMessage(data)
        case "result":
            handleResultMessage(data)
        case "setup":
            handleSetupMessage(data, raw: text)
        default:
            Log.error("Unknown message type: \(meta.type)")
        }
    }

    private func handleEventMessage(_ data: Data, raw: String) {
        do {
            let backendEvent = try decoder.decode(BackendEvent.self, from: data)
            let resolvedName = playerNames[backendEvent.actorId ?? ""] ?? backendEvent.actorId
        let event = GameEvent.from(backendEvent, resolvedName: resolvedName)
            Log.event("kind=\(event.kind.rawValue) player=\(event.player ?? "nil") text=\(event.text.prefix(60))")

            DispatchQueue.main.async {
                switch event.kind {
                case .prompt, .planner, .decision:
                    break

                case .system:
                    // Skip internal orchestrator messages
                    let text = event.text
                    let skipPrefixes = [
                        "(progress gate)",
                        "(planner override)",
                        "(loop avoided)",
                        "(policy gate)",
                        "(stall gate)",
                        "CRITICAL:",
                        "OUT-OF-POLICY",
                        "STALL MODE",
                        "📋 Shared plan"
                    ]
                    let shouldSkip = skipPrefixes.contains { text.hasPrefix($0) }
                    if !shouldSkip {
                        self.events.append(event)
                    }

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
            // Simpan mapping id → nama untuk resolve di event
            for player in snapshot.players {
                playerNames[player.id] = player.name
            }
            DispatchQueue.main.async {
                self.currentState = snapshot
            }
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
            case "turn_limit": reasonLabel = "Turn limit reached (\(result.turns) turns). The team did not escape."
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
        // Setup bisa punya berbagai struktur — ambil text kalau ada
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String ?? json["message"] as? String {
            DispatchQueue.main.async {
                self.setup = GameSetup(scenario: text)
                self.events.append(.synthetic(kind: .setup, text: "🎮 \(text)"))
            }
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
            case .normalClosure, .goingAway:
                self.connectionState = .disconnected
            default:
                self.connectionState = .error("Closed unexpectedly (code \(closeCode.rawValue))")
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            Log.error("Task error [\(nsError.code)]: \(error.localizedDescription)")
        } else {
            Log.ws("Task completed normally")
        }
    }
}
