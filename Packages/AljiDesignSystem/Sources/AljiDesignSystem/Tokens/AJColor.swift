import SwiftUI

/// Color tokens, taken from the approved onboarding prototype.
/// The app is dark-first because it is used at bedtime.
/// App code uses these tokens only — never raw hex values or system colors.
///
/// Contrast (WCAG 2.1), measured on `background`:
/// - textPrimary: 15.6:1 · textSecondary: 9.6:1 · textTertiary: 6.7:1
/// - onAccent on accentWarm (gold): 10.6:1
/// - onAction (white) on action (sky blue): 2.1:1. This matches the prototype but is
///   below the 3:1 minimum for large text. To pass, set `action` to 0x1E8FBF.
public enum AJColor {
    // MARK: Surfaces
    /// Night indigo. Screen background.
    public static let background = Color(hex: 0x1D1A45)
    /// Cards, option rows, inputs.
    public static let surface = Color(hex: 0x36305E)
    /// Raised or selected neutral surfaces, tracks.
    public static let surfaceRaised = Color(hex: 0x453F7A)
    /// Deep blue card, for "what's next" and plan summaries.
    public static let surfaceDeep = Color(hex: 0x24356B)
    /// Outline of option rows and inputs (white at 60%).
    public static let border = Color(hex: 0xFFFFFF, opacity: 0.6)
    /// Quiet outline of cards and dividers (white at 35%).
    public static let borderQuiet = Color(hex: 0xFFFFFF, opacity: 0.35)
    /// Decorative fills (illustrations, inactive dots). Never for text.
    public static let decor = Color(hex: 0x2B2760)

    // MARK: Text
    public static let textPrimary = Color(hex: 0xFFFFFF)
    public static let textSecondary = Color(hex: 0xC9C6E6)
    /// Sources, fine print, captions.
    public static let textTertiary = Color(hex: 0xA9A5D1)
    /// Text placed on gold (`accentWarm`) fills.
    public static let onAccent = Color(hex: 0x2A2350)
    /// Text placed on the primary button (`action`).
    public static let onAction = Color(hex: 0xFFFFFF)
    /// Only for text on the fully dimmed (black) screen.
    public static let textDimmed = Color(hex: 0xA9A5D1)

    // MARK: Accents
    /// Sky blue: highlighted words in titles, progress, checks, selection outlines.
    public static let accentCalm = Color(hex: 0x5EC2E6)
    /// Gold: selected answers, stars, the moon, badges.
    public static let accentWarm = Color(hex: 0xF4DE90)
    /// Primary button fill. One per screen.
    public static let action = Color(hex: 0x55BCE0)
    /// Disabled primary button.
    public static let actionDisabled = Color(hex: 0x2F5A78)
    public static let onActionDisabled = Color(hex: 0x8FA9BC)
    /// Coral: "now" bars, hard-night data, gentle warnings. Never for errors alone.
    public static let coral = Color(hex: 0xE0857A)
    /// Soft coral text on dark, paired with `coral` fills.
    public static let coralText = Color(hex: 0xF5C3BB)

    // MARK: Gradients
    /// Hopeful result cards ("Alji's goal for you", "time back").
    public static let hopeGradient = LinearGradient(
        colors: [Color(hex: 0x2E5E8C), Color(hex: 0x5A4BA8)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: Special
    /// Full-black screen used when the phone is set down during a ritual.
    public static let dimmed = Color.black
}

public extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0x1D1A45)`.
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
