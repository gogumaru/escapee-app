//
//  UtilityView.swift
//  escapee
//
//  Created by Benedikta Anin on 04/06/26.
//

import SwiftUI

// MARK: - Connecting View

struct ConnectingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Connecting to backend...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wifi.slash")
                .font(.system(size: 56))
                .foregroundStyle(.red.opacity(0.7))

            VStack(spacing: 8) {
                Text("Connection Error")
                    .font(.title2.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                onRetry()
            } label: {
                Label("Back to Setup", systemImage: "arrow.left")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
