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
    /// "Calm", "A bit itchy" or "Very itchy". Answered the next morning.
    var itch: String?
    /// No longer asked. Kept so nights saved by earlier builds still load.
    var cream: String?
    var fallMinutes: Int?
    var wakes: Int?
    var morningDate: Date?

    var hasNightCheckIn: Bool { itch != nil }
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
    private static let storySinceKey = "tonightStorySince.v1"
    private static let newStoryKey = "tonightStoryIsNew.v1"
    private static let affirmationKey = "affirmationMinutes.v1"

    /// Massage stories offered in turn, so the same one doesn't go stale.
    static let storyRotation = ["comet", "lastStar", "tummyStory"]
    static let nightsPerStory = 3

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
    /// How many nights had been logged when tonight's story was chosen.
    private var storySinceNight: Int { didSet { UserDefaults.standard.set(storySinceNight, forKey: Self.storySinceKey) } }
    /// True on the first night of a story the app picked, so Tonight can say "New story tonight".
    private(set) var isNewStoryTonight: Bool { didSet { UserDefaults.standard.set(isNewStoryTonight, forKey: Self.newStoryKey) } }
    /// How long affirmations play after the massage. 0 is off.
    var affirmationMinutes: Int { didSet { UserDefaults.standard.set(affirmationMinutes, forKey: Self.affirmationKey) } }
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
        storySinceNight = defaults.integer(forKey: Self.storySinceKey)
        isNewStoryTonight = defaults.bool(forKey: Self.newStoryKey)
        affirmationMinutes = defaults.object(forKey: Self.affirmationKey) as? Int ?? 20
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

    /// The parent picked a story themselves. It stays as tonight's story for the next few nights.
    func chooseTonightStory(_ id: String) {
        tonightStoryID = id
        storySinceNight = nights.count
        isNewStoryTonight = false
    }

    /// Records the night. Nothing is asked at bedtime; the check-in happens in the morning.
    func finishRitual(storyID: String, minutes: Int, wasFlare: Bool) {
        nights.append(NightEntry(storyID: storyID, minutes: minutes, wasFlare: wasFlare))
        // After a few nights with one story, line up the next one.
        if nights.count - storySinceNight >= Self.nightsPerStory {
            let rotation = Self.storyRotation
            let current = rotation.firstIndex(of: tonightStoryID) ?? -1
            tonightStoryID = rotation[(current + 1) % rotation.count]
            storySinceNight = nights.count
            isNewStoryTonight = true
        } else {
            isNewStoryTonight = false
        }
    }

    func saveMorning(itch: String, rating: Int, fallMinutes: Int, wakes: Int) {
        guard !nights.isEmpty else { return }
        var entry = nights[nights.count - 1]
        entry.itch = itch
        entry.rating = rating
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
