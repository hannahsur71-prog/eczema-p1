import Foundation

enum StoryKind: String, Codable {
    case massage, bedtimeStory, affirmation, calm
}

/// One step of a massage story: what the hands do and what the story says.
struct MassageStep: Equatable {
    let label: String
    let cue: String
    let story: String
    /// Body areas, e.g. "upper", "armL". See `MassageGeometry.spot`.
    let zones: [String]
    /// Stroke name, e.g. "glide", "circle". See `MassageGeometry.path`.
    let motion: String
    /// "back", "front", "foot", "palm", or the special views "warm", "turn", "turnBack".
    let view: String
    let reps: String
    let seconds: Int
    /// Optional steps are left out of the shorter version.
    let isOptional: Bool

    init(_ label: String, cue: String, story: String, zones: [String], motion: String, view: String,
         reps: String, seconds: Int = 60, isOptional: Bool = false) {
        self.label = label
        self.cue = cue
        self.story = story
        self.zones = zones
        self.motion = motion
        self.view = view
        self.reps = reps
        self.seconds = seconds
        self.isOptional = isOptional
    }
}

struct StoryChapter: Equatable {
    let title: String
    let text: String
}

struct StoryFact {
    let text: String
    let source: String
}

struct StoryItem: Identifiable {
    let id: String
    let kind: StoryKind
    let kindLabel: String
    let title: String
    let color: UInt32
    let chips: [String]
    let summary: String
    let age: String
    let length: String
    let benefits: [String]
    let factKey: String
    let steps: [MassageStep]
    let chapters: [StoryChapter]
    let ending: String
    let lines: [String]

    var isAudio: Bool { kind != .massage }
    var hasChapters: Bool { !chapters.isEmpty }
    var meta: String { "\(length) · \(age)" }
}

/// What a parent picked in "Create a story".
struct CustomStoryRequest: Codable, Equatable {
    var topic = "dinosaur"
    var text = ""
    var lesson = "confidence"
}

enum StoryLength: String, CaseIterable {
    case short, medium, long
    var minutes: Int { self == .short ? 5 : (self == .medium ? 10 : 20) }
}

extension String {
    /// Puts the child's name into story text.
    func personalized(_ child: String) -> String { replacingOccurrences(of: "{child}", with: child) }
}

extension StoryCatalog {
    static let customID = "custom"

    static func item(_ id: String, custom: CustomStoryRequest?) -> StoryItem? {
        if id == customID, let custom { return customStory(custom) }
        return all.first { $0.id == id }
    }

    /// The library, with the parent's own story last among the massage stories.
    static func library(custom: CustomStoryRequest?) -> [StoryItem] {
        guard let custom else { return all }
        var items = all
        let insertAt = (items.lastIndex { $0.kind == .massage } ?? -1) + 1
        items.insert(customStory(custom), at: insertAt)
        return items
    }

    /// The steps to play: the shorter version drops optional steps; "Warm the cream" shows hands
    /// rubbing; and a clear roll-over step is added whenever the child has to turn.
    static func playableSteps(_ item: StoryItem, short: Bool, child: String) -> [MassageStep] {
        var result: [MassageStep] = []
        var side: String?
        for original in item.steps where !(short && original.isOptional) {
            var step = original
            if step.label.hasPrefix("Warm the cream") {
                step = MassageStep(step.label, cue: step.cue, story: step.story, zones: step.zones, motion: "rub", view: "warm",
                                   reps: step.reps, seconds: step.seconds, isOptional: step.isOptional)
            }
            let stepSide: String? = step.view == "warm" ? side : (step.view == "back" ? "back" : "front")
            if let side, let stepSide, side != stepSide {
                result.append(stepSide == "front"
                    ? MassageStep("Time to roll over", cue: "Help \(child) roll gently onto their back",
                                  story: "Now let's roll over, slow as a sleepy bear, and look up at the sky.",
                                  zones: ["tummy"], motion: "still", view: "turn", reps: "Roll onto back", seconds: 25)
                    : MassageStep("Time to roll over", cue: "Help \(child) roll gently onto their tummy",
                                  story: "Now let's roll over, slow as a sleepy bear, and snuggle down.",
                                  zones: ["upper"], motion: "still", view: "turnBack", reps: "Roll onto tummy", seconds: 25))
            }
            if let stepSide { side = stepSide }
            result.append(step)
        }
        return result
    }

