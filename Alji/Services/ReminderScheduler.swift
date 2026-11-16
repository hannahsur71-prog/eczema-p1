import Foundation
import UserNotifications

enum ReminderScheduler {
    private static let identifier = "bedtime.reminder"

    /// Asks permission, then schedules a daily bedtime reminder. Returns whether it's allowed.
    @discardableResult
    static func enable(hour: Int, minute: Int, childName: String) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return false }
        schedule(hour: hour, minute: minute, childName: childName)
        return true
    }

    static func schedule(hour: Int, minute: Int, childName: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = "Almost bedtime"
        content.body = "Tonight's calm ritual for \(childName) is ready. Grab the moisturizer."
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

extension ReminderScheduler {
    private static let trialIdentifier = "trial.reminder"

    /// Schedules the "your trial ends soon" reminder. Asks for permission if needed.
    static func scheduleTrialReminder(trialEnds: Date, price: String) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }
        let fireDate = Calendar.current.date(byAdding: .day, value: -AppConfig.trialReminderDaysBefore, to: trialEnds) ?? trialEnds
        guard fireDate > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your free trial ends in \(AppConfig.trialReminderDaysBefore) days"
        content.body = "On \(trialEnds.formatted(date: .abbreviated, time: .omitted)) you'll be charged \(price) for the year. Cancel anytime in Settings before then."
        content.sound = .default
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        center.removePendingNotificationRequests(withIdentifiers: [trialIdentifier])
        try? await center.add(UNNotificationRequest(identifier: trialIdentifier, content: content, trigger: trigger))
    }
}

extension ReminderScheduler {
    private static let morningIdentifier = "morning.checkin"

    /// One quiet notification the morning after a ritual, asking how the night went.
    /// Only sent if notifications are already allowed; it never asks for permission at bedtime.
    static func scheduleMorningCheckIn(childName: String) async {
        let center = UNUserNotificationCenter.current()
        guard await center.notificationSettings().authorizationStatus == .authorized else { return }
        let calendar = Calendar.current
        let now = Date.now
        // The next 7:30 am. A ritual finished after midnight still gets the same morning.
        var parts = calendar.dateComponents([.year, .month, .day], from: now)
        parts.hour = 7
        parts.minute = 30
        guard var fire = calendar.date(from: parts) else { return }
        if fire <= now { fire = calendar.date(byAdding: .day, value: 1, to: fire) ?? fire }
        let content = UNMutableNotificationContent()
        content.title = "How did \(childName) sleep?"
        content.body = "Three taps, and a new star is waiting."
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire), repeats: false)
        center.removePendingNotificationRequests(withIdentifiers: [morningIdentifier])
        try? await center.add(UNNotificationRequest(identifier: morningIdentifier, content: content, trigger: trigger))
    }
}
