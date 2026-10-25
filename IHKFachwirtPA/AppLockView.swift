import SwiftUI

struct AppLockView: View {
    @Environment(AppSettingsStore.self) private var settings

    var body: some View {
        Group {
            if settings.isUnlocked || !settings.useBiometricLock {
                RootView()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "faceid")
                        .font(.system(size: 60))
                    Text("IHK Fachwirt Trainer")
                        .font(.title2.bold())
                    Text("Entsperre die App, um deinen Lernfortschritt zu öffnen.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Entsperren") {
                        Task { _ = await settings.unlock() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(32)
                .task { _ = await settings.unlock() }
            }
        }
    }
}
