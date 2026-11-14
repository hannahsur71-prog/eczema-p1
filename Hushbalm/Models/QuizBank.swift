import Foundation

struct QuizOption: Identifiable, Hashable {
    let id: String
    let title: String
    /// Contribution to the struggle score (single-select questions only).
    var weight: Int = 0
}

struct QuizQuestion: Identifiable, Hashable {
    let id: String
    /// Use {child} and {parent} placeholders; they are filled with names.
    let title: String
    let subtitle: String?
    let options: [QuizOption]
    var allowsMultiple = false

    func title(for answers: OnboardingAnswers) -> String {
        title
            .replacingOccurrences(of: "{child}", with: answers.displayChild)
            .replacingOccurrences(of: "{parent}", with: answers.displayParent)
    }
}

/// The quiz. Order follows the proven sleep-app pattern:
/// child's problem → bedtime reality → parent's own feelings → goals.
enum QuizBank {
    static let questions: [QuizQuestion] = [
        QuizQuestion(
            id: "bedtimeLength",
            title: "How long does bedtime take with {child} right now?",
            subtitle: "From bath to asleep.",
            options: [
                QuizOption(id: "under20", title: "Under 20 minutes", weight: 0),
                QuizOption(id: "20to45", title: "20–45 minutes", weight: 1),
                QuizOption(id: "45to90", title: "45–90 minutes", weight: 2),
                QuizOption(id: "over90", title: "Over 90 minutes", weight: 3)
            ]
        ),
        QuizQuestion(
            id: "lotionTime",
            title: "What usually happens at lotion time?",
            subtitle: nil,
            options: [
                QuizOption(id: "fine", title: "It goes fine", weight: 0),
                QuizOption(id: "wriggles", title: "They wriggle and won't sit still", weight: 1),
                QuizOption(id: "runs", title: "They run away or hide", weight: 2),
                QuizOption(id: "tears", title: "Tears, screaming, a full battle", weight: 3)
            ]
        ),
        QuizQuestion(
            id: "nightWaking",
            title: "How often does {child} wake up scratching?",
            subtitle: nil,
            options: [
                QuizOption(id: "rarely", title: "Rarely", weight: 0),
                QuizOption(id: "weekly", title: "A few nights a week", weight: 1),
                QuizOption(id: "nightly", title: "Most nights", weight: 2),
                QuizOption(id: "multiple", title: "Several times every night", weight: 3)
            ]
        ),
        QuizQuestion(
            id: "parentSleep",
            title: "And how are you sleeping, {parent}?",
            subtitle: "Be honest. This is just for your plan.",
            options: [
                QuizOption(id: "good", title: "Pretty well", weight: 0),
                QuizOption(id: "ok", title: "Okay, but tired", weight: 1),
                QuizOption(id: "broken", title: "Broken sleep most nights", weight: 2),
                QuizOption(id: "running", title: "I'm running on empty", weight: 3)
            ]
        ),
        QuizQuestion(
            id: "bedtimeFeeling",
            title: "How do you feel when bedtime gets close?",
            subtitle: nil,
            options: [
                QuizOption(id: "calm", title: "Calm, it's our time together", weight: 0),
                QuizOption(id: "tired", title: "Tired, I just want it done", weight: 1),
                QuizOption(id: "dread", title: "I dread it a little", weight: 2),
                QuizOption(id: "guilty", title: "Guilty and helpless when they itch", weight: 3)
            ]
        ),
        QuizQuestion(
            id: "tried",
            title: "What have you already tried?",
            subtitle: "Select all that apply.",
            options: [
                QuizOption(id: "creams", title: "Lots of different creams"),
                QuizOption(id: "bathRoutine", title: "Changing bath routines"),
                QuizOption(id: "sleeves", title: "Scratch sleeves or mittens"),
                QuizOption(id: "apps", title: "Sleep apps or white noise"),
                QuizOption(id: "bribes", title: "Bribes, sticker charts, distraction")
            ],
            allowsMultiple: true
        ),
        QuizQuestion(
            id: "goals",
            title: "If bedtime got easier, what would change for you?",
            subtitle: "Select all that matter.",
            options: [
                QuizOption(id: "connection", title: "More calm, close time with {child}"),
                QuizOption(id: "sleep", title: "I'd finally sleep through the night"),
                QuizOption(id: "evenings", title: "I'd get my evenings back"),
                QuizOption(id: "noFights", title: "No more lotion fights"),
                QuizOption(id: "confidence", title: "I'd feel like I'm doing it right")
            ],
            allowsMultiple: true
        )
    ]

    static func question(_ id: String) -> QuizQuestion? { questions.first { $0.id == id } }
}
