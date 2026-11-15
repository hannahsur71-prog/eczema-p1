import Foundation

/// Everything the parent enters during onboarding, before it is saved to `OnboardingAnswers`.
struct OnboardingDraft: Equatable {
    var child = ""
    var parent = ""
    /// Single-choice answers that have a default: age, relationship, reminder, plan, severity.
    var picks: [String: String] = ["age": "toddler", "relationship": "mom", "reminder": "1930",
                                   "plan": "yearly", "severity": "moderate"]
    /// Multi-choice answers: zones, goals.
    var multi: [String: [String]] = ["zones": ["arms", "elbows", "knees"]]
    /// Quiz answers with no default.
    var q: [String: String] = [:]
    /// Free text typed into "Something else? Tell us".
    var other: [String: String] = [:]
    var lit = 0
    var promised = false
    var rating = 0

    var childName: String {
        let name = child.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "your child" : name
    }
    var parentName: String { parent.trimmingCharacters(in: .whitespaces) }
    var grownUp: String {
        ["mom": "Mommy", "dad": "Daddy", "grandma": "Grandma", "grandpa": "Grandpa"][picks["relationship"] ?? "mom"] ?? "Your grown-up"
    }
    var isSevere: Bool { picks["severity"] == "severe" }
    var zones: [String] { multi["zones"] ?? [] }
    var goals: [String] { multi["goals"] ?? [] }
    /// Shorter rituals for touch-shy children, babies and severe eczema.
    var minutes: Int {
        let touch = q["touch"]
        return (touch == "notFan" || touch == "sensitive" || isSevere || picks["age"] == "baby") ? 5 : 10
    }
    var isYearly: Bool { picks["plan"] != "monthly" }
}

struct OBOption: Identifiable, Equatable {
    let id: String
    let label: String
}

enum OBKind: Equatable {
    case hero, insight, featureDemo, featureScreenFree, featureStars
    case input, single, multi, question
    case environment, loading, cost, chart, beforeAfter, month, plan
    case taste, win, commit, rate, signin, building, paywall, offer, welcome
}

/// One onboarding screen. Mirrors the prototype's screen list one to one.
struct OBScreen {
    var kind: OBKind
    var title: String
    var key = ""
    var body = ""
    /// Small line under the options.
    var note = ""
    var options: [OBOption] = []
    var isGrid = false
    var statValue = ""
    var statCaption = ""
    var source = ""
    var cta: String? = "Continue"
    var secondary: String?
    var showsArt = false
    var isCentered = false
    var showsBar = true
    var showsClose = false
    var autoAdvances = false
    var hasOther = false
    var placeholder = ""
    /// Tailored reply shown under the chosen answer: option id → text.
    var feedback: [String: String] = [:]
    var showsCeiling = false
    var showsLegal = false

    init(_ kind: OBKind, _ title: String, _ configure: (inout OBScreen) -> Void = { _ in }) {
        self.kind = kind
        self.title = title
        configure(&self)
    }
}

struct OBEnvironmentItem: Identifiable {
    let ok: Bool
    let title: String
    let text: String
    var id: String { title }
}

struct OBCostNumbers {
    let nightlyStruggle: Int
    let struggleHours: Int
    let wakesPerYear: Int
    let lostSleepHours: Int
    let gainHours: Int
    let wakeLabel: String
}

struct OBPlanStep: Identifiable {
    let icon: String
    let title: String
    let detail: String
    let time: String
    let tint: UInt32
    var id: String { title }
}

struct OBTasteStep {
    let title: String
    let reps: String
    let hands: String
    let story: String
    let motion: MassageMotion
}

/// The onboarding copy and logic, taken word for word from the approved prototype.
enum OnboardingScript {

    // MARK: Screens