    /// Seconds a step lasts. The shorter version runs each step at 60%.
    static func duration(_ step: MassageStep, short: Bool) -> Int {
        Int((Double(step.seconds) * (short ? 0.6 : 1)).rounded())
    }

    static func totalMinutes(_ item: StoryItem, short: Bool) -> Int {
        let seconds = item.steps.filter { !(short && $0.isOptional) }.reduce(0) { $0 + $1.seconds }
        return Int((Double(seconds) * (short ? 0.6 : 1) / 60).rounded())
    }

    /// Chapters for the chosen length, always ending with the same calm goodnight.
    static func parts(_ item: StoryItem, length: StoryLength) -> [StoryChapter] {
        let count = length == .short ? 1 : (length == .medium ? 2 : item.chapters.count)
        return Array(item.chapters.prefix(count)) + [StoryChapter(title: "Goodnight", text: item.ending)]
    }

    // MARK: Create a story

    static let topics: [(id: String, label: String)] = [("dinosaur", "Dinosaurs"), ("unicorn", "Unicorns"), ("whale", "The ocean"),
                                                         ("rocket", "Space"), ("digger", "Diggers and trucks"), ("puppy", "Puppies")]
    static let lessons: [(id: String, label: String)] = [("confidence", "Confidence"), ("kindness", "Being kind"), ("doctor", "Brave at the doctor"),
                                                          ("sharing", "Sharing"), ("newThings", "Trying new things"), ("itchy", "Calm on itchy nights"),
                                                          ("fun", "Just for fun")]

