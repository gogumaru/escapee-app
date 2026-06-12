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
    @StateObject private var vnVM = VNGameViewModel()

    var body: some View {
        Group {
            switch vm.phase {
            case .idle:
                SetupView(vm: vm, settings: settings, vnVM: vnVM)
            case .connecting:
                ConnectingView()
                    .background(Color.black.ignoresSafeArea())
            case .setup, .playing:
                VNGameView(gameVM: vm, vnVM: vnVM)
                    .ignoresSafeArea()
            case .finished:
                ResultView(vm: vm)
            case .deduction:
                DeductionView(gameVM: vm, vnVM: vnVM)
            case .error(let msg):
                ErrorView(message: msg) { vm.stopGame() }
            }
        }
    }
}