    static func screens(_ d: OnboardingDraft) -> [OBScreen] {
        let c = d.childName
        let parent = d.parentName
        let touch = d.q["touch"]

        let touchCopy: (String, String)
        switch touch {
        case "ticklish":
            touchCopy = ("*Ticklish?* Slower and firmer helps.", "Light, quick strokes tickle most. Lumi guides slow, steady glides, and we keep each scene short for \(c).")
        case "notFan":
            touchCopy = ("We'll *start small* with \(c).", "Lots of kids warm up to touch with time. The plan starts with 5-minute rituals and just a few areas.")
        case "sensitive":
            touchCopy = ("*Gentle* comes first.", "Feather-light pressure, massage only on calm skin, and on flaring spots we just smooth the cream on. Rituals start at 5 minutes.")
        default:
            touchCopy = ("*\(c)* is going to love this.", "Kids who enjoy touch usually settle quickly into a massage ritual. Lumi's long, slow glides are made for that.")
        }

        func insight(_ title: String, body: String = "", stat: (String, String)? = nil, source: String = "", cta: String = "Continue") -> OBScreen {
            OBScreen(.insight, title) {
                $0.showsArt = true
                $0.isCentered = true
                $0.body = body
                $0.statValue = stat?.0 ?? ""
                $0.statCaption = stat?.1 ?? ""
                $0.source = source
                $0.cta = cta
            }
        }
        func options(_ pairs: [(String, String)]) -> [OBOption] { pairs.map { OBOption(id: $0.0, label: $0.1) } }
        func question(_ key: String, _ title: String, _ pairs: [(String, String)], note: String = "", hasOther: Bool = false) -> OBScreen {
            OBScreen(.question, title) {
                $0.key = key
                $0.options = options(pairs)
                $0.note = note
                $0.hasOther = hasOther
            }
        }

        let severityInsight: OBScreen
        if d.isSevere {
            severityInsight = insight("For harder nights, Alji *focuses on comfort*",
                body: "With severe eczema, \(c)'s plan leans on what soothes without rubbing: affirmations that build confidence in their skin, audio bedtime stories to relax, and gentle touch, like still hands and slow strokes on calm skin only. On flaring skin you just smooth the cream on, exactly as \(c)'s doctor directed.",
                source: "Alji is a bedtime routine, not a medical treatment. Severe eczema needs a doctor's care plan.", cta: "Sounds right")
        } else if d.picks["severity"] == "unsure" {
            severityInsight = insight("Not sure? *That's okay.*",
                body: "Many parents aren't. A quick guide: mild is a few dry, itchy patches. Moderate is several areas with regular flares. Severe is widespread, cracked or weeping skin. We'll start gently, and \(c)'s doctor can tell you for sure.",
                source: "Alji is a bedtime routine, not a medical treatment.")
        } else {
            severityInsight = insight("Alji is made for *mild to moderate* eczema",
                body: "That's most children with eczema. Alji works alongside the care \(c)'s doctor recommends, never instead of it: a calm, screen-free routine that makes nightly moisturizing easier.",
                source: "Alji is a bedtime routine, not a medical treatment. If eczema becomes severe or infected, see a doctor.")
        }

        let wakingInsight: OBScreen
        switch d.q["nightWaking"] {
        case "rarely":
            wakingInsight = insight("Calm nights are *worth protecting*",
                body: "That's good to hear. Eczema can change with the seasons and with flares, so a steady bedtime ritual helps keep \(c)'s nights the way they are.")
        case "weekly":
            wakingInsight = insight("You're *not alone* in this",
                stat: ("7 in 10", "children with eczema have disrupted sleep, and more than half of their parents do too."),
                source: "Eczema Society of Canada caregiver survey (361 families).")
        default:
            wakingInsight = insight("With eczema, the *whole family* loses sleep",
                stat: ("60%", "of eczema caregivers wake two or more times a night to care for their child."),
                source: "National Eczema Association.")
        }

        let creamInsight = d.q["lotionTime"] == "fine"
            ? insight("Good. Let's make it *the best part* of the night",
                      body: "Cream time already goes smoothly for \(c). Alji turns it into something to look forward to: a story, your hands, and time together.")
            : insight("It's not you. Cream time was *never designed to feel good*.",
                      body: "Alji turns it into a story \(c) wants to hear, so the cream goes on while they lie still and listen.")

        let triedTitles = ["tracker": "Trackers help you *spot patterns*", "sleepapp": "Sleep stories help kids *drift off*",
                           "cream": "Quick is *understandable*", "nothing": "You're starting at *the right place*",
                           "other": "Thank you for *telling us*"]
        let triedBodies = [
            "tracker": "That's useful. Alji adds the part trackers don't cover: a calm ritual for the cream itself, plus a 2-second nightly check-in.",
            "sleepapp": "They're great for winding down. They don't help the moisturizer go on, though. Alji does both: a story that guides the cream, then sleep.",
            "cream": "A story gives \(c) a reason to lie still, so there's time to get the cream on everywhere.",
            "nothing": "Alji gives you one simple nightly ritual: bath, cream with a guided massage story, then sleep.",
            "other": "Every family finds its own way. Alji builds on what you've already learned, and your answer helps us improve."]
        let tried = d.q["tried"] ?? ""
        let triedInsight = insight(triedTitles[tried] ?? "Here's how *Alji fits in*",
                                   body: triedBodies[tried] ?? "Alji turns the moisturizer itself into a calming ritual.")

        let parentSleepInsight = d.q["parentSleep"] == "good"
            ? insight("Glad you're *sleeping well*",
                      body: "Let's keep it that way. In a 2023 trial, mothers who gave their babies a nightly massage slept better and felt less anxious, so this ritual is for you too.",
                      source: "Lin et al., Frontiers in Public Health, 2023.")
            : insight("When parents give the massage, *parents feel better too*",
                      body: (d.q["parentSleep"] == "running" ? "Running on empty is hard, and it matters. " : "")
                        + "In a 2023 randomized trial, mothers who massaged their babies with eczema saw milder eczema, and their own anxiety and depression scores dropped.",
                      source: "Lin et al., Frontiers in Public Health, 2023.")

        let fixes = environment(d).filter { !$0.ok }.count
        let rx = "Got it. Alji will remind you to apply it first, exactly as prescribed, before the massage."
        let welcomeDeal = d.isYearly
            ? " Free until \(dateString(daysFromNow: 3)). We'll remind you on \(dateString(daysFromNow: 2)). Then $59.99 a year."
            : " $9.99 a month."

        var list: [OBScreen] = [
            OBScreen(.hero, "Bedtime can be the *calmest part* of your day.") {
                $0.showsArt = true; $0.isCentered = true; $0.showsBar = false; $0.cta = "Get started"
                $0.body = "Alji turns your child's nightly moisturizer into a calming massage-and-story ritual, made for eczema skin."
            },
            insight("“My mom massaged my cream in and tucked me in under *glow-in-the-dark stars*.”",
                    body: "I grew up with eczema. The itch didn't always go away, but bedtime felt safe. Alji is that ritual, for every family living with eczema. — Hannah, founder"),
            OBScreen(.featureDemo, "A bedtime story that *guides your hands*") {
                $0.body = "Press play. Lumi's story tells you each massage stroke while you smooth the moisturizer in."
            },
            OBScreen(.featureScreenFree, "*Screen-free* for your child") {
                $0.body = "Your child just listens and feels your hands. The phone lies face down with the screen dark."
            },
            OBScreen(.featureStars, "Watch calm nights *add up*") {
                $0.isCentered = true; $0.showsCeiling = true; $0.cta = "Let's set it up"
                $0.body = "Every ritual lights a star, and every month completes a new moon. See itch and wake-ups change over time."
            },
            OBScreen(.input, "Pick *a name* for your child's profile") {
                $0.key = "child"; $0.placeholder = "Name or nickname"
                $0.body = "A name or nickname. Lumi the Star Catcher will use it in every story."
            },
            OBScreen(.single, "That's a beautiful name. How old is *\(c)*?") {
                $0.key = "age"
                $0.options = options([("baby", "Baby (0–1)"), ("toddler", "Toddler (1–3)"), ("kid", "Kid (4–8)")])
                $0.note = "We'll suggest stories and techniques for their age."
            },
            OBScreen(.single, "What is your relationship to *\(c)*?") {
                $0.key = "relationship"
                $0.options = options([("mom", "Mother"), ("dad", "Father"), ("grandma", "Grandmother"), ("grandpa", "Grandfather"), ("other", "Other caregiver")])
                $0.note = "Lumi's stories mention you, so it feels like your ritual."
            },
            OBScreen(.input, "And what's *your* first name?") {
                $0.key = "parent"; $0.placeholder = "Your first name"
                $0.body = "So \(c)'s plan is made for both of you."
            },
            OBScreen(.multi, "Where does *\(c)'s* eczema usually show up?") {
                $0.key = "zones"; $0.isGrid = true; $0.note = "Select all that apply."
                $0.options = options([("face", "Face"), ("neck", "Neck"), ("arms", "Arms"), ("elbows", "Elbow creases"), ("hands", "Hands"),
                                      ("tummy", "Tummy"), ("back", "Back"), ("legs", "Legs"), ("knees", "Behind knees"), ("feet", "Feet")])
            },
            OBScreen(.single, "How would you describe *\(c)'s* eczema right now?") {
                $0.key = "severity"
                $0.options = options([("mild", "Mild: a few dry, itchy patches"), ("moderate", "Moderate: several areas, regular flares"),
                                      ("severe", "Severe: widespread, cracked or weeping skin, broken sleep most nights"), ("unsure", "Not sure")])
                $0.note = "Your best guess is fine. It helps us set things up safely."
            },
            severityInsight,
            question("nightWaking", "How often does *\(c)* wake up scratching?",
                     [("rarely", "Rarely"), ("weekly", "A few nights a week"), ("nightly", "Most nights"), ("multiple", "Several times every night")]),
            wakingInsight,
            question("lotionTime", "What happens when the *cream comes out*?",
                     [("fine", "It goes fine"), ("wriggles", "They wriggle and won't sit still"), ("runs", "They run away or hide"), ("tears", "Tears, screaming, a full battle")]),
            creamInsight,
            question("tried", "What have you tried to make *bedtime* easier?",
                     [("tracker", "Eczema tracker apps"), ("sleepapp", "Kids' sleep or story apps"), ("cream", "Getting the cream on as fast as possible"), ("nothing", "Nothing yet")],
                     hasOther: true),
            triedInsight,
            question("touch", "In general, how does *\(c)* respond to physical touch?",
                     [("loves", "Loves it!"), ("ok", "Ok with it"), ("ticklish", "Super ticklish"), ("notFan", "Not a big fan"), ("sensitive", "Skin often feels sore or sensitive")]),
            insight(touchCopy.0, body: touchCopy.1),
            insight("Bedtime massage is a *gentle, research-backed* add-on",
                    body: "Dermatologists say massage with your child's moisturizer appears safe, just not on flaring skin. In a small study, children massaged nightly improved more than with moisturizer alone.",
                    source: "American Academy of Dermatology; Schachner, Field et al., Pediatric Dermatology, 1998."),
            question("room", "How warm is *\(c)'s* room at night?",
                     [("cool", "Cool"), ("comfy", "Comfortable"), ("warm", "Warm or stuffy"), ("unsure", "Not sure")],
                     note: "Their sleep environment matters as much as the routine."),
            question("sleepwear", "What does *\(c)* usually sleep in?",
                     [("cotton", "Soft cotton pajamas"), ("fleece", "Fleece or synthetic"), ("wool", "Wool or scratchy fabrics"), ("layers", "Lots of layers or heavy blankets")]),
            question("bath", "What happens *after bath time*?",
                     [("right", "Moisturizer goes on right away"), ("later", "Moisturizer goes on later"), ("skip", "We often skip moisturizer"), ("nobath", "No bath most nights")]),
            question("cream", "Does *\(c)* use a prescribed cream or ointment?",
                     [("steroid", "Yes, a steroid cream or ointment"), ("nonsteroid", "Yes, a non-steroid prescription"), ("moisturizer", "Only moisturizer"), ("unsure", "Not sure")],
                     note: "Alji will remind you to apply it first, exactly as your doctor directed."),
            OBScreen(.environment, "*\(c)'s* ideal eczema bedroom") {
                $0.body = fixes == 0 ? "You're already doing all of this. Lovely." : "\(fixes) small changes could make nights easier. We'll add them to \(c)'s plan."
                $0.source = "Based on guidance from the American Academy of Dermatology and the National Eczema Association."
            },
            question("bedtimeLength", "How long does it take for *\(c)* to fall asleep?",
                     [("under20", "5 – 15 minutes"), ("20to45", "20 – 45 minutes"), ("45to90", "45 – 90 minutes"), ("over90", "1.5 hours or more")]),
            question("parentSleep", "And how are *you* sleeping\(parent.isEmpty ? "" : ", \(parent)")?",
                     [("good", "Pretty well"), ("ok", "Okay, but tired"), ("broken", "Broken sleep most nights"), ("running", "I'm running on empty")]),
            parentSleepInsight,
            insight("Alji is *screen-free* for \(c)",
                    body: "You hold the phone. \(c) just listens and feels your hands. Pediatricians recommend no screens in the hour before bed.",
                    source: "American Academy of Pediatrics; Akacem et al., Journal of Pineal Research, 2022."),
            OBScreen(.multi, "What would you most like to help *\(c)* with?") {
                $0.key = "goals"; $0.note = "Select all that apply."
                $0.options = options([("noFights", "Cream time without the fight"), ("sleep", "Sleep through the night"), ("connection", "Feel more connected to me"),
                                      ("confidence", "Feel good in their own skin"), ("evenings", "Get my evenings back")])
            },
            OBScreen(.loading, "We are personalizing *\(c)'s bedtime*") {
                $0.isCentered = true; $0.autoAdvances = true; $0.showsBar = false; $0.cta = nil
                $0.body = "Goals · care areas · bedroom · touch preferences"
            },
            OBScreen(.cost, "Up to *\(cost(d).gainHours) hours* a year could go back to your family") { $0.cta = "Show me how" },
            OBScreen(.chart, "Here's how bedtime can change for *\(c)*") {
                $0.source = "An illustration of our goal based on your answers, not a guarantee. Every child is different."
            },
            OBScreen(.beforeAfter, "From cream-time battles to *lights out under the stars*") { $0.cta = "I want this for us" },
            OBScreen(.month, "What the *first month* looks like"),
            OBScreen(.single, "Ideally, what time would *\(c)* be asleep?") {
                $0.key = "reminder"; $0.cta = "Set up reminder"; $0.secondary = "Maybe later"
                $0.options = options([("1900", "7:00 pm"), ("1930", "7:30 pm"), ("2000", "8:00 pm"), ("2030", "8:30 pm")])
                $0.note = "We'll send a gentle reminder 30 minutes before, so there's time for the bath and the cream."
            },
            OBScreen(.plan, "*\(c)'s* bedtime plan is ready") { $0.cta = "Try night 1 now · 1 minute" },
            OBScreen(.taste, "Grab the cream and *follow along*") {
                $0.body = "Set the phone down. Lumi's story guides your hands."
                $0.cta = "Start the 1-minute ritual"; $0.secondary = "Skip for now"
            },
            OBScreen(.win, "Night 1, *done*.") {
                $0.isCentered = true; $0.showsCeiling = true
                $0.body = "That's how every night with \(c) can feel: calm hands, a soft voice, no battle."
            },
            OBScreen(.commit, "Will you make this *\(c)'s* bedtime ritual?") {
                $0.isCentered = true; $0.cta = "I'm in"
                $0.body = "Small, steady nights are what change bedtime. Tap the star to make it a promise."
            },
            OBScreen(.rate, "Support the *mission*") {
                $0.isCentered = true; $0.cta = "Rate and continue"; $0.secondary = "Not now"
                $0.body = "Alji is made by a founder who grew up with eczema. A quick rating helps other families find it."
            },
            OBScreen(.signin, "Save *\(c)'s* plan") {
                $0.isCentered = true; $0.cta = nil; $0.secondary = "Skip for now"
                $0.body = "Your answers, bedtime plan and tonight's star are ready to save."
            },
            OBScreen(.building, "Writing *\(c)'s* story") {
                $0.body = "Lumi is putting tonight together."; $0.cta = "Unlock \(c)'s story"
            },
            OBScreen(.paywall, headline(d)) {
                $0.showsBar = false; $0.showsClose = true; $0.isCentered = true; $0.showsLegal = true
                $0.body = "Unlock \(c)'s story and every bedtime ritual."
            },
            OBScreen(.offer, "Not ready for full price? Start for *less*.") {
                $0.showsBar = false; $0.isCentered = true; $0.showsArt = true; $0.showsLegal = true
                $0.body = "Same full plan, a lower yearly price, offered once."
                $0.statValue = "$34.99/yr"; $0.statCaption = "That's $2.92 a month. Auto-renews. Cancel anytime in Settings."
                $0.cta = "Start for $34.99/year"; $0.secondary = "Continue with the free version"
            },
            OBScreen(.welcome, "Welcome\(parent.isEmpty ? "" : ", *\(parent)*").") {
                $0.showsArt = true; $0.isCentered = true; $0.showsBar = false; $0.cta = "Go to tonight"
                $0.body = "Every ritual is open. See you tonight for \(c)'s first full night.\(welcomeDeal) Cancel anytime in Settings."
            }
        ]

        let reminderTimes = ["1900": "6:30", "1930": "7:00", "2000": "7:30", "2030": "8:00"]
        let feedback: [String: [String: String]] = [
            "age": ["baby": "For babies, rituals are short and extra gentle: about 5 minutes.",
                    "toddler": "Toddlers love repetition. Asking for the same story all week is a good sign.",
                    "kid": "Big kids get longer stories and can help with their own cream."],
            "room": ["cool": "Great. A cool room is one of the simplest ways to ease night itch.",
                     "comfy": "Good. If nights get itchy, try going a little cooler.",
                     "warm": "Worth changing: heat and sweat are common itch triggers. We'll add it to the plan.",
                     "unsure": "No problem. One sign: if \(c) kicks off the covers, the room is probably too warm."],
            "sleepwear": ["cotton": "Perfect. Loose cotton is the gentlest choice.",
                          "fleece": "Fleece traps heat. Cotton is usually kinder to eczema skin.",
                          "wool": "Wool is a common irritant. We'll suggest a swap in the plan.",
                          "layers": "Layers trap heat, and heat feeds itch. Lighter is usually better."],
            "bath": ["right": "Exactly right. Cream on damp skin locks moisture in.",
                     "later": "Sooner helps: cream works best while skin is still damp.",
                     "skip": "That's common, and it's the step Alji makes easiest.",
                     "nobath": "That's okay. The ritual works without a bath too."],
            "cream": ["steroid": rx, "nonsteroid": rx,
                      "moisturizer": "Great. The massage story is built around that moisturizer.",
                      "unsure": "No problem. You can add it later in Settings."],
            "bedtimeLength": ["under20": "\(c) settles quickly. The goal is to keep it calm and make it closer.",
                              "20to45": "That's common. A steady routine often shortens it.",
                              "45to90": "That's a long, tiring stretch. A wind-down ritual is made for this.",
                              "over90": "That's a long, tiring stretch. A wind-down ritual is made for this."],
            "reminder": reminderTimes.mapValues { "We'll remind you at \($0) pm." }
        ]
        for index in list.indices {
            if let replies = feedback[list[index].key] { list[index].feedback = replies }
        }
        return list
    }

