import SwiftUI

/// Full-width buttons. Three kinds only.
/// - primary: one per screen, the main action (warm lotion fill).
/// - secondary: alternative actions (raised surface).
/// - ghost: low-emphasis actions like "Skip tonight" (text only).
public struct HBButtonStyle: ButtonStyle {
    public enum Kind { case primary, secondary, ghost }

    let kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    public init(_ kind: Kind) { self.kind = kind }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .hbText(kind == .primary ? .headline : .callout, color: foreground)
            .frame(maxWidth: .infinity, minHeight: HBSize.buttonHeight)
            .padding(.horizontal, HBSpacing.md)
            .background(background, in: RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        guard isEnabled else { return HBColor.textSecondary }
        switch kind {
        case .primary: return HBColor.onAccent
        case .secondary: return HBColor.textPrimary
        case .ghost: return HBColor.textSecondary
        }
    }

    private var background: Color {
        guard isEnabled else { return kind == .ghost ? .clear : HBColor.surfaceRaised }
        switch kind {
        case .primary: return HBColor.accentWarm
        case .secondary: return HBColor.surfaceRaised
        case .ghost: return .clear
        }
    }
}

public extension ButtonStyle where Self == HBButtonStyle {
    static var hbPrimary: HBButtonStyle { HBButtonStyle(.primary) }
    static var hbSecondary: HBButtonStyle { HBButtonStyle(.secondary) }
    static var hbGhost: HBButtonStyle { HBButtonStyle(.ghost) }
}

/// Square icon-only button (e.g. Back). Always give it an accessibility label.
public struct HBIconButton: View {
    let icon: HBIcon
    let accessibilityLabel: String
    let action: () -> Void

    public init(_ icon: HBIcon, accessibilityLabel: String, action: @escaping () -> Void) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(hb: icon)
                .font(.system(size: HBSize.iconSmall, weight: .semibold, design: .rounded))
                .foregroundStyle(HBColor.textPrimary)
                .frame(width: HBSize.minTouch, height: HBSize.minTouch)
                .background(HBColor.surface, in: RoundedRectangle(cornerRadius: HBRadius.sm, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
