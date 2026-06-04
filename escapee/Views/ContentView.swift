//
//  ContentView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//


import SwiftUI

struct ContentView: View {

    @StateObject private var vm = GameViewModel()
    @StateObject private var settings = SettingsStore()

    var body: some View {
        NavigationStack {
            Group {
                switch vm.phase {
                case .idle:
                    SetupView(vm: vm, settings: settings)
                case .connecting:
                    ConnectingView()
                case .setup, .playing:
                    GameFeedView(vm: vm)
                case .finished:
                    ResultView(vm: vm)
                case .error(let msg):
                    ErrorView(message: msg) {
                        vm.stopGame()
                    }
                }
            }
            .navigationTitle(vm.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if vm.isConnected {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Stop") {
                            vm.stopGame()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}