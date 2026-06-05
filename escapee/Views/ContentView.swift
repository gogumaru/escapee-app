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
        Group {
            switch vm.phase {
            case .idle:
                SetupView(vm: vm, settings: settings)
            case .connecting:
                ConnectingView()
                    .background(Color.black.ignoresSafeArea())
            case .setup, .playing:
                GameFeedView(vm: vm)
                    .ignoresSafeArea(edges: .bottom)
            case .finished:
                GameFeedView(vm: vm)
                    .ignoresSafeArea(edges: .bottom)
            case .error(let msg):
                ErrorView(message: msg) { vm.stopGame() }
            }
        }
    }
}
