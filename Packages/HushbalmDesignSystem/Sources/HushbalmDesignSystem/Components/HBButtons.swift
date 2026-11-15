import SwiftUI

/// Full-width buttons. Three kinds only.
/// - primary: one per screen, the main action (sky blue fill).
/// - secondary: alternative actions (outlined).
/// - ghost: low-emphasis actions like "Skip for now" (underlined text only).
public struct HBButtonStyle: ButtonStyle {
    public enum Kind { case primary, secondary, ghost }

    let kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    public init(_ kind: Kind) { self.kind = kind }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .hbText(kind == .primary ? .headline : .callout, color: foreground)
            .underline(kind == .ghost)
            .frame(maxWidth: .infinity, minHeight: kind == .ghost ? HBSize.minTouch : HBSize.buttonHeight)
            .padding(.horizontal, HBSpacing.md)
            .background(background, in: RoundedRectangle(cornerRadius: HBRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HBRadius.button, style: .continuous)
                    .strokeBorder(kind == .secondary ? HBColor.borderQuiet : Color.clear, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch kind {
        case .primary: return isEnabled ? HBColor.onAction : HBColor.onActionDisabled
        case .secondary: return isEnabled ? HBColor.textPrimary : HBColor.textTertiary
        case .ghost: return isEnabled ? HBColor.textPrimary : HBColor.textTertiary
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return isEnabled ? HBColor.action : HBColor.actionDisabled
        case .secondary, .ghost: return .clear
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
                .font(.system(size: HBSize.iconSmall, weight: .semibold))
                .foregroundStyle(HBColor.textPrimary)
                .frame(width: HBSize.minTouch, height: HBSize.minTouch)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
