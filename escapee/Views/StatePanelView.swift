//
//  StatePanelView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import SwiftUI

struct StatePanelView: View {
    let state: GameStateSnapshot?
    @State private var selectedTab: StateTab = .map

    enum StateTab { case list, map }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment control
                Picker("", selection: $selectedTab) {
                    Text("List").tag(StateTab.list)
                    Text("Map").tag(StateTab.map)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()

                if let state {
                    switch selectedTab {
                    case .list: ListView(state: state)
                    case .map:  MapView(state: state)
                    }
                } else {
                    EmptyStateView()
                }
            }
            .navigationTitle("World State")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - List View

struct ListView: View {
    let state: GameStateSnapshot

    // Objects di room yang dihuni agent
    private var occupiedRooms: Set<String> {
        Set(state.players.map { $0.room })
    }

    private var visibleObjects: [ObjectState] {
        state.objects.filter { obj in
            guard let room = obj.room else { return false }
            return occupiedRooms.contains(room)
        }
    }

    var body: some View {
        List {
            // Turn
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("current turn")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("\(state.turn)")
                            .font(.system(size: 28, weight: .medium))
                    }
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Agents
            Section("Agents") {
                ForEach(state.players) { player in
                    HStack(alignment: .top, spacing: 10) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(AgentColor.from(player.id).bubble)
                                .frame(width: 30, height: 30)
                            Text(initials(player.name))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(AgentColor.from(player.id).name)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text(player.name)
                                .font(.system(size: 13, weight: .medium))

                            if player.inventory.isEmpty {
                                Text("empty inventory")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            } else {
                                FlowTagLayout(items: player.inventory) { item in
                                    Text(item.replacingOccurrences(of: "_", with: " "))
                                        .font(.system(size: 11))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 2)
                                        .background(.secondary.opacity(0.1))
                                        .foregroundStyle(.secondary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Objects
            if !visibleObjects.isEmpty {
                Section("Objects nearby") {
                    ForEach(visibleObjects) { obj in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: objectIcon(obj))
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(obj.id.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.system(size: 13, weight: .medium))
                                Text(obj.description)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()
                            ObjectStateBadge(state: obj.state)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ")
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }

    private func objectIcon(_ obj: ObjectState) -> String {
        if !obj.takeable { return "door.left.hand.closed" }
        return "cube"
    }
}

// MARK: - Map View

struct MapView: View {
    let state: GameStateSnapshot

    private func agentsIn(_ roomId: String) -> [PlayerState] {
        state.players.filter { $0.room == roomId }
    }

    private func isAccessible(_ roomId: String) -> Bool {
        state.accessibleRooms.contains(roomId)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Turn \(state.turn) · \(state.rooms.count) rooms")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(state.rooms, id: \.self) { roomId in
                        RoomCard(
                            roomId: roomId,
                            agents: agentsIn(roomId),
                            isAccessible: isAccessible(roomId)
                        )
                    }
                }

                // Legend
                HStack(spacing: 16) {
                    LegendItem(color: .blue.opacity(0.15), label: "accessible")
                    LegendItem(color: .secondary.opacity(0.08), label: "locked", dimmed: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
            .padding(16)
        }
    }
}

// MARK: - Room Card

struct RoomCard: View {
    let roomId: String
    let agents: [PlayerState]
    let isAccessible: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(roomId.replacingOccurrences(of: "_", with: " "))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isAccessible ? .primary : .secondary)

            if agents.isEmpty {
                Text("empty")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(agents) { agent in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(AgentColor.from(agent.id).name)
                                .frame(width: 6, height: 6)
                            Text(agent.name)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            Text(isAccessible ? "accessible" : "locked")
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(isAccessible ? Color.blue.opacity(0.12) : Color.secondary.opacity(0.1))
                .foregroundStyle(isAccessible ? .blue : .secondary)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        .padding(12)
        .background(isAccessible ? Color.blue.opacity(0.06) : Color.secondary.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isAccessible ? Color.blue.opacity(0.25) : Color.secondary.opacity(0.15),
                    lineWidth: isAccessible ? 1 : 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isAccessible ? 1.0 : 0.5)
    }
}

// MARK: - Object State Badge

struct ObjectStateBadge: View {
    let state: String

    var color: Color {
        switch state {
        case "unlocked", "visible": return .green
        case "locked", "locked_bolt": return .red
        case "taken": return .secondary
        default: return .orange
        }
    }

    var body: some View {
        Text(state.replacingOccurrences(of: "_", with: " "))
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String
    var dimmed: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
                .opacity(dimmed ? 0.5 : 1)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No state yet")
                .foregroundStyle(.secondary)
            Text("Updates once the game starts.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