    // MARK: Personalized pieces

    static func headline(_ d: OnboardingDraft) -> String {
        let c = d.childName
        let line: String
        switch d.goals.first {
        case "noFights": line = "cream time without the fight starts tonight."
        case "sleep": line = "a month from now, you could be sleeping through again."
        case "connection": line = "bedtime is about to become your favorite part of the day."
        case "confidence": line = "a month from now, \(c) could feel more at home in their own skin."
        case "evenings": line = "a month from now, your evenings are yours again."
        default: line = "a month from now, bedtime won't feel like a battle."
        }
        if d.parentName.isEmpty { return line.prefix(1).uppercased() + line.dropFirst() }
        return "*\(d.parentName)*, \(line)"
    }

    static func goalText(_ d: OnboardingDraft) -> String {
        switch d.goals.first {
        case "noFights": return "Cream time feels like story time"
        case "sleep": return "Settling faster, fewer wake-ups"
        case "connection": return "Bedtime becomes your time together"
        case "confidence": return "\(d.childName) feels good in their skin"
        case "evenings": return "Your evenings start coming back"
        default: return "Bedtime feels calm"
        }
    }

    /// The "ideal eczema bedroom" checklist, from the environment answers.
    static func environment(_ d: OnboardingDraft) -> [OBEnvironmentItem] {
        let room = d.q["room"] == "cool"
        let cotton = d.q["sleepwear"] == "cotton"
        let bath = d.q["bath"] == "right"
        return [
            OBEnvironmentItem(ok: room, title: "A cool bedroom",
                              text: room ? "Already doing this. Heat and sweat can make itching worse."
                                         : "Heat and sweat can make itching worse. Lower the thermostat a little and use lighter blankets."),
            OBEnvironmentItem(ok: cotton, title: "Soft, breathable sleepwear",
                              text: cotton ? "Already doing this. Loose cotton lets skin breathe."
                                           : "Loose, soft cotton is gentlest. Wool and scratchy fabrics can irritate eczema skin."),
            OBEnvironmentItem(ok: bath, title: "Moisturize right after the bath",
                              text: bath ? "Already doing this. Cream on damp skin after a short, lukewarm bath locks in moisture."
                                         : "After a 5–10 minute lukewarm bath, pat dry and put the cream on while skin is still damp. Alji's ritual starts right there."),
            OBEnvironmentItem(ok: false, title: "Fragrance-free laundry and products",
                              text: "Fragrance is a common irritant. Choose fragrance-free detergent and moisturizer."),
            OBEnvironmentItem(ok: false, title: "Short, smooth nails", text: "Keeps night scratching from breaking the skin.")
        ]
    }

