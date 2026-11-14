import Foundation

/// An original bedtime story, read aloud by the device voice after the massage.
/// TODO before launch: replace device voice with recorded narration for quality.
struct Story: Identifiable, Hashable {
    let id: String
    let title: String
    let blurb: String
    let paragraphs: [String]

    var minutes: Int { max(3, paragraphs.joined(separator: " ").split(separator: " ").count / 110) }
}

enum StoryLibrary {
    static let all: [Story] = [otter, cloud, snow]

    static func story(_ id: String) -> Story { all.first { $0.id == id } ?? otter }

    static let otter = Story(
        id: "otter",
        title: "Sleepy Otter and the Cool River",
        blurb: "Cool water, soft moss and a slow, sleepy float.",
        paragraphs: [
            "Once upon a time, at the edge of a quiet forest, there was a little otter named Pip who loved the evening most of all.",
            "Every night, when the sky turned the color of blueberries, Pip slid down the soft grassy bank and into the cool, calm river.",
            "The water was gentle. It wrapped around Pip's paws, and then Pip's tummy, and then Pip's back, cool and smooth, like a soft blanket made of moonlight.",
            "Pip floated on her back and looked up. One star appeared. Then two. Then so many that Pip stopped counting and just breathed. In, slowly. And out, slowly.",
            "The river carried her past the tall reeds, which whispered shhh, shhh as she drifted by. A sleepy frog said goodnight. A firefly blinked a tiny lantern hello.",
            "At the bend in the river, there was a bed of soft green moss, cool and damp from the evening air. Pip climbed onto it and curled up, her tail tucked around her nose.",
            "Her skin felt calm. Her paws felt heavy. Her eyes felt heavy too.",
            "The river kept singing its quiet song, the same song it sang every night. Shhh. Shhh. Goodnight, little otter. Goodnight.",
            "And Pip, warm inside and cool outside, drifted off into the softest, deepest sleep."
        ]
    )

    static let cloud = Story(
        id: "cloud",
        title: "The Cloud That Kept Cool",
        blurb: "A soft cloud drifts over sleeping hills on a gentle breeze.",
        paragraphs: [
            "High above the hills lived a small white cloud named Wisp.",
            "Wisp's favorite job was keeping things cool. On warm evenings, Wisp would float over the meadow and let a gentle breeze tumble down, soft and fresh, onto everyone below.",
            "Tonight, the breeze drifted over a sleepy fox, who sighed and tucked in her paws. It drifted over a family of rabbits, who wiggled their noses and closed their eyes.",
            "It drifted through an open window, and across a cozy bed, where a child was getting ready to sleep. The breeze was cool on their arms and cool on their legs, like a gentle hand saying, it's okay, you can rest now.",
            "Wisp floated lower and lower, until it was resting on top of the tallest hill, like a pillow.",
            "The moon came up to say goodnight. Wisp breathed in, slow and soft. And out, slow and soft. Every breath sent another little breeze across the sleeping world.",
            "The meadow was quiet. The rabbits were quiet. The fox was quiet.",
            "And the child in the cozy bed was quiet too, drifting, drifting, all the way to sleep."
        ]
    )

    static let snow = Story(
        id: "snow",
        title: "Bear and the Quiet Snowfall",
        blurb: "Snowflakes fall softly while a little bear gets cozy.",
        paragraphs: [
            "In a little cabin under the pine trees lived a small bear named Bramble.",
            "One evening, Bramble pressed her nose to the window. Outside, snow had started to fall. Not a storm, just the quiet kind, one soft flake at a time.",
            "Each snowflake drifted down slowly, slowly, and landed without a sound on the branches, on the rooftop, on the path to the door.",
            "Bramble's mama wrapped her in a soft blanket and counted the snowflakes with her. One. Two. Three. Each number was slower and quieter than the last.",
            "The snow made the whole world hush. The trees stood still. The wind took a rest. Even the owl in the pine tree closed one eye, and then the other.",
            "Bramble felt cozy on the inside and calm on the outside, like the cool, soft snow resting on the hills.",
            "Her mama hummed a slow little song. Bramble's breathing grew slow too, in and out, in and out, as gentle as the falling snow.",
            "And as the last snowflake of the evening settled on the windowsill, little Bramble was fast asleep."
        ]
    )
}

/// A massage technique in the library.
struct MassageTechnique: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let steps: [String]
}

enum MassageLibrary {
    static let all: [MassageTechnique] = [
        MassageTechnique(
            id: "glide", title: "Moisturizer glide", detail: "For dry, calm skin",
            steps: ["Warm the lotion between your palms.",
                    "Use long, slow strokes in the direction the hair grows.",
                    "Keep pressure light and even. Let the lotion melt in."]),
        MassageTechnique(
            id: "pat", title: "Gentle patting", detail: "For flaring, itchy skin",
            steps: ["Never rub flaring skin.",
                    "Press lotion on with a soft, flat palm.",
                    "Hold for one slow breath, then lift. Skip broken or oozing skin."]),
        MassageTechnique(
            id: "creases", title: "Elbow and knee creases", detail: "The spots kids hate most",
            steps: ["Gently straighten the arm or leg.",
                    "Use fingertips to glide lotion into the crease.",
                    "If the crease is flaring, switch to patting."]),
        MassageTechnique(
            id: "itchCalm", title: "Itch-attack calm-down", detail: "2 minutes, for night waking",
            steps: ["Rest a cool, flat palm over the itchy area. Don't rub.",
                    "Breathe slowly together: in for 4, out for 6.",
                    "Gently hold their hands in yours to stop the scratching while you hum."]),
        MassageTechnique(
            id: "backCircles", title: "Slow back circles", detail: "Wind-down to sleep",
            steps: ["Rest your hand flat on their back.",
                    "Make big, slow circles.",
                    "Match your breathing to the music and slow down a little more each circle."])
    ]
}

/// One scene of tonight's ritual.
struct RitualStep: Identifiable, Hashable {
    enum Kind: Hashable { case warm, glide, pat, calm }
    let id = UUID()
    let kind: Kind
    /// Body area or moment, shown to the parent.
    let title: String
    let badge: String
    /// Short instruction for the parent's hands, shown on screen.
    let script: String
    /// The story the child hears. Spoken aloud.
    let narration: String
}

enum RitualBuilder {
    /// Builds tonight's massage story: one scene per area the parent tapped.
    static func steps(for zones: [CareZone: CareState],
                      story: MassageStory = MassageStoryLibrary.sleepyComet) -> [RitualStep] {
        var steps = [RitualStep(
            kind: .warm, title: "Warm the cream", badge: "Get ready",
            script: "Warm a generous amount of moisturizer between your palms. Prescribed cream first, exactly as directed.",
            narration: story.opening)]
        let areas = zones.isEmpty ? [CareZone.arms: CareState.dry, .legs: .dry, .back: .dry] : zones
        for zone in CareZone.allCases {
            guard let state = areas[zone] else { continue }
            steps.append(RitualStep(
                kind: state == .dry ? .glide : .pat,
                title: zone.label,
                badge: state == .dry ? "Glide · dry skin" : "Pat · flaring skin",
                script: state == .dry ? zone.glideScript : CareZone.patScript,
                narration: story.scene(for: zone, state: state)))
        }
        steps.append(RitualStep(
            kind: .calm, title: "Slow back circles", badge: "Wind down",
            script: "Big, slow circles on their back. Match your breathing to the music.",
            narration: story.closing + " Now, let's whisper together: " + story.affirmation))
        return steps
    }
}
