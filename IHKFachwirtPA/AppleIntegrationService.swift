import EventKit
import Foundation
import UserNotifications

@MainActor
final class AppleIntegrationService {
    static let shared = AppleIntegrationService()

    private static let dailyReminderID = "fachwirt.daily-learning"
    private static let examEventTitle = "Technischer Fachwirt – Prüfung"

    private init() {}

    func addExamDateToCalendar(date: Date) async throws {
        let store = EKEventStore()
        let granted = try await store.requestFullAccessToEvents()
        guard granted else { throw AppleIntegrationError.calendarDenied }
        guard let calendar = store.defaultCalendarForNewEvents else { throw AppleIntegrationError.noCalendar }

        let day = Calendar.current.startOfDay(for: date)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
        let existing = store.events(matching: store.predicateForEvents(withStart: day, end: nextDay, calendars: nil))
        if existing.contains(where: { $0.title == Self.examEventTitle }) { return }

        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = Self.examEventTitle
        event.isAllDay = true
        event.startDate = day
        event.endDate = nextDay
        event.notes = "Eingetragen aus dem Fachwirt Trainer."
        do {
            try store.save(event, span: .thisEvent)
        } catch {
            throw AppleIntegrationError.failed("Der Termin konnte nicht im Kalender gespeichert werden.")
        }
    }

    func createStudyReminders(topics: [LearningTopic], examDate: Date?) async throws {
        let store = EKEventStore()
        let granted = try await store.requestFullAccessToReminders()
        guard granted else { throw AppleIntegrationError.remindersDenied }
        guard let calendar = store.defaultCalendarForNewReminders() else { throw AppleIntegrationError.noReminderList }

        let existing = await reminderTitles(in: store)
        let start = Calendar.current.startOfDay(for: .now)
        var didSave = false
        for (offset, topic) in topics.enumerated() {
            let title = "Lernen: \(topic.title)"
            guard !existing.contains(title) else { continue }
            let reminder = EKReminder(eventStore: store)
            reminder.calendar = calendar
            reminder.title = title
            if let due = Calendar.current.date(byAdding: .day, value: offset, to: start) {
                var components = Calendar.current.dateComponents([.year, .month, .day], from: due)
                components.hour = 18
                reminder.dueDateComponents = components
            }
            if let examDate {
                reminder.notes = "Prüfung am \(examDate.formatted(date: .abbreviated, time: .omitted)). Angelegt vom Fachwirt Trainer."
            } else {
                reminder.notes = "Angelegt vom Fachwirt Trainer."
            }
            do {
                try store.save(reminder, commit: false)
                didSave = true
            } catch {
                throw AppleIntegrationError.failed("Die Erinnerung konnte nicht angelegt werden.")
            }
        }
        if didSave {
            do {
                try store.commit()
            } catch {
                throw AppleIntegrationError.failed("Die Erinnerungen konnten nicht gespeichert werden.")
            }
        }
    }

    func scheduleDailyLearningReminder(hour: Int) async throws {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        let granted: Bool
        switch status {
        case .notDetermined:
            granted = try await center.requestAuthorization(options: [.alert, .sound])
        case .authorized, .provisional, .ephemeral:
            granted = true
        default:
            granted = false
        }
        guard granted else { throw AppleIntegrationError.notificationsDenied }

        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderID])
        let content = UNMutableNotificationContent()
        content.title = "Zeit zum Lernen"
        content.body = "Dein Tagesziel für den Technischen Fachwirt wartet."
        content.sound = .default

        var components = DateComponents()
        components.hour = min(23, max(0, hour))
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.dailyReminderID, content: content, trigger: trigger)
        try await center.add(request)
    }

    func removeDailyLearningReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderID])
    }

    private func reminderTitles(in store: EKEventStore) async -> Set<String> {
        let predicate = store.predicateForReminders(in: nil)
        return await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: Set((reminders ?? []).compactMap(\.title)))
            }
        }
    }
}

enum AppleIntegrationError: LocalizedError {
    case calendarDenied
    case remindersDenied
    case notificationsDenied
    case noCalendar
    case noReminderList
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .calendarDenied:
            return "Kein Zugriff auf den Kalender. Du kannst ihn in den iOS-Einstellungen erlauben."
        case .remindersDenied:
            return "Kein Zugriff auf Erinnerungen. Du kannst ihn in den iOS-Einstellungen erlauben."
        case .notificationsDenied:
            return "Mitteilungen sind nicht erlaubt. Aktiviere sie in den iOS-Einstellungen für den Fachwirt Trainer."
        case .noCalendar:
            return "Auf diesem Gerät ist kein Kalender zum Eintragen verfügbar."
        case .noReminderList:
            return "Auf diesem Gerät ist keine Erinnerungsliste verfügbar."
        case .failed(let message):
            return message
        }
    }
}
