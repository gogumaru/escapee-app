//
//  StatePanelView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import SwiftUI

struct StatePanelView: View {
    let state: GameStateSnapshot?

    var body: some View {
        NavigationStack {
            Group {
                if let state {
                    List {
                        // Turn counter
                        Section {
                            Label("Turn \(state.turn)", systemImage: "clock")
                                .font(.headline)
                        }

                        // Players + their locations & inventory
                        Section {
                            ForEach(state.players) { player in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(player.name)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(player.room)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(.secondary.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    if player.inventory.isEmpty {
                                        Text("Empty inventory")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    } else {
                                        FlowLayout(items: player.inventory) { item in
                                            Text(item)
                                                .font(.caption)
                                                .padding(.horizontal, 7)
                                                .padding(.vertical, 3)
                                                .background(.blue.opacity(0.12))
                                                .foregroundStyle(.blue)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Players (\(state.players.count))")
                        }

                        // Accessible rooms
                        Section {
                            ForEach(state.accessibleRooms, id: \.self) { room in
                                Label(room, systemImage: "door.left.hand.open")
                                    .font(.subheadline)
                            }
                        } header: {
                            Text("Accessible Rooms")
                        }

                        // Objects in current rooms
                        let roomObjects = state.objects.filter { $0.room != nil }
                        if !roomObjects.isEmpty {
                            Section {
                                ForEach(roomObjects) { obj in
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(obj.id.replacingOccurrences(of: "_", with: " ").capitalized)
                                                .font(.subheadline.weight(.medium))
                                            Spacer()
                                            StateBadge(state: obj.state)
                                        }
                                        if let room = obj.room {
                                            Text(room)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            } header: {
                                Text("Room Objects (\(roomObjects.count))")
                            }
                        }
                    }
                    .listStyle(.insetGrouped)

                } else {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "map")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No state yet")
                            .foregroundStyle(.secondary)
                        Text("State panel updates once the game starts.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                }
            }
            .navigationTitle("World State")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - State Badge

struct StateBadge: View {
    let state: String

    var color: Color {
        switch state {
        case "taken":    return .gray
        case "unlocked": return .green
        case "locked":   return .red
        case "visible":  return .blue
        default:         return .orange
        }
    }

    var body: some View {
        Text(state)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Simple Flow Layout untuk inventory tags

struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        // Simple wrapping menggunakan LazyVGrid dengan flexible columns
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 6)], spacing: 6) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}
