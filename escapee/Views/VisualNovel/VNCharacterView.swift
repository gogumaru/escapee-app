import SwiftUI

struct VNCharacterView: View {
    let playerId: String
    let playerName: String
    let isSpeaking: Bool
    let agentColor: AgentColor

    // Nanti ganti dengan Image(playerName) kalau asset sudah ada
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                // Load gambar dari Assets.xcassets
                // Nama file harus sama dengan nama karakter (lowercase, spasi → underscore)
                // Contoh: "Alex Quinn" → "alex_quinn"
                let _ = print("🎭 Loading character: '\(assetName)' for '\(playerName)'")
                if let uiImage = UIImage(named: assetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.72)
                        .clipped()
                } else {
                    // Fallback placeholder kalau gambar belum ada
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    agentColor.bubble.opacity(0.8),
                                    agentColor.bubble.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 110, height: 200)

                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(agentColor.avatar)
                                .frame(width: 56, height: 56)
                            Text(initials)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(agentColor.name)
                        }
                        Text(playerName.components(separatedBy: " ").first ?? playerName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(agentColor.name.opacity(0.8))
                    }
                }
            }
            .opacity(isSpeaking ? 1.0 : 0.35)
            .scaleEffect(isSpeaking ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.2), value: isSpeaking)
        }
    }

    private var initials: String {
        playerName
            .split(separator: " ")
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }

    /// Convert nama ke nama file asset
    /// "Alex Quinn" → "alex_quinn"
    /// "Mara Vance" → "mara_vance"
    private var assetName: String {
        playerName
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
}
