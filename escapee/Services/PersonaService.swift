//
//  PersonaService.swift
//  escapee
//
//  Created by Benedikta Anin on 08/06/26.
//

import Foundation

// MARK: - Models

struct PersonaCatalogResponse: Decodable {
    let defaultModel: String
    let models: [String]
    let catalog: [PersonaTemplate]
    let roster: [RosterPersona]

    enum CodingKeys: String, CodingKey {
        case defaultModel = "default_model"
        case models, catalog, roster
    }
}

/// Roster tidak punya field "key" — hanya nama + role
struct RosterPersona: Decodable {
    let name: String
    let role: String
    let skills: [String]?
    let backstory: String?
    let personality: String?
    let gender: String?
    let model: String?
    let temperature: Double?
}

struct PersonaTemplate: Decodable, Identifiable, Hashable {
    let key: String
    let name: String
    let role: String
    let skills: [String]?       // optional — bisa null atau missing
    let backstory: String?
    let personality: String?
    let gender: String?
    let model: String?
    let temperature: Double?

    var skillList: [String] { skills ?? [] }

    // Identifiable — pakai key
    var id: String { key }

    // Encode ke dict untuk WebSocket query param
    func toQueryDict(overrideModel: String? = nil) -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "role": role,
            "skills": skillList
        ]
        if let backstory, !backstory.isEmpty   { dict["backstory"] = backstory }
        if let personality, !personality.isEmpty { dict["personality"] = personality }
        if let gender, !gender.isEmpty         { dict["gender"] = gender }

        // Model priority: user override > persona default
        if let m = overrideModel ?? model { dict["model"] = m }
        if let t = temperature            { dict["temperature"] = t }
        return dict
    }

    static func == (lhs: PersonaTemplate, rhs: PersonaTemplate) -> Bool { lhs.key == rhs.key }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }
}

// MARK: - PersonaService

class PersonaService {

    static let shared = PersonaService()
    private init() {}

    enum PersonaError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL:           return "Invalid server URL"
            case .networkError(let e):  return "Network error: \(e.localizedDescription)"
            case .decodingError(let e): return "Failed to parse response: \(e.localizedDescription)"
            case .serverError(let c):   return "Server error (code \(c))"
            }
        }
    }

    // MARK: - Fetch all personas

    func fetchPersonas(host: String, port: Int) async throws -> PersonaCatalogResponse {
        let urlString = "http://\(host):\(port)/api/personas"
        guard let url = URL(string: urlString) else {
            throw PersonaError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw PersonaError.serverError(http.statusCode)
        }

        do {
            // Debug — print raw JSON
            if let raw = String(data: data, encoding: .utf8) {
                print("📋 [PersonaService] Raw JSON: \(raw.prefix(500))")
            }
            let decoder = JSONDecoder()
            return try decoder.decode(PersonaCatalogResponse.self, from: data)
        } catch {
            print("📋 [PersonaService] Decode error: \(error)")
            throw PersonaError.decodingError(error)
        }
    }

    // MARK: - Build WebSocket URL with personas

    func buildWebSocketURL(
        host: String,
        port: Int,
        narrate: Bool,
        rounds: Int,
        model: String,
        selectedPersonas: [(persona: PersonaTemplate, model: String?)]
    ) -> URL? {

        var components = URLComponents()
        components.scheme = "ws"
        components.host   = host
        components.port   = port
        components.path   = "/ws/game"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "narrate", value: "\(narrate)"),
            URLQueryItem(name: "rounds",  value: "\(rounds)"),
            URLQueryItem(name: "model",   value: model),
        ]

        // Encode personas array sebagai JSON string
        if !selectedPersonas.isEmpty {
            let personaDicts = selectedPersonas.map { $0.persona.toQueryDict(overrideModel: $0.model) }
            if let jsonData = try? JSONSerialization.data(withJSONObject: personaDicts),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                queryItems.append(URLQueryItem(name: "personas", value: jsonString))
            }
        }

        components.queryItems = queryItems
        return components.url
    }
}
