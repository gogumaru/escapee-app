//
//  SettingsStore.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import Foundation
import Combine

class SettingsStore: ObservableObject {

    @Published var host: String {
        didSet { UserDefaults.standard.set(host, forKey: "escapee_host") }
    }

    @Published var port: Int {
        didSet { UserDefaults.standard.set(port, forKey: "escapee_port") }
    }

    @Published var narrate: Bool {
        didSet { UserDefaults.standard.set(narrate, forKey: "escapee_narrate") }
    }

    init() {
        self.host    = UserDefaults.standard.string(forKey: "escapee_host") ?? "localhost"
        self.port    = UserDefaults.standard.integer(forKey: "escapee_port").nonZero ?? 8000
        self.narrate = UserDefaults.standard.object(forKey: "escapee_narrate") as? Bool ?? true
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}