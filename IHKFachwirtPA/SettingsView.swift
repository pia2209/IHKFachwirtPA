import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(AppSettingsStore.self) private var settings
    @State private var statusMessage: String?

    var body: some View {
        Form {
            accountSection
            securitySection
            syncSection
            learningSection
            inviteSection
            aboutSection
        }
        .navigationTitle("Einstellungen")
        .alert("Hinweis", isPresented: Binding(get: { statusMessage != nil }, set: { if !$0 { statusMessage = nil } })) {
            Button("OK", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if settings.isSignedInWithApple {
                LabeledContent("Angemeldet", value: settings.appleDisplayName ?? "Apple Account")
                Button("Apple-Anmeldung trennen", role: .destructive) { settings.signOutApple() }
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName]
                } onCompletion: { result in
                    settings.handleAppleAuthorization(result)
                    switch result {
                    case .success:
                        statusMessage = settings.isSignedInWithApple
                            ? "Apple-Anmeldung wurde auf diesem Gerät gespeichert."
                            : "Die Anmeldung konnte nicht gespeichert werden."
                    case .failure(let error):
                        let nsError = error as NSError
                        if nsError.domain == ASAuthorizationErrorDomain && nsError.code == ASAuthorizationError.canceled.rawValue {
                            return
                        }
                        statusMessage = "Die Apple-Anmeldung konnte nicht abgeschlossen werden."
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 46)
            }
            Text("Name und Anmeldung bleiben auf diesem Gerät. Die App hat keinen eigenen Server.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var securitySection: some View {
        Section("Sicherheit") {
            Toggle("App mit Face ID / Gerätecode schützen", isOn: Binding(
                get: { settings.useBiometricLock },
                set: { newValue in
                    settings.useBiometricLock = newValue
                    if newValue { settings.lock() }
                }
            ))
            Text("Die App erhält keine biometrischen Daten. Die Prüfung erfolgt durch das System.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var syncSection: some View {
        Section("Kalender & Erinnerungen") {
            if let examDate = store.examDate {
                Button("Prüfungstermin in Kalender") {
                    Task {
                        do {
                            try await AppleIntegrationService.shared.addExamDateToCalendar(date: examDate)
                            statusMessage = "Prüfungstermin wurde zum Kalender hinzugefügt."
                        } catch { statusMessage = error.localizedDescription }
                    }
                }
            } else {
                Text("Lege zuerst einen Prüfungstermin im Lernplan fest.")
                    .foregroundStyle(.secondary)
            }

            Button("Smart-Lernplan zu Erinnerungen") {
                Task {
                    do {
                        try await AppleIntegrationService.shared.createStudyReminders(
                            topics: Array(store.weakestTopics.prefix(5)),
                            examDate: store.examDate
                        )
                        statusMessage = "Die nächsten Lernblöcke wurden als Erinnerungen angelegt."
                    } catch { statusMessage = error.localizedDescription }
                }
            }

            Toggle("Tägliche Lernerinnerung", isOn: Binding(
                get: { settings.dailyReminderEnabled },
                set: { enabled in
                    settings.dailyReminderEnabled = enabled
                    Task {
                        if enabled {
                            do {
                                try await AppleIntegrationService.shared.scheduleDailyLearningReminder(hour: settings.dailyReminderHour)
                            } catch {
                                settings.dailyReminderEnabled = false
                                statusMessage = error.localizedDescription
                            }
                        } else {
                            AppleIntegrationService.shared.removeDailyLearningReminder()
                        }
                    }
                }
            ))

            if settings.dailyReminderEnabled {
                Picker("Uhrzeit", selection: Binding(
                    get: { settings.dailyReminderHour },
                    set: { hour in
                        settings.dailyReminderHour = hour
                        Task { try? await AppleIntegrationService.shared.scheduleDailyLearningReminder(hour: hour) }
                    }
                )) {
                    ForEach(6..<23, id: \.self) { hour in Text(String(format: "%02d:00", hour)).tag(hour) }
                }
            }
        }
    }

    private var learningSection: some View {
        Section("Intelligentes Lernen") {
            LabeledContent("Aktueller Fokus", value: store.weakestTopics.first?.title ?? "Noch keine Daten")
            LabeledContent("Fällige Karten", value: "\(store.dueFlashcards.count)")
            LabeledContent("Fehlerfragen", value: "\(store.wrongQuestions.count)")
            if let days = store.daysUntilExam {
                LabeledContent("Bis zur Prüfung", value: "\(days) Tage")
            }
            Text("Der Smart-Lernplan priorisiert automatisch schwache Themen, fällige Karteikarten und Fehlerfragen.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var inviteSection: some View {
        Section("Freunde") {
            ShareLink(
                item: "Ich lerne mit dem IHK Fachwirt Trainer für den Technischen Fachwirt. Lern mit mir!",
                subject: Text("IHK Fachwirt Trainer"),
                message: Text("Technischer Fachwirt gemeinsam lernen")
            ) {
                Label("Freunde einladen", systemImage: "person.crop.circle.badge.plus")
            }

            ShareLink(item: progressSummary) {
                Label("Lernfortschritt teilen", systemImage: "square.and.arrow.up")
            }
        }
    }

    private var aboutSection: some View {
        Section("Lernen") {
            NavigationLink("25-Minuten-Fokus-Timer") { FocusTimerView() }
            NavigationLink("Persönliche Lernempfehlung") { SmartStudyView() }
            LabeledContent(
                "Version",
                value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
            )
            Text("Unabhängiger Lerntrainer für die Fortbildungsprüfung zum Technischen Fachwirt. Keine offizielle App der IHK.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var progressSummary: String {
        "IHK Fachwirt Trainer – mein Lernstand: \(store.totalAnswered) Aufgaben, \(Int(store.accuracy * 100)) % Trefferquote, \(store.streak)-Tage-Streak."
    }
}

struct SmartStudyView: View {
    @Environment(LearningStore.self) private var store

    var body: some View {
        List {
            Section("Heute priorisieren") {
                if !store.wrongQuestions.isEmpty { Label("\(store.wrongQuestions.count) Fehlerfragen wiederholen", systemImage: "exclamationmark.triangle") }
                if !store.dueFlashcards.isEmpty { Label("\(store.dueFlashcards.count) Karteikarten wiederholen", systemImage: "rectangle.stack") }
                ForEach(store.weakestTopics.prefix(3)) { topic in
                    Label(topic.title, systemImage: topic.icon)
                }
            }
            Section("Empfohlener Ablauf") {
                Text("1. 10 Minuten Fehlerfragen")
                Text("2. 15 Minuten schwächstes Thema")
                Text("3. Fällige Karteikarten")
                Text("4. Zum Abschluss 5 Quizfragen")
            }
        }
        .navigationTitle("Smart-Lernplan")
    }
}

struct FocusTimerView: View {
    @State private var remaining = 25 * 60
    @State private var running = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "timer")
                .font(.system(size: 52))
            Text(timeText)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("Konzentrierter Lernblock")
                .foregroundStyle(.secondary)
            HStack {
                Button(running ? "Pause" : "Start") { running.toggle() }
                    .buttonStyle(.borderedProminent)
                Button("Zurücksetzen") {
                    running = false
                    remaining = 25 * 60
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Fokus-Timer")
        .task(id: running) {
            while running && remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                remaining -= 1
            }
            if remaining == 0 { running = false }
        }
        .sensoryFeedback(.success, trigger: remaining == 0)
    }

    private var timeText: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }
}
