import SwiftUI

/// Spacing on a 4-point grid. Use these instead of raw numbers.
public enum HBSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
    /// Left/right padding of every screen.
    public static let screenGutter: CGFloat = 22
}

/// Corner radii. Continuous ("squircle") corners everywhere.
public enum HBRadius {
    public static let sm: CGFloat = 12   // toggles, small controls
    public static let md: CGFloat = 16   // chips in grids, inputs, notices
    public static let lg: CGFloat = 18   // buttons, rows
    public static let xl: CGFloat = 24   // cards
}

/// Fixed control sizes.
public enum HBSize {
    /// Apple's minimum touch target.
    public static let minTouch: CGFloat = 44
    public static let buttonHeight: CGFloat = 56
    public static let rowMinHeight: CGFloat = 64
    public static let iconSmall: CGFloat = 18
    public static let iconMedium: CGFloat = 22
}

/// SF Symbols used by the app, so every screen uses the same icon for the same idea.
public enum HBIcon: String, CaseIterable {
    case tonight = "moon.stars"
    case library = "books.vertical"
    case report = "chart.bar.doc.horizontal"
    case back = "chevron.left"
    case music = "music.note"
    case voice = "waveform"
    case lock = "lock.fill"
    case check = "checkmark"
    case info = "info.circle"
    case dim = "moon.zzz"
    case share = "square.and.arrow.up"
    case settings = "gearshape"
    case close = "xmark"
    case bell = "bell"
    case heart = "heart.fill"
    case star = "star.fill"
    case sparkles = "sparkles"
    case hands = "hands.and.sparkles"
    case play = "play.fill"
    case pause = "pause.fill"
    case forward = "forward.end.fill"
    case shield = "checkmark.shield"
}

public extension Image {
    init(hb icon: HBIcon) {
        self.init(systemName: icon.rawValue)
    }
}

public extension View {
    /// Sizes and colors an SF Symbol the design-system way. Use instead of `.font(...)` on icons.
    func hbIcon(_ size: CGFloat = HBSize.iconSmall, color: Color = HBColor.textPrimary) -> some View {
        self
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
    }
}
