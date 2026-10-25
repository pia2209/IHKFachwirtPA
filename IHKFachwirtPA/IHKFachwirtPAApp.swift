import SwiftUI

@main
struct IHKFachwirtPAApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var learningStore = LearningStore()
    @State private var settings = AppSettingsStore()

    var body: some Scene {
        WindowGroup {
            AppLockView()
                .environment(learningStore)
                .environment(settings)
                .task { settings.refreshAppleCredentialState() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                learningStore.rollDayIfNeeded()
            }
        }
    }
}
