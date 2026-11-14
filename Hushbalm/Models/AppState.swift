import Foundation
import Observation

/// App-wide state that isn't subscription or night logs: onboarding answers and tonight's setup.
@MainActor
@Observable
final class AppState {
    private static let answersKey = "onboardingAnswers.v1"
    private static let completedKey = "onboardingCompleted.v1"
    private static let tonightKey = "tonightZones.v1"
    private static let dismissedKey = "paywallDismissed.v1"

    var answers: OnboardingAnswers { didSet { save() } }
    /// True once the user has finished the onboarding quiz (they then see the paywall until they subscribe).
    var hasCompletedOnboarding: Bool { didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.completedKey) } }

    /// True after the user said no to both offers; they then use the free version.
    var paywallDismissed: Bool { didSet { UserDefaults.standard.set(paywallDismissed, forKey: Self.dismissedKey) } }
    /// Show the "welcome, here's your deal" screen once, right after a purchase.
    var showWelcomeAfterPurchase = false

    // Tonight's ritual setup
    var tonightZones: [CareZone: CareState] { didSet { saveTonight() } }
    var tonightMinutes: Int = 10
    var tonightStoryID: String = StoryLibrary.otter.id

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Self.answersKey),
           let decoded = try? JSONDecoder().decode(OnboardingAnswers.self, from: data) {
            answers = decoded
        } else {
            answers = OnboardingAnswers()
        }
        hasCompletedOnboarding = defaults.bool(forKey: Self.completedKey)
        paywallDismissed = defaults.bool(forKey: Self.dismissedKey)
        if let data = defaults.data(forKey: Self.tonightKey),
           let decoded = try? JSONDecoder().decode([CareZone: CareState].self, from: data) {
            tonightZones = decoded
        } else {
            tonightZones = [:]
        }
        tonightMinutes = answers.recommendedMinutes
    }

    /// Seeds tonight's areas from the usual zones picked in onboarding.
    func seedTonightFromOnboarding() {
        var zones: [CareZone: CareState] = [:]
        for zone in answers.usualZones { zones[zone] = .dry }
        tonightZones = zones
        tonightMinutes = answers.recommendedMinutes
    }

    func cycle(_ zone: CareZone) {
        if let current = tonightZones[zone] {
            tonightZones[zone] = current.next
        } else {
            tonightZones[zone] = .dry
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(answers) {
            UserDefaults.standard.set(data, forKey: Self.answersKey)
        }
    }

    private func saveTonight() {
        if let data = try? JSONEncoder().encode(tonightZones) {
            UserDefaults.standard.set(data, forKey: Self.tonightKey)
        }
    }
}
