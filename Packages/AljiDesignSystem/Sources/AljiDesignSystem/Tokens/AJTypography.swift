import SwiftUI
import CoreText

/// The ONE type system for the app, taken from the approved onboarding prototype.
///
/// Font family: Figtree (SIL Open Font License, bundled in Resources/Fonts) for
/// every piece of text. Every style is built on a `Font.TextStyle`, so it scales
/// with Dynamic Type.
///
/// Rules:
/// 1. Call `AJFonts.register()` once at app launch.
/// 2. Use `.ajText(_:)` for all text. Do not call `.font(...)` in app code.
/// 3. Only the weights below are allowed: regular, medium, semibold, bold, extrabold.
/// 4. Need a new size? Add a style here; never one-off it in a screen.
public enum AJTextStyle: CaseIterable {
    /// 44 pt extrabold. One big number per screen ("7 in 10", "−55 min").
    case stat
    /// 32 pt extrabold. Hero, paywall and celebration headlines.
    case display
    /// 29 pt extrabold. Screen titles and questions.
    case title
    /// 22 pt extrabold. Step titles in the ritual player, card headlines.
    case title2
    /// 19 pt bold. Primary button labels.
    case headline
    /// 18 pt regular. Paragraphs and answer options.
    case body
    /// 18 pt extrabold. Plan names and emphasized lines.
    case bodyStrong
    /// 17 pt semibold. Card titles, row titles, secondary buttons.
    case callout
    /// 15 pt regular. Feedback notes, supporting lines, list details.
    case subhead
    /// 13 pt regular. Sources, fine print, captions.
    case footnote
    /// 13 pt extrabold. Small badges and step names.
    case footnoteStrong
    /// 13 pt extrabold, tracked, uppercase. Eyebrows and badges.
    case label

    var size: CGFloat {
        switch self {
        case .stat: return 44
        case .display: return 32
        case .title: return 29
        case .title2: return 22
        case .headline: return 19
        case .body, .bodyStrong: return 18
        case .callout: return 17
        case .subhead: return 15
        case .footnote, .footnoteStrong, .label: return 13
        }
    }

    var textStyle: Font.TextStyle {
        switch self {
        case .stat, .display: return .largeTitle
        case .title: return .title
        case .title2: return .title2
        case .headline: return .headline
        case .body, .bodyStrong: return .body
        case .callout: return .callout
        case .subhead: return .subheadline
        case .footnote, .footnoteStrong: return .footnote
        case .label: return .caption
        }
    }

    var fontName: String {
        switch self {
        case .stat, .display, .title, .title2, .label, .bodyStrong, .footnoteStrong: return AJFonts.extraBold
        case .headline: return AJFonts.bold
        case .callout: return AJFonts.semiBold
        case .body, .subhead, .footnote: return AJFonts.regular
        }
    }

    /// Extra space between lines, in points (prototype line-height minus the font's own).
    var lineSpacing: CGFloat {
        switch self {
        case .stat: return 0
        case .display, .title, .title2: return 2
        case .body, .bodyStrong: return 6
        case .subhead: return 4
        case .footnote: return 4
        case .headline, .callout, .label, .footnoteStrong: return 0
        }
    }

    var tracking: CGFloat {
        switch self {
        case .label: return 0.6
        default: return 0
        }
    }

    var isUppercased: Bool { self == .label }

    /// The SwiftUI font for this style. Prefer `.ajText(_:)`.
    public var font: Font {
        .custom(fontName, size: size, relativeTo: textStyle)
    }

    /// Human-readable name, used by the catalog.
    public var name: String {
        switch self {
        case .stat: return "Stat"
        case .display: return "Display"
        case .title: return "Title"
        case .title2: return "Title 2"
        case .headline: return "Headline"
        case .body: return "Body"
        case .bodyStrong: return "Body strong"
        case .callout: return "Callout"
        case .subhead: return "Subhead"
        case .footnote: return "Footnote"
        case .footnoteStrong: return "Footnote strong"
        case .label: return "Label"
        }
    }
}

/// Registers the bundled Figtree files. Call once, before any view is shown.
public enum AJFonts {
    static let regular = "Figtree-Regular"
    static let medium = "Figtree-Medium"
    static let semiBold = "Figtree-SemiBold"
    static let bold = "Figtree-Bold"
    static let extraBold = "Figtree-ExtraBold"

    private static var didRegister = false

    public static func register() {
        guard !didRegister else { return }
        didRegister = true
        for name in [regular, medium, semiBold, bold, extraBold] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

private struct AJTextModifier: ViewModifier {
    let style: AJTextStyle
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
    func ajText(_ style: AJTextStyle, color: Color = AJColor.textPrimary) -> some View {
        modifier(AJTextModifier(style: style, color: color))
    }
}

public extension Text {
    /// For text drawn inside a `Canvas`, where view modifiers like `.ajText` can't be used.
    func ajCanvasText(_ style: AJTextStyle, color: Color = AJColor.textPrimary) -> Text {
        font(style.font).foregroundStyle(color)
    }
}
