import Foundation

/// Everything the Progress tab shows, worked out from the family's own check-ins. Nothing here is example data.
struct ProgressStats {
    let nights: [NightEntry]
    private let calendar = Calendar.current

    init(nights: [NightEntry]) {
        self.nights = nights.sorted { $0.date < $1.date }
    }

    /// One week of the ritual, counted from the first night.
    struct Week {
        let number: Int
        let fallMinutes: Double?
        let itch: Double?
    }

    /// Calm 1 · A bit itchy 2 · Very itchy 3.
    static func itchScore(_ answer: String?) -> Double? {
        switch answer {
        case "Calm": return 1
        case "A bit itchy": return 2
        case "Very itchy": return 3
        default: return nil
        }
    }

    private static func average(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    /// The most recent four weeks that have any nights in them.
    var weeks: [Week] {
        guard let first = nights.first else { return [] }
        let start = calendar.startOfDay(for: first.date)
        let grouped = Dictionary(grouping: nights) { entry in
            (calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: entry.date)).day ?? 0) / 7
        }
        return grouped.keys.sorted().suffix(4).map { key in
            let entries = grouped[key] ?? []
            return Week(number: key + 1,
                        fallMinutes: Self.average(entries.compactMap { $0.fallMinutes.map(Double.init) }),
                        itch: Self.average(entries.compactMap { Self.itchScore($0.itch) }))
        }
    }

    // MARK: Time back

    /// The first week's average minutes to fall asleep: what later nights are compared with.
    var baselineFall: Double? {
        guard let first = nights.first else { return nil }
        let end = calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: first.date)) ?? first.date
        return Self.average(nights.filter { $0.date < end }.compactMap { $0.fallMinutes.map(Double.init) })
    }

    /// Minutes saved over the last 30 days, compared with the first week. Never negative.
    var minutesBackThisMonth: Int? {
        guard let baseline = baselineFall else { return nil }
        let since = calendar.date(byAdding: .day, value: -30, to: .now) ?? .now
        let recent = nights.filter { $0.date >= since }.compactMap(\.fallMinutes)
        guard recent.count >= 2 else { return nil }
        return max(0, Int(recent.reduce(0.0) { $0 + (baseline - Double($1)) }.rounded()))
    }

    var fallWeeks: [Week] { weeks.filter { $0.fallMinutes != nil } }

    /// How many fewer minutes bedtime takes in the latest week than in the first.
    var minutesFasterThisWeek: Int? {
        let list = fallWeeks
        guard list.count >= 2, let first = list.first?.fallMinutes, let last = list.last?.fallMinutes else { return nil }
        return Int((first - last).rounded())
    }

    static func hours(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = Int((Double(minutes % 60) / 5).rounded()) * 5
        if hours == 0 { return "\(rest) min" }
        return "\(hours) hr" + (rest > 0 ? " \(rest) min" : "")
    }

    // MARK: Itch

    var itchWeeks: [Week] { weeks.filter { $0.itch != nil } }

    /// Change in average night itch from the first shown week to the latest, in percent. Negative is better.
    var itchChangePercent: Int? {
        let list = itchWeeks
        guard list.count >= 2, let first = list.first?.itch, let last = list.last?.itch, first > 0 else { return nil }
        return Int(((last - first) / first * 100).rounded())
    }

    // MARK: This month

    struct Day: Identifiable {
        let id: Int
        /// nil: no ritual that day.
        let entry: NightEntry?
    }

    var monthDays: [Day] {
        let now = Date.now
        let count = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        return (1...count).map { day in
            Day(id: day, entry: nights.last {
                calendar.isDate($0.date, equalTo: now, toGranularity: .month) && calendar.component(.day, from: $0.date) == day
            })
        }
    }

    private var last28: [NightEntry] {
        let since = calendar.date(byAdding: .day, value: -28, to: .now) ?? .now
        return nights.filter { $0.date >= since }
    }

    var nightsLast28: Int { last28.count }
    var minutesLast28: Int { last28.reduce(0) { $0 + $1.minutes } }
    var checkInsLast28: Int { last28.filter { $0.hasNightCheckIn || $0.fallMinutes != nil }.count }

    // MARK: Totals

    var averageWakes: Double? { Self.average(nights.compactMap { $0.wakes.map(Double.init) }) }
    var flareNightsThisMonth: Int {
        nights.filter { $0.wasFlare && calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }.count
    }
    var averageRating: Double? { Self.average(nights.filter { $0.rating > 0 }.map { Double($0.rating) }) }
}
