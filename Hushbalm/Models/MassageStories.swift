import Foundation

/// A massage story: the narration the child hears IS the parent's massage guide.
/// Each scene is one body area. Dry skin gets a gliding scene; flaring skin gets the
/// story's gentle "tap" scene. Original stories starring Lumi the Star Catcher.
struct MassageStory: Identifiable, Hashable {
    let id: String
    let title: String
    let ages: String
    let blurb: String
    /// Spoken while the parent warms the cream.
    let opening: String
    /// One gliding scene per body area.
    let zoneScenes: [CareZone: String]
    /// Used for any flaring area. "{area}" is replaced with the area name.
    let flareScene: String
    /// Spoken during slow back circles; ends with Lumi placing a star on the ceiling.
    let closing: String
    /// Whispered together at the very end.
    let affirmation: String
}

enum MassageStoryLibrary {
    static let all: [MassageStory] = [sleepyComet, lastStar]

    static func story(_ id: String) -> MassageStory { all.first { $0.id == id } ?? sleepyComet }

    // Ages 1–5: short, repetitive, lots of sound.
    static let sleepyComet = MassageStory(
        id: "sleepyComet",
        title: "Lumi and the Sleepy Comet",
        ages: "Ages 1–5",
        blurb: "Lumi follows a yawning comet across a soft, sleepy sky.",
        opening: "High above the rooftops lives Lumi, the Star Catcher. Lumi has a little silver net and very gentle hands. Tonight, a sleepy comet is drifting by. Let's warm our hands, nice and slow, so we're ready to follow it.",
        zoneScenes: [
            .face: "The comet floats past your cheeks, whoosh, soft as a feather, and tickles your forehead goodnight.",
            .neck: "Down, down, the comet slides along the hill of your neck. Gentle. Slow.",
            .arms: "The comet zooms down the long, long sky of your arm, whoosh, all the way to your fingertips.",
            .elbows: "It curls into the cozy cave in your elbow, takes a little nap, and slides back out.",
            .hands: "Lumi holds your hand and counts the stars on each finger. One, two, three, four, five.",
            .tummy: "The comet circles round and round the moon on your tummy, slow and warm.",
            .back: "Whoosh, the comet glides down the big sky of your back, from the top all the way to the bottom.",
            .legs: "The comet races down the long road of your leg, all the way to your toes.",
            .knees: "It tucks into the little hideout behind your knee, then slides out, whoosh.",
            .feet: "Lumi gives each toe a sleepy star. Night night, toes."
        ],
        flareScene: "Here, on your {area}, the stars are tender tonight. So Lumi doesn't slide. Lumi just taps, tap, tap, soft as snowflakes landing.",
        closing: "The sleepy comet gives one last big yawn. Lumi catches it in the silver net, so gently, and climbs up to your ceiling to stick it there, glowing. Big, slow circles now, like the comet going round and round to sleep.",
        affirmation: "My skin is healing. I am safe. I am loved."
    )

    // Ages 4–8: a little more story, a little more wonder.
    static let lastStar = MassageStory(
        id: "lastStar",
        title: "Lumi Catches the Last Star",
        ages: "Ages 4–8",
        blurb: "One star is still awake, and only Lumi can help it find its place.",
        opening: "Every night, when the town goes quiet, Lumi the Star Catcher climbs the tallest ladder in the world. Tonight, every star is tucked into the sky except one, a small, shy star still wandering about. Let's warm our hands so we can help Lumi find it.",
        zoneScenes: [
            .face: "Lumi checks behind the clouds of your cheeks, light as a breath, and around the hill of your forehead. Not here.",
            .neck: "Lumi tiptoes down the quiet path of your neck, step by careful step.",
            .arms: "Lumi slides down the moonbeam of your arm, slow and smooth, all the way to the edge of the sky at your fingertips.",
            .elbows: "The little valley in your elbow is a perfect hiding place. Lumi looks inside, gently. Just moonlight.",
            .hands: "Lumi peeks between each of your fingers, like five tall trees in a forest. One, two, three, four, five. No star yet.",
            .tummy: "Lumi floats in slow circles over the lake of your tummy, watching for a twinkle in the water.",
            .back: "Lumi sails down the wide, dark sky of your back, long and slow, from your shoulders all the way down.",
            .legs: "Lumi glides down the long river of your leg, past the reeds, all the way to the waterfall at your toes.",
            .knees: "Behind your knee is a secret tunnel. Lumi slides through, slow and careful. Still no star.",
            .feet: "At the very bottom of the world, by your toes, Lumi finds something warm and glowing."
        ],
        flareScene: "On your {area}, the sky is tender tonight. Lumi knows just what to do: no sliding here, only soft taps, like raindrops on a window, tap, tap, tap.",
        closing: "There it is, the last little star, curled up and sleepy. Lumi scoops it into the silver net and carries it all the way up to your ceiling, where it glows softly, right above you. Now big, slow circles, like the whole sky settling down to sleep.",
        affirmation: "I am brave. I am more than my skin. I am loved."
    )
}

extension MassageStory {
    func scene(for zone: CareZone, state: CareState) -> String {
        if state == .flaring {
            return flareScene.replacingOccurrences(of: "{area}", with: zone.label.lowercased())
        }
        return zoneScenes[zone] ?? flareScene.replacingOccurrences(of: "{area}", with: zone.label.lowercased())
    }
}
