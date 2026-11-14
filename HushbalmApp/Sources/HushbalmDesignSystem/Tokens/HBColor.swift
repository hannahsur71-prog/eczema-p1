import SwiftUI

/// Color tokens. The app is dark-first because it is used at bedtime.
/// App code uses these tokens only — never raw hex values or system colors.
///
/// Contrast (WCAG 2.1):
/// - textPrimary on background / surface: > 12:1
/// - textSecondary on background / surface: > 7:1
/// - onAccent (background color) on accentCalm / accentWarm: > 8:1
public enum HBColor {
    // MARK: Surfaces
    /// Night sky. Screen background.
    public static let background = Color(hex: 0x0E1430)
    /// Cards, rows, inputs.
    public static let surface = Color(hex: 0x182046)
    /// Selected cards, secondary buttons, tracks.
    public static let surfaceRaised = Color(hex: 0x222B57)
    /// Hairlines and unselected outlines.
    public static let border = Color(hex: 0x2E3870)
    /// Decorative fills (illustrations, inactive dots). Never for text.
    public static let decor = Color(hex: 0x2B3570)

    // MARK: Text
    public static let textPrimary = Color(hex: 0xEEF0FA)
    public static let textSecondary = Color(hex: 0xAEB5D6)
    /// Text placed on accentCalm or accentWarm fills.
    public static let onAccent = Color(hex: 0x0E1430)
    /// Only for text on the fully dimmed (black) screen.
    public static let textDimmed = Color(hex: 0x7C83A8)

    // MARK: Accents (blue/orange so they differ in lightness, not hue alone)
    /// Calm blue: selection, "dry skin · glide", progress.
    public static let accentCalm = Color(hex: 0x9DB2FF)
    /// Warm lotion: primary actions, "flaring skin · pat", gentle warnings.
    public static let accentWarm = Color(hex: 0xF4BE8A)

    // MARK: Special
    /// Full-black screen used when the phone is set down during a ritual.
    public static let dimmed = Color.black
}

public extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0x0E1430)`.
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
