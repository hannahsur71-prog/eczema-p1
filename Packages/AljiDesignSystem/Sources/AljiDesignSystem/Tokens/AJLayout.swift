import SwiftUI

/// Spacing on a 4-point grid. Use these instead of raw numbers.
public enum AJSpacing {
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
public enum AJRadius {
    public static let sm: CGFloat = 12   // toggles, small controls
    public static let button: CGFloat = 14   // primary and secondary buttons, text fields
    public static let md: CGFloat = 16   // answer options, chips, notices
    public static let lg: CGFloat = 18   // rows, plan cards
    public static let xl: CGFloat = 20   // cards
}

/// Fixed control sizes.
public enum AJSize {
    /// Apple's minimum touch target.
    public static let minTouch: CGFloat = 44
    public static let buttonHeight: CGFloat = 60
    /// Answer option rows (single column).
    public static let optionMinHeight: CGFloat = 62
    /// Answer options in a two-column grid.
    public static let optionGridMinHeight: CGFloat = 54
    public static let rowMinHeight: CGFloat = 64
    public static let iconSmall: CGFloat = 18
    public static let iconMedium: CGFloat = 22
}

/// SF Symbols used by the app, so every screen uses the same icon for the same idea.
public enum AJIcon: String, CaseIterable {
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
    case screensOff = "tv.slash"
    case lightbulb = "lightbulb"
    case bath = "bathtub"
    case drop = "drop"
    case thermometer = "thermometer.low"
    case pajamas = "tshirt"
    case leaf = "leaf"
    case moon = "moon.fill"
    case plus = "plus"
    case apple = "apple.logo"
    case arrowDown = "arrow.down"
    case home = "house.fill"
    case stories = "book.fill"
    case progress = "chart.bar.fill"
    case chevronDown = "chevron.down"
    case heartOutline = "heart"
    case previous = "backward.end.fill"
    case timer = "timer"
    case text = "text.alignleft"
    case hourglass = "hourglass"
    case pencil = "pencil.and.outline"
    case speaker = "speaker.wave.2"
}

public extension Image {
    init(aj icon: AJIcon) {
        self.init(systemName: icon.rawValue)
    }
}

public extension View {
    /// Sizes and colors an SF Symbol the design-system way. Use instead of `.font(...)` on icons.
    func ajIcon(_ size: CGFloat = AJSize.iconSmall, color: Color = AJColor.textPrimary) -> some View {
        self
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
    }
}
