//
//  AgentColor.swift
//  escapee
//
//  Created by Benedikta Anin on 09/06/26.
//


import SwiftUI

struct AgentColor {
    let bubble: Color
    let text: Color
    let name: Color
    let avatar: Color

    static func from(_ playerId: String?) -> AgentColor {
        guard let id = playerId else { return .system }
        let seed = (id.unicodeScalars.first?.value ?? 0) + UInt32(id.count)
        let palette: [AgentColor] = [.blue, .purple, .teal, .amber]
        let index = Int(seed) % palette.count
        return palette[index]
    }

    // Biru
    static let blue = AgentColor(
        bubble: Color(light: Color(red: 0.87, green: 0.93, blue: 1.0),
                      dark:  Color(red: 0.05, green: 0.13, blue: 0.28)),
        text:   Color(light: Color(red: 0.05, green: 0.20, blue: 0.45),
                      dark:  Color(red: 0.86, green: 0.93, blue: 1.0)),
        name:   Color(light: Color(red: 0.15, green: 0.38, blue: 0.85),
                      dark:  Color(red: 0.55, green: 0.72, blue: 1.0)),
        avatar: Color(light: Color(red: 0.71, green: 0.83, blue: 0.96),
                      dark:  Color(red: 0.23, green: 0.38, blue: 0.62))
    )

    // Ungu
    static let purple = AgentColor(
        bubble: Color(light: Color(red: 0.93, green: 0.90, blue: 1.0),
                      dark:  Color(red: 0.12, green: 0.06, blue: 0.24)),
        text:   Color(light: Color(red: 0.30, green: 0.15, blue: 0.55),
                      dark:  Color(red: 0.93, green: 0.88, blue: 1.0)),
        name:   Color(light: Color(red: 0.50, green: 0.25, blue: 0.85),
                      dark:  Color(red: 0.78, green: 0.55, blue: 1.0)),
        avatar: Color(light: Color(red: 0.81, green: 0.75, blue: 0.97),
                      dark:  Color(red: 0.37, green: 0.20, blue: 0.55))
    )

    // Teal
    static let teal = AgentColor(
        bubble: Color(light: Color(red: 0.86, green: 0.97, blue: 0.93),
                      dark:  Color(red: 0.04, green: 0.18, blue: 0.16)),
        text:   Color(light: Color(red: 0.04, green: 0.32, blue: 0.25),
                      dark:  Color(red: 0.86, green: 0.97, blue: 0.94)),
        name:   Color(light: Color(red: 0.06, green: 0.52, blue: 0.42),
                      dark:  Color(red: 0.28, green: 0.82, blue: 0.68)),
        avatar: Color(light: Color(red: 0.62, green: 0.88, blue: 0.80),
                      dark:  Color(red: 0.10, green: 0.40, blue: 0.35))
    )

    // Amber
    static let amber = AgentColor(
        bubble: Color(light: Color(red: 1.0,  green: 0.95, blue: 0.82),
                      dark:  Color(red: 0.22, green: 0.15, blue: 0.03)),
        text:   Color(light: Color(red: 0.40, green: 0.25, blue: 0.00),
                      dark:  Color(red: 1.0,  green: 0.93, blue: 0.78)),
        name:   Color(light: Color(red: 0.65, green: 0.42, blue: 0.00),
                      dark:  Color(red: 0.95, green: 0.72, blue: 0.28)),
        avatar: Color(light: Color(red: 0.98, green: 0.78, blue: 0.46),
                      dark:  Color(red: 0.50, green: 0.35, blue: 0.05))
    )

    // System — abu
    static let system = AgentColor(
        bubble: Color.secondary.opacity(0.08),
        text:   Color.secondary,
        name:   Color.secondary,
        avatar: Color.secondary.opacity(0.2)
    )
}

// MARK: - Color light/dark helper

extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