    /// What bedtime costs the family in a year, estimated from their own answers.
    static func cost(_ d: OnboardingDraft) -> OBCostNumbers {
        let fall = ["under20": 10, "20to45": 32, "45to90": 67, "over90": 100][d.q["bedtimeLength"] ?? ""] ?? 40
        let battle = ["fine": 3, "wriggles": 8, "runs": 12, "tears": 18][d.q["lotionTime"] ?? ""] ?? 8
        let waking = d.q["nightWaking"] ?? ""
        let nightsPerWeek = ["rarely": 1.0, "weekly": 3.0, "nightly": 5.5, "multiple": 7.0][waking] ?? 3.0
        let perNight = waking == "multiple" ? 3 : 1
        let label = ["rarely": "about once a week", "weekly": "3 nights a week", "nightly": "5 to 6 nights a week",
                     "multiple": "about 3 times a night"][waking] ?? "3 nights a week"
        let nightlyStruggle = max(0, fall - 15) + battle
        let struggleHours = Int((Double(nightlyStruggle) * 365 / 60).rounded())
        let wakes = Int((nightsPerWeek * 52).rounded()) * perNight
        let lostSleep = Int((Double(wakes) * 20 / 60).rounded())
        let gain = max(10, Int((Double(struggleHours + lostSleep) * 0.5 / 5).rounded()) * 5)
        return OBCostNumbers(nightlyStruggle: nightlyStruggle, struggleHours: struggleHours, wakesPerYear: wakes,
                             lostSleepHours: lostSleep, gainHours: gain, wakeLabel: label)
    }

