import Foundation

enum AgeGroup: String, Codable, CaseIterable, Identifiable {
    case baby, toddler, kid
    var id: String { rawValue }
    var label: String {
        switch self {
        case .baby: return "Baby (0–1)"
        case .toddler: return "Toddler (1–3)"
        case .kid: return "Kid (4–8)"
        }
    }
}

/// Everything collected in onboarding. Saved locally on the device.
struct OnboardingAnswers: Codable, Equatable {
    var parentName = ""
    var childName = ""
    var ageGroup: AgeGroup = .toddler
    /// Quiz answers: question id → selected option ids.
    var quiz: [String: [String]] = [:]
    var usualZones: [CareZone] = [.arms, .elbows, .knees]
    var reminderHour = 19
    var reminderMinute = 30
    var wantsReminder = false
    var completedTaste = false

    var displayParent: String {
        let name = parentName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "You" : name
    }

    var displayChild: String {
        let name = childName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "your little one" : name
    }

    func selected(_ questionID: String) -> [String] { quiz[questionID] ?? [] }

    /// A 0–100 "bedtime struggle" estimate from the quiz. Higher = harder nights.
    /// This is our own simple scoring of the parent's answers, not a clinical measure.
    var struggleScore: Int {
        var points = 0
        var maxPoints = 0
        for question in QuizBank.questions where !question.allowsMultiple {
            guard let maxWeight = question.options.map(\.weight).max(), maxWeight > 0 else { continue }
            maxPoints += maxWeight
            if let pick = selected(question.id).first,
               let option = question.options.first(where: { $0.id == pick }) {
                points += option.weight
            }
        }
        guard maxPoints > 0 else { return 0 }
        return Int((Double(points) / Double(maxPoints) * 100).rounded())
    }

    /// The paywall headline: remembers the main reason they came (their first goal).
    var paywallHeadline: String {
        let line: String
        switch selected("goals").first {
        case "noFights": line = "lotion time without the fight starts tonight."
        case "sleep": line = "30 nights from now, you could be sleeping through again."
        case "evenings": line = "30 nights from now, your evenings are yours again."
        case "connection": line = "bedtime is about to become your favorite part of the day."
        case "confidence": line = "in 30 nights you'll know exactly what to do, every night."
        default: line = "30 nights from now, bedtime won't feel like a battle."
        }
        let name = parentName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return line.prefix(1).uppercased() + line.dropFirst() }
        return "\(name), \(line)"
    }

    var recommendedMinutes: Int {
        switch ageGroup {
        case .baby: return 5
        case .toddler: return 10
        case .kid: return 10
        }
    }
}
