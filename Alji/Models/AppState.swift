import Foundation
import Observation

/// One night of the ritual: what the parent told us after the massage and the next morning.
struct NightEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date = .now
    var storyID: String
    var minutes: Int
    var wasFlare = false
    var rating = 0
    /// "Calm", "A bit itchy" or "Very itchy". Nil if the night check-in was skipped.
    var itch: String?
    /// "Easy", "Some fuss" or "A battle".
    var cream: String?
    var fallMinutes: Int?
    var wakes: Int?
    var morningDate: Date?

    var hasNightCheckIn: Bool { itch != nil && cream != nil }
}

enum TonightPhase {
    case bedtime, after, morning, result
}

enum MainTab: Hashable {
    case tonight, stories, progress
}

/// App-wide state that isn't the subscription: onboarding answers, the library, and the nights logged.
@MainActor
@Observable
final class AppState {
    private static let answersKey = "onboardingAnswers.v1"
    private static let completedKey = "onboardingCompleted.v1"
    private static let dismissedKey = "paywallDismissed.v1"
    private static let nightsKey = "nights.v1"
    private static let favoritesKey = "favorites.v1"
    private static let customKey = "customStory.v1"
    private static let tonightStoryKey = "tonightStory.v1"

    var answers: OnboardingAnswers { didSet { save(answers, key: Self.answersKey) } }
    /// True once the user has finished onboarding.
    var hasCompletedOnboarding: Bool { didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.completedKey) } }
    /// True after the user said no to both offers; they then use the free version.
    var paywallDismissed: Bool { didSet { UserDefaults.standard.set(paywallDismissed, forKey: Self.dismissedKey) } }
    /// Show the "welcome, here's your deal" screen once, right after a purchase.
    var showWelcomeAfterPurchase = false

    var selectedTab: MainTab = .tonight
    var nights: [NightEntry] { didSet { save(nights, key: Self.nightsKey) } }
    var favorites: Set<String> { didSet { save(Array(favorites), key: Self.favoritesKey) } }
    var customStory: CustomStoryRequest? { didSet { save(customStory, key: Self.customKey) } }
    /// The massage story on the Tonight screen.
    var tonightStoryID: String { didSet { UserDefaults.standard.set(tonightStoryID, forKey: Self.tonightStoryKey) } }
    var voiceOn = true
    var musicOn = true
    var storyLength: StoryLength = .medium
    var massageIsShort = true

    init() {
        let defaults = UserDefaults.standard
        answers = Self.load(OnboardingAnswers.self, key: Self.answersKey) ?? OnboardingAnswers()
        hasCompletedOnboarding = defaults.bool(forKey: Self.completedKey)
        paywallDismissed = defaults.bool(forKey: Self.dismissedKey)
        nights = Self.load([NightEntry].self, key: Self.nightsKey) ?? []
        favorites = Set(Self.load([String].self, key: Self.favoritesKey) ?? [])
        customStory = Self.load(CustomStoryRequest.self, key: Self.customKey)
        tonightStoryID = defaults.string(forKey: Self.tonightStoryKey) ?? "comet"
    }

    var child: String { answers.displayChild }

    // MARK: Tonight

    /// Which state the Tonight screen shows, from the most recent night.
    func phase(now: Date = .now) -> TonightPhase {
        guard let last = nights.last else { return .bedtime }
        let calendar = Calendar.current
        if last.fallMinutes == nil {
            // The ritual is done but the morning answers aren't in yet.
            if calendar.isDate(last.date, inSameDayAs: now) && calendar.component(.hour, from: now) >= 15 { return .after }
            if now.timeIntervalSince(last.date) < 36 * 3600 { return .morning }
            return .bedtime
        }
        if let morning = last.morningDate, calendar.isDate(morning, inSameDayAs: now), calendar.component(.hour, from: now) < 15 {
            return .result
        }
        return .bedtime
    }

    func finishRitual(storyID: String, minutes: Int, wasFlare: Bool, rating: Int, itch: String?, cream: String?) {
        nights.append(NightEntry(storyID: storyID, minutes: minutes, wasFlare: wasFlare, rating: rating, itch: itch, cream: cream))
    }

    func saveMorning(itch: String?, cream: String?, fallMinutes: Int, wakes: Int) {
        guard !nights.isEmpty else { return }
        var entry = nights[nights.count - 1]
        if let itch { entry.itch = itch }
        if let cream { entry.cream = cream }
        entry.fallMinutes = fallMinutes
        entry.wakes = wakes
        entry.morningDate = .now
        nights[nights.count - 1] = entry
    }

    func toggleFavorite(_ id: String) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
    }

    // MARK: Saving

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
