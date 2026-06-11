//
//  DeductionView.swift
//  escapee
//
//  Created by Benedikta Anin on 11/06/26.
//


import SwiftUI

struct DeductionView: View {
    @ObservedObject var gameVM: GameViewModel
    @StateObject private var vm: DeductionViewModel

    init(gameVM: GameViewModel) {
        self.gameVM = gameVM
        let prompt = gameVM.deductionPrompt ?? DeductionPrompt(
            question: "Who is the murderer?",
            attempt: 1, maxAttempts: 3, hint: ""
        )
        self._vm = StateObject(wrappedValue: DeductionViewModel(
            prompt: prompt,
            suspects: gameVM.setup?.suspects ?? [],
            discoveries: gameVM.discoveries,
            onSubmit: { answer in gameVM.submitDeduction(answer: answer) }
        ))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Back button — sits in safe area naturally
                    HStack {
                        Button(action: { gameVM.phase = .playing }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 17))
                                .foregroundStyle(Color.white.opacity(0.5))
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.07))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    // Title at ~35% from visible height (below safe area)
                    let titleY = geo.size.height * 0.35
                    let navHeight = CGFloat(38 + 8 + 4)
                    let spacerHeight = max(0, titleY - navHeight - 60)

                    Spacer().frame(height: spacerHeight)

                    VStack(spacing: 8) {
                        Text(vm.prompt.question)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        if let attempt = vm.attemptText {
                            Text(attempt)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.3))
                        }

                        if let hint = vm.hintText {
                            Text(hint)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(red: 0.91, green: 0.49, blue: 0.42).opacity(0.85))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    // Suspect list — directly above bottom buttons
                    VStack(spacing: 8) {
                        ForEach(vm.suspects) { suspect in
                            SuspectCard(
                                suspect: suspect,
                                isSelected: vm.selectedSuspect?.id == suspect.id,
                                onTap: { vm.select(suspect) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    // Bottom buttons
                    VStack(spacing: 10) {
                        Button(action: { vm.submit() }) {
                            Text(vm.accuseButtonLabel)
                                .font(.system(size: 15, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    vm.canSubmit
                                        ? Color(red: 0.91, green: 0.49, blue: 0.42)
                                        : Color.white.opacity(0.07)
                                )
                                .foregroundStyle(
                                    vm.canSubmit
                                        ? Color.white
                                        : Color.white.opacity(0.25)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!vm.canSubmit)

                        Button(action: { vm.showEvidence = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 14))
                                Text("View evidence")
                                    .font(.system(size: 13))
                                if !vm.discoveries.isEmpty {
                                    Text("\(vm.discoveries.count)")
                                        .font(.system(size: 11))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 1)
                                        .background(Color.white.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .foregroundStyle(Color.white.opacity(0.4))
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24))
                    .padding(.top, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.98)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
        }
        .sheet(isPresented: $vm.showEvidence) {
            EvidenceSheet(discoveries: vm.discoveries)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Suspect Card

struct SuspectCard: View {
    let suspect: SuspectInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suspect.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.88))

                    if let motive = suspect.apparentMotive {
                        Text(motive)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.3))
                            .lineLimit(2)
                    }
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected
                                ? Color(red: 0.91, green: 0.49, blue: 0.42)
                                : Color.white.opacity(0.15),
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.91, green: 0.49, blue: 0.42))
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? Color(red: 0.91, green: 0.49, blue: 0.42).opacity(0.08)
                    : Color.white.opacity(0.05)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected
                            ? Color(red: 0.91, green: 0.49, blue: 0.42).opacity(0.6)
                            : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Evidence Sheet

struct EvidenceSheet: View {
    let discoveries: [GameEvent]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if discoveries.isEmpty {
                    VStack(spacing: 14) {
                        Spacer()
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("No evidence collected yet")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(discoveries) { discovery in
                                HStack(alignment: .top, spacing: 12) {
                                    Rectangle()
                                        .fill(Color(red: 0.7, green: 0.55, blue: 0.39).opacity(0.5))
                                        .frame(width: 2)
                                        .clipShape(Capsule())
                                        .padding(.vertical, 2)

                                    Text(discovery.displayText)
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                        .lineSpacing(4)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Deduction — suspect selected") {
    _DeductionPreview(selectedIndex: 1)
}

#Preview("Deduction — nothing selected") {
    _DeductionPreview(selectedIndex: nil)
}

private struct _DeductionPreview: View {
    let selectedIndex: Int?

    private let suspects: [SuspectInfo] = [
        SuspectInfo(name: "Jonathan Hale",
                    connectionToVictim: "Financial dependent",
                    apparentMotive: "Eleanor Marsh was planning to cut Jonathan's financial support, putting him at risk of bankrup..."),
        SuspectInfo(name: "Isabella Finch",
                    connectionToVictim: "Business partner",
                    apparentMotive: "Eleanor Marsh was planning to reveal that Isabella had been embezzling funds."),
        SuspectInfo(name: "Richard Langley",
                    connectionToVictim: "Art dealer",
                    apparentMotive: "Eleanor Marsh threatened to expose his illegal art dealings.")
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Circle())
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    let spacerHeight = max(0, geo.size.height * 0.35 - CGFloat(38 + 8 + 4) - 60)
                    Spacer().frame(height: spacerHeight)

                    Text("Who murdered the victim?")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    Spacer()

                    VStack(spacing: 8) {
                        ForEach(Array(suspects.enumerated()), id: \.offset) { i, suspect in
                            let isSelected = selectedIndex == i
                            HStack(alignment: .center, spacing: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(suspect.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.white.opacity(0.88))
                                    if let motive = suspect.apparentMotive {
                                        Text(motive)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.white.opacity(0.3))
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .strokeBorder(isSelected ? Color(red: 0.91, green: 0.49, blue: 0.42) : Color.white.opacity(0.15), lineWidth: isSelected ? 1.5 : 0.5)
                                        .frame(width: 22, height: 22)
                                    if isSelected {
                                        Circle().fill(Color(red: 0.91, green: 0.49, blue: 0.42)).frame(width: 22, height: 22)
                                        Image(systemName: "checkmark").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(isSelected ? Color(red: 0.91, green: 0.49, blue: 0.42).opacity(0.08) : Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color(red: 0.91, green: 0.49, blue: 0.42).opacity(0.6) : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                    VStack(spacing: 10) {
                        let canSubmit = selectedIndex != nil
                        Text(canSubmit ? "Accuse \(suspects[selectedIndex!].name)" : "Accuse")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSubmit ? Color(red: 0.91, green: 0.49, blue: 0.42) : Color.white.opacity(0.07))
                            .foregroundStyle(canSubmit ? Color.white : Color.white.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        HStack(spacing: 6) {
                            Image(systemName: "doc.text").font(.system(size: 14))
                            Text("View evidence").font(.system(size: 13))
                            Text("8").font(.system(size: 11)).padding(.horizontal, 7).padding(.vertical, 1).background(Color.white.opacity(0.12)).clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(Color.white.opacity(0.4))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24))
                    .padding(.top, 12)
                    .background(LinearGradient(colors: [Color.clear, Color.black.opacity(0.98)], startPoint: .top, endPoint: .bottom))
                }
            }
        }
    }
}