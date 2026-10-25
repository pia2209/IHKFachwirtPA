import AuthenticationServices
import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppSettingsStore {
    private enum Key {
        static let appleUserID = "settings.appleUserID"
        static let appleName = "settings.appleName"
        static let biometric = "settings.biometricLock"
        static let reminder = "settings.dailyReminder"
        static let hour = "settings.dailyReminderHour"
    }

    private let defaults = UserDefaults.standard

    var isUnlocked: Bool
    var appleUserID: String? { didSet { store(appleUserID, forKey: Key.appleUserID) } }
    var appleDisplayName: String? { didSet { store(appleDisplayName, forKey: Key.appleName) } }
    var useBiometricLock: Bool { didSet { defaults.set(useBiometricLock, forKey: Key.biometric) } }
    var dailyReminderEnabled: Bool { didSet { defaults.set(dailyReminderEnabled, forKey: Key.reminder) } }
    var dailyReminderHour: Int { didSet { defaults.set(dailyReminderHour, forKey: Key.hour) } }

    var isSignedInWithApple: Bool { appleUserID != nil }

    init() {
        appleUserID = defaults.string(forKey: Key.appleUserID)
        appleDisplayName = defaults.string(forKey: Key.appleName)
        useBiometricLock = defaults.bool(forKey: Key.biometric)
        dailyReminderEnabled = defaults.bool(forKey: Key.reminder)
        dailyReminderHour = defaults.object(forKey: Key.hour) as? Int ?? 18
        isUnlocked = !useBiometricLock
    }

    func signOutApple() {
        appleUserID = nil
        appleDisplayName = nil
    }

    func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        appleUserID = credential.user
        if let components = credential.fullName {
            let name = PersonNameComponentsFormatter().string(from: components)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                appleDisplayName = name
            }
        }
    }

    func refreshAppleCredentialState() {
        guard let userID = appleUserID else { return }
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { [weak self] state, _ in
            guard state == .revoked || state == .notFound else { return }
            Task { @MainActor in
                self?.signOutApple()
            }
        }
    }

    func lock() {
        isUnlocked = false
    }

    private func store(_ value: String?, forKey key: String) {
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    func unlock() async -> Bool {
        guard useBiometricLock else {
            isUnlocked = true
            return true
        }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isUnlocked = true
            return true
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Entsperre deinen Lernfortschritt."
            )
            isUnlocked = success
            return success
        } catch {
            isUnlocked = false
            return false
        }
    }
}