    /// Minutes to fall asleep now, and the goal.
    static func fallAsleep(_ d: OnboardingDraft) -> (now: Int, goal: Int) {
        let now = ["under20": 15, "20to45": 35, "45to90": 70, "over90": 100][d.q["bedtimeLength"] ?? ""] ?? 45
        return (now, min(now, 15))
    }

    static func beforeLine(_ d: OnboardingDraft) -> String {
        let cream = ["tears": "Tears and a full battle", "runs": "Chasing them with the cream", "wriggles": "Wriggling through cream",
                     "fine": "Cream goes on, but it's rushed"][d.q["lotionTime"] ?? ""] ?? "Rushed, tiring bedtimes"
        let waking = ["multiple": "Waking up scratching, again and again", "nightly": "Scratching most nights",
                      "weekly": "Itchy nights a few times a week", "rarely": "Long, tiring evenings"][d.q["nightWaking"] ?? ""] ?? "Itchy, broken nights"
        return "\(cream). \(waking)."
    }

    static func beforeChips(_ d: OnboardingDraft) -> [String] {
        [["under20": "15 min to fall asleep", "20to45": "35 min to fall asleep", "45to90": "Over an hour to fall asleep",
          "over90": "1.5 hours+ to fall asleep"][d.q["bedtimeLength"] ?? ""] ?? "Long bedtimes",
         ["broken": "Your sleep is broken", "running": "You're running on empty", "ok": "You're tired",
          "good": "Little time for you"][d.q["parentSleep"] ?? ""] ?? "You're exhausted",
         "Itchy, unsettled skin"]
    }

