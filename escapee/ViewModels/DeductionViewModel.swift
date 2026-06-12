//
//  DeductionViewModel.swift
//  escapee
//
//  Created by Benedikta Anin on 11/06/26.
//


import Foundation
import Combine

@MainActor
class DeductionViewModel: ObservableObject {

    @Published var selectedSuspect: SuspectInfo?
    @Published var showEvidence = false
    @Published var isSubmitting = false
    @Published var lastHint: String = ""
    @Published var currentPrompt: DeductionPrompt

    var prompt: DeductionPrompt { currentPrompt }
    let suspects: [SuspectInfo]
    let discoveries: [GameEvent]

    private let onSubmit: (String) -> Void

    init(
        prompt: DeductionPrompt,
        suspects: [SuspectInfo],
        discoveries: [GameEvent],
        onSubmit: @escaping (String) -> Void
    ) {
        self.currentPrompt = prompt
        self.suspects = suspects
        self.discoveries = discoveries
        self.onSubmit = onSubmit
        self.lastHint = prompt.hint
    }

    func updatePrompt(_ prompt: DeductionPrompt) {
        currentPrompt = prompt
        if !prompt.hint.isEmpty {
            lastHint = prompt.hint
        }
        isSubmitting = false
        selectedSuspect = nil
    }

    var canSubmit: Bool { selectedSuspect != nil && !isSubmitting }

    var attemptText: String? {
        guard prompt.attempt > 1 else { return nil }
        return "Attempt \(prompt.attempt) of \(prompt.maxAttempts)"
    }

    var hintText: String? {
        lastHint.isEmpty ? nil : lastHint
    }

    var accuseButtonLabel: String {
        guard let suspect = selectedSuspect else { return "Select a suspect" }
        return "Accuse \(suspect.name)"
    }

    func select(_ suspect: SuspectInfo) {
        selectedSuspect = selectedSuspect?.id == suspect.id ? nil : suspect
    }

    func submit() {
        guard let suspect = selectedSuspect else { return }
        isSubmitting = true
        onSubmit(suspect.name)
        // isSubmitting akan di-reset saat server reply
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isSubmitting = false
        }
    }
}