//
//  ReminderManager.swift
//  Math Camp
//

import Foundation
import Observation
import UserNotifications

/// Schedules one repeating local notification a day at the time the user picks.
@MainActor
@Observable
final class ReminderManager {
    static let shared = ReminderManager()

    private static let enabledKey = "reminder.enabled"
    private static let minutesKey = "reminder.minutesSinceMidnight"
    private static let requestIdentifier = "daily-reminder"

    /// What happened when the user tried to switch the reminder on.
    enum EnableResult {
        case enabled
        /// Notifications are blocked in Settings; the system will not ask again.
        case denied
        /// The user just declined the system prompt; no need to explain anything yet.
        case declinedPrompt
    }

    private(set) var isEnabled: Bool
    /// Minutes since midnight; 18:00 by default.
    private(set) var minutesSinceMidnight: Int

    private let defaults = UserDefaults.standard
    private let center = UNUserNotificationCenter.current()

    private init() {
        isEnabled = defaults.bool(forKey: Self.enabledKey)
        minutesSinceMidnight = defaults.object(forKey: Self.minutesKey) as? Int ?? 18 * 60
    }

    /// The reminder time as a `Date` today, for a `DatePicker`.
    var time: Date {
        let components = DateComponents(hour: minutesSinceMidnight / 60, minute: minutesSinceMidnight % 60)
        return Calendar.current.date(from: components) ?? .now
    }

    /// Switches the reminder on. Asks for permission the first time; if the user has
    /// already refused, returns `.denied` so the UI can point them to Settings.
    func enable() async -> EnableResult {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            setEnabled(false)
            return .denied
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else {
                setEnabled(false)
                return .declinedPrompt
            }
        default:
            break
        }
        setEnabled(true)
        await schedule()
        return .enabled
    }

    func disable() {
        setEnabled(false)
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])
    }

    func setTime(_ date: Date) async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        minutesSinceMidnight = (components.hour ?? 18) * 60 + (components.minute ?? 0)
        defaults.set(minutesSinceMidnight, forKey: Self.minutesKey)
        if isEnabled { await schedule() }
    }

    /// Turns the reminder off when permission was withdrawn in system Settings,
    /// and refreshes the text after an in-app language change.
    func refresh() async {
        guard isEnabled else { return }
        let status = await center.notificationSettings().authorizationStatus
        if status == .denied {
            disable()
        } else {
            await schedule()
        }
    }

    private func setEnabled(_ value: Bool) {
        isEnabled = value
        defaults.set(value, forKey: Self.enabledKey)
    }

    private func schedule() async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])

        let content = UNMutableNotificationContent()
        // Resolved with the in-app locale, so the text follows the language picker.
        let locale = LanguageManager.activeLocale
        content.title = String(localized: LocalizedStringResource("reminder.notification.title", locale: locale))
        content.body = String(localized: LocalizedStringResource("reminder.notification.body", locale: locale))
        content.sound = .default

        let components = DateComponents(hour: minutesSinceMidnight / 60, minute: minutesSinceMidnight % 60)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.requestIdentifier, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
