//
//  GameFeedView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import SwiftUI

struct GameFeedView: View {

    @ObservedObject var vm: GameViewModel
    @State private var showStatePanel = false
    @State private var autoScroll = true

    var body: some View {
        VStack(spacing: 0) {

            // Filter bar
            FilterBar(active: vm.activeFilter) { filter in
                vm.setFilter(filter)
                // Reset auto-scroll saat ganti filter
                autoScroll = true
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Feed
            if vm.filteredEvents.isEmpty {
                WaitingView()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(vm.filteredEvents) { event in
                                EventRowView(event: event)
                                    .id(event.id)
                            }
                            // Anchor invisible di bawah untuk scroll target
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding()
                    }
                    .onChange(of: vm.filteredEvents.count) {
                        guard autoScroll else { return }
                        // Tanpa animasi supaya tidak naik-turun
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                    .onChange(of: vm.activeFilter) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            Divider()

            // Bottom status bar
            StatusBar(vm: vm, onToggleState: {
                showStatePanel.toggle()
            })
        }
        .sheet(isPresented: $showStatePanel) {
            StatePanelView(state: vm.currentState)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Filter Bar

struct FilterBar: View {
    let active: FeedFilter
    let onSelect: (FeedFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    Button(filter.rawValue) {
                        onSelect(filter)
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        active == filter
                            ? Color.blue
                            : Color.secondary.opacity(0.12)
                    )
                    .foregroundStyle(active == filter ? .white : .primary)
                    .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Status Bar

struct StatusBar: View {
    @ObservedObject var vm: GameViewModel
    let onToggleState: () -> Void

    var body: some View {
        HStack {
            // Connection dot + status
            Circle()
                .fill(vm.isConnected ? .green : .red)
                .frame(width: 8, height: 8)
            Text(vm.connectionLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(vm.turnCount) turns")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Tombol Play Again muncul saat game selesai
            if !vm.isConnected && vm.hasEvents {
                Button {
                    vm.stopGame()
                } label: {
                    Label("Play Again", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            Button {
                onToggleState()
            } label: {
                Label("State", systemImage: "map")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Waiting View

struct WaitingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
            Text("Waiting for agents...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