    static func afterLine(_ d: OnboardingDraft) -> String {
        "\(d.childName) asks for Lumi's story, the cream goes on, and they drift off under the stars."
    }

    static func afterChips(_ d: OnboardingDraft) -> [String] {
        ["Calm \(d.minutes)-min ritual", "Moisturized every night", "Your evening back", "Closer together"]
    }

    static func monthSteps(_ d: OnboardingDraft) -> [(when: String, title: String, text: String)] {
        let c = d.childName
        return [
            ("Tonight", "The cream goes on during a story", "No chasing, no convincing. \(c) lies still to hear what Lumi does next."),
            ("Night 3", "\(c) asks for Lumi", "Kids love predictable rituals. The story becomes the cue that it's time to wind down."),
            ("Week 1", "The routine runs itself", "Screens off, lights dim, bath, massage, story. Same order, same calm, every night."),
            ("Week 2", "You see the pattern", "Your 2-second check-ins show itch and wake-ups trending down on the progress page."),
            ("One month in", goalText(d), "\(c)'s first moon is complete, and the next one begins.")
        ]
    }

    /// The bedtime plan, counted back from the chosen sleep time and shaped by their answers.
    static func plan(_ d: OnboardingDraft) -> [OBPlanStep] {
        let sleepAt = ["1900": 19 * 60, "1930": 19 * 60 + 30, "2000": 20 * 60, "2030": 20 * 60 + 30][d.picks["reminder"] ?? ""] ?? 19 * 60 + 30
        func time(_ minutes: Int) -> String {
            let hour = minutes / 60
            return "\((hour + 11) % 12 + 1):" + String(format: "%02d", minutes % 60)
        }
        let hasPrescription = d.q["cream"] == "steroid" || d.q["cream"] == "nonsteroid"
        let noBath = d.q["bath"] == "nobath"
        let m = d.minutes
        var steps = [
            OBPlanStep(icon: "tv.slash", title: "Screens off", detail: "No TV or tablets from here", time: time(sleepAt - 60), tint: 0xC9B6FF),
            OBPlanStep(icon: "lightbulb", title: "Dim the lights", detail: "Lamps only, warm light", time: time(sleepAt - 45), tint: 0xF4DE90)
        ]
        if !noBath {
            steps.append(OBPlanStep(icon: "bathtub", title: "Lukewarm bath", detail: "5–10 minutes, then pat dry", time: time(sleepAt - m - 25), tint: 0x8FC7DD))
        }
        if hasPrescription {
            steps.append(OBPlanStep(icon: "drop", title: "Prescribed cream first", detail: "Exactly as \(d.childName)'s doctor directed", time: time(sleepAt - m - 14), tint: 0xF2A0B8))
        }
        steps.append(OBPlanStep(icon: "sparkles", title: d.isSevere ? "Gentle massage story" : "Massage story",
                                detail: "\(m) min · " + (d.isSevere ? "still hands and soft strokes on calm skin"
                                                                    : "moisturizer on \(noBath ? "" : "damp ")skin, \(d.zones.count) care areas"),
                                time: time(sleepAt - m - 12), tint: 0xF4DE90))
        steps.append(OBPlanStep(icon: "heart.fill", title: "Affirmations, playing softly", detail: "Kind words in the background, up to 2 hours", time: time(sleepAt - 12), tint: 0xA27FD0))
        steps.append(OBPlanStep(icon: "moon.zzz", title: "Asleep", detail: "Log tonight in 2 seconds", time: time(sleepAt), tint: 0x5EC2E6))
        return steps
    }

