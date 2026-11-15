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