    /// A parent-made story. The words follow their choices; the strokes always come from the reviewed routine.
    /// In the shipped app the words would be written by an AI service; this template stands in for it.
    static func customStory(_ request: CustomStoryRequest) -> StoryItem {
        let heroes: [String: (String, String, String)] = [
            "dinosaur": ("little dinosaur", "Dino", "the fern valley"), "unicorn": ("little unicorn", "Luna", "the rainbow meadow"),
            "whale": ("little whale", "Wren", "the deep blue sea"), "rocket": ("little astronaut", "Nova", "the quiet moon"),
            "digger": ("little digger truck", "Scoop", "the sleepy building site"), "puppy": ("little puppy", "Biscuit", "the cozy backyard")]
        let typed = request.text.trimmingCharacters(in: .whitespaces)
        let (hero, name, place) = typed.isEmpty ? (heroes[request.topic] ?? heroes["dinosaur"]!)
                                                : ("little friend who loves \(typed)", "Pip", "a quiet, cozy place")
        let lesson: (title: String, moment: String, words: String)
        switch request.lesson {
        case "kindness":
            lesson = ("Is Kind", "On the way, \(name) saw a tiny snail who had lost its way. \(name) stopped, smiled, and gently showed the snail the path home. Being kind made \(name) feel warm all over.", "I am kind. My kindness makes the world brighter.")
        case "doctor":
            lesson = ("Visits the Doctor", "\(name) had a check-up today and felt a little nervous. The doctor had gentle hands and a friendly smile. \(name) squeezed a grown-up's hand, took a slow breath, and it was over before a count of ten.", "I am brave at the doctor. I am safe.")
        case "sharing":
            lesson = ("Learns to Share", "\(name) had one favorite blanket, and a friend who was cold. \(name) thought about it, then opened the blanket wide. There was room for two, and it was even cozier.", "I can share. There is enough for everyone.")
        case "newThings":
            lesson = ("Tries Something New", "Tonight there was a new food on \(name)'s plate. \(name) sniffed it. Licked it. Took one tiny bite. Trying is brave, even when it's just one bite.", "I can try new things. One small step at a time.")
        case "itchy":
            lesson = ("and the Itchy Night", "\(name)'s skin felt itchy and prickly tonight. Instead of scratching, \(name) asked for cool cream and a gentle hand. Slowly, the prickles settled, like leaves landing on still water.", "My skin is calming. I am more than my skin.")
        case "fun":
            lesson = ("Has a Sleepy Adventure", "\(name) found the softest, quietest spot in all of \(place), and decided it was the perfect place to rest.", "I am safe. I am loved.")
        default:
            lesson = ("Is Brave", "\(name) wanted to climb the big hill, but felt wobbly inside. \(name) took one slow breath and whispered, I can do hard things. And step by step, up \(name) went.", "I can do hard things. I am brave.")
        }
        let capitalHero = hero.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
        let title = typed.isEmpty ? "The \(capitalHero) \(lesson.title)" : "\(name) \(lesson.title)"
        return StoryItem(
            id: customID, kind: .massage, kindLabel: "Massage story", title: title, color: 0xB98A4A,
            chips: ["Made for {child}", "A story they feel"],
            summary: "Written for {child}. A sleepy \(hero) named \(name) winds down for the night, and every part of the story is a touch {child} can feel.",
            age: "2+", length: "5 or 10 min",
            benefits: ["About something {child} loves", "Every story moment is a touch they can feel", "Ends with: \"\(lesson.words)\""],
            factKey: "protocol",
            steps: [
                MassageStep("Ask first", cue: "Rest both palms still on their back, then ask", story: "Once upon a time, in \(place), lived a sleepy \(hero) named \(name). Before the story begins, we always ask: can I put on your cream? Wait for a yes.", zones: ["upper"], motion: "still", view: "back", reps: "Wait for a yes", seconds: 40),
                MassageStep("The warm sun", cue: "Warm the cream in your hands, then rest your warm palms on their back", story: "The evening sun rested on \(name)'s back, warm and golden. Feel the sun? That's the warm sun on your back too.", zones: ["upper"], motion: "still", view: "back", reps: "Warm, still hands", seconds: 40),
                MassageStep("The cloud blanket", cue: "Flat palms sweep the cream across the whole back", story: "A soft blanket of clouds drifted over \(place), smoothing everything quiet.", zones: ["upper"], motion: "open", view: "back", reps: "×3 slow", seconds: 50),
                MassageStep("The long hill", cue: "Hand over hand, neck to hips, moderate pressure", story: "\(name) slid down the long, long hill toward home. Whoosh. And once more, whoosh. Feel \(name) sliding down your back?", zones: ["upper"], motion: "glide", view: "back", reps: "×8 slow", seconds: 100),
                MassageStep("Round puddles", cue: "Fingertip circles on both sides of the spine, never on it", story: "At the bottom were round, still puddles. \(name) walked a slow circle around each one. Round and round.", zones: ["midL", "midR"], motion: "circle", view: "back", reps: "×8 each side", seconds: 80),
                MassageStep("The two rivers", cue: "Shoulder to wrist with a gentle squeeze, one arm then the other", story: "Two gentle rivers flowed down from the hills. \(name) floated down the first, then the second, all the way to the end.", zones: ["armL"], motion: "armGlide", view: "back", reps: "×5 each arm", seconds: 90),
                MassageStep("The big moment", cue: "Slow circles over both shoulders", story: lesson.moment, zones: ["shL", "shR"], motion: "circle", view: "back", reps: "Slow circles", seconds: 80),
                MassageStep("The long hill, slower", cue: "The same long strokes, slower each time", story: "Home at last. \(name) walked slower now. And slower. So very sleepy.", zones: ["upper"], motion: "glide", view: "back", reps: "×5 very slow", seconds: 70, isOptional: true),
                MassageStep("The cozy nest", cue: "Rest both palms still and breathe together", story: "\(name) curled up in a cozy nest and whispered, \(lesson.words) Now you say it too, {child}. \(lesson.words) Goodnight.", zones: ["lower"], motion: "still", view: "back", reps: "3 slow breaths", seconds: 50)
            ],
            chapters: [], ending: "", lines: [])
    }
}
