import Foundation

enum CareState: String, Codable {
    case dry, flaring

    var technique: String { self == .dry ? "Glide" : "Pat" }
    var label: String { self == .dry ? "Dry · glide" : "Flaring · pat" }

    var next: CareState? { self == .dry ? .flaring : nil }
}

enum CareZone: String, Codable, CaseIterable, Identifiable {
    case face, neck, arms, elbows, hands, tummy, back, legs, knees, feet

    var id: String { rawValue }

    var label: String {
        switch self {
        case .face: return "Face"
        case .neck: return "Neck"
        case .arms: return "Arms"
        case .elbows: return "Elbow creases"
        case .hands: return "Hands"
        case .tummy: return "Tummy & chest"
        case .back: return "Back"
        case .legs: return "Legs"
        case .knees: return "Behind knees"
        case .feet: return "Feet"
        }
    }

    /// Voice cue for dry skin.
    var glideScript: String {
        switch self {
        case .face: return "With one fingertip, sweep lotion gently across the cheeks and forehead, away from the eyes. Light as a feather."
        case .neck: return "Smooth lotion down the neck in soft, downward strokes. Slow and light."
        case .arms: return "Long, slow strokes from shoulder to wrist, in the direction the hair grows. Let the lotion melt in."
        case .elbows: return "Gently straighten the arm and glide lotion into the elbow crease with your fingertips."
        case .hands: return "Hold their hand in yours and glide lotion from the wrist to each fingertip."
        case .tummy: return "Rest your palms on the tummy and sweep slowly outward, like opening a book."
        case .back: return "Long strokes from the shoulders down to the waist, one hand after the other."
        case .legs: return "Long, slow strokes from hip to ankle, in the direction the hair grows."
        case .knees: return "Gently straighten the leg and glide lotion into the back of the knee."
        case .feet: return "Hold the foot and glide lotion from heel to toes with your thumbs."
        }
    }

    static let patScript = "No rubbing here. Press lotion on with a soft, flat palm, hold for one slow breath, then lift. Skip any broken or oozing skin."

    func script(for state: CareState) -> String {
        state == .dry ? glideScript : CareZone.patScript
    }
}