    static func bedroomTweaks(_ d: OnboardingDraft) -> [(label: String, ok: Bool, icon: String)] {
        let items = environment(d)
        return [("Cool room", items[0].ok, "thermometer.low"), ("Cotton PJs", items[1].ok, "tshirt"),
                ("Cream on damp skin", items[2].ok, "drop"), ("Fragrance-free", false, "leaf")]
    }

    static func tasteSteps(_ d: OnboardingDraft) -> [OBTasteStep] {
        [
            OBTasteStep(title: "Warm the cream", reps: "10 sec", hands: "Warm a generous amount of moisturizer between your palms.",
                        story: "High above the rooftops lives Lumi, the Star Catcher. \(d.grownUp) is warming the magic cream, nice and slow, so we are ready to follow the sleepy comet.",
                        motion: .warm),
            OBTasteStep(title: "Arm glides", reps: "×3 each", hands: "Long, slow strokes from shoulder to wrist. Let the cream melt in.",
                        story: "The comet zooms down the long, long sky of your arm, whoosh, all the way to your fingertips.",
                        motion: .armGlide),
            OBTasteStep(title: "Whirlwinds", reps: "×3 slow", hands: "Big, slow circles on their back. Match your breathing.",
                        story: "Lumi catches the sleepy comet and sticks it on your ceiling, glowing. My skin is healing. I am safe. I am loved.",
                        motion: .bigCircle)
        ]
    }

