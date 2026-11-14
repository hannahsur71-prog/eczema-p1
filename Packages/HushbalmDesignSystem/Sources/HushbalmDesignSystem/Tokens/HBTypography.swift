import SwiftUI

/// The ONE type system for the app.
///
/// Font family: SF Pro Rounded (Apple's system font, `.rounded` design) for
/// every piece of text. It is soft and calm, ships with iOS (no font files or
/// licenses), and scales with Dynamic Type because every style is built on a
/// `Font.TextStyle`.
///
/// Rules:
/// 1. Use `.hbText(_:)` for all text. Do not call `.font(...)` in app code.
/// 2. Only the weights below are allowed: regular, semibold, bold, heavy.
/// 3. Need a new size? Add a style here; never one-off it in a screen.
public enum HBTextStyle: CaseIterable {
    /// 34 pt heavy. One per screen, hero headlines only (Welcome, Done).
    case display
    /// 28 pt heavy. Screen titles.
    case title
    /// 22 pt bold. Step titles in the ritual player.
    case title2
    /// 17 pt bold. Section headers, card titles, buttons.
    case headline
    /// 17 pt regular. Paragraphs and instructions.
    case body
    /// 16 pt semibold. Chips, row titles, secondary buttons.
    case callout
    /// 13 pt regular. Supporting text under titles.
    case footnote
    /// 12 pt bold, tracked, uppercase. Eyebrows ("STEP 1 OF 1") and badges.
    case label

    var textStyle: Font.TextStyle {
        switch self {
        case .display: return .largeTitle
        case .title: return .title
        case .title2: return .title2
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .label: return .caption
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .title: return .heavy
        case .title2, .headline, .label: return .bold
        case .callout: return .semibold
        case .body, .footnote: return .regular
        }
    }

    /// Extra space between lines, in points.
    var lineSpacing: CGFloat {
        switch self {
        case .display, .title, .title2: return 2
        case .body: return 5
        case .footnote: return 3
        case .headline, .callout, .label: return 0
        }
    }

    var tracking: CGFloat {
        switch self {
        case .label: return 0.6
        case .display, .title: return -0.2
        default: return 0
        }
    }

    var isUppercased: Bool { self == .label }

    /// The SwiftUI font for this style. Prefer `.hbText(_:)`.
    public var font: Font {
        .system(textStyle, design: .rounded, weight: weight)
    }

    /// Human-readable name, used by the catalog.
    public var name: String {
        switch self {
        case .display: return "Display"
        case .title: return "Title"
        case .title2: return "Title 2"
        case .headline: return "Headline"
        case .body: return "Body"
        case .callout: return "Callout"
        case .footnote: return "Footnote"
        case .label: return "Label"
        }
    }
}

private struct HBTextModifier: ViewModifier {
    let style: HBTextStyle
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
            .textCase(style.isUppercased ? .uppercase : nil)
            .foregroundStyle(color)
    }
}

public extension View {
    /// Applies a design-system text style. The only way text should be styled.
    func hbText(_ style: HBTextStyle, color: Color = HBColor.textPrimary) -> some View {
        modifier(HBTextModifier(style: style, color: color))
    }
}