    static let promiseLines = ["I'll start the ritual at the same time each night",
                               "Screens off, lights low, cream on damp skin",
                               "On hard nights, a shorter ritual still counts"]

    static func buildingLines(_ d: OnboardingDraft) -> [String] {
        let names = ["face": "face", "neck": "neck", "arms": "arms", "elbows": "elbow creases", "hands": "hands", "tummy": "tummy",
                     "back": "back", "legs": "legs", "knees": "behind the knees", "feet": "feet"]
        let zoneList = d.zones.prefix(3).map { names[$0] ?? $0 }.joined(separator: ", ")
        let touch = ["ticklish": "Slow, steady pressure so it won't tickle", "notFan": "Short, gentle strokes to start small",
                     "sensitive": "Feather-gentle touch, calm skin only"][d.q["touch"] ?? ""] ?? "Long, slow strokes made for winding down"
        let bedtime = ["1900": "7:00", "1930": "7:30", "2000": "8:00", "2030": "8:30"][d.picks["reminder"] ?? ""] ?? "7:30"
        return ["Writing Lumi's story with \(d.childName)'s name",
                "Mapping strokes to \(zoneList.isEmpty ? "their care areas" : zoneList)",
                touch,
                "Timing it to finish by \(bedtime) pm",
                "Adding a goodnight affirmation for \(d.childName)"]
    }

    static func lockTitle(_ d: OnboardingDraft) -> String {
        "\(d.childName)'s \(d.isSevere ? "gentle comfort story" : "20-minute massage story") is ready"
    }

    static let paywallBenefits = ["Massage stories that guide your hands",
                                  "Bedtime stories and affirmations, screen-free",
                                  "New stories every month, plus your own"]

    static func dateString(daysFromNow days: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// Thirty star positions that form a crescent moon when all are lit.
    static let constellation: [CGPoint] = {
        var points: [CGPoint] = []
        for k in 0..<18 {
            let angle = (70 + Double(k) * (220.0 / 17)) * Double.pi / 180
            points.append(CGPoint(x: 120 + cos(angle) * 78, y: 95 + sin(angle) * 78))
        }
        for k in 0..<12 {
            let angle = (270 - Double(k) * (180.0 / 11)) * Double.pi / 180
            points.append(CGPoint(x: 150 + cos(angle) * 58, y: 88 + sin(angle) * 58))
        }
        return points
    }()
}
