import SwiftUI

/// Full-width buttons. Three kinds only.
/// - primary: one per screen, the main action (sky blue fill).
/// - secondary: alternative actions (outlined).
/// - ghost: low-emphasis actions like "Skip for now" (underlined text only).
public struct AJButtonStyle: ButtonStyle {
    public enum Kind { case primary, secondary, ghost }

    let kind: Kind
    @Environment(\.isEnabled) private var isEnabled

    public init(_ kind: Kind) { self.kind = kind }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .ajText(kind == .primary ? .headline : .callout, color: foreground)
            .underline(kind == .ghost)
            .frame(maxWidth: .infinity, minHeight: kind == .ghost ? AJSize.minTouch : AJSize.buttonHeight)
            .padding(.horizontal, AJSpacing.md)
            .background(background, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous)
                    .strokeBorder(kind == .secondary ? AJColor.borderQuiet : Color.clear, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch kind {
        case .primary: return isEnabled ? AJColor.onAction : AJColor.onActionDisabled
        case .secondary: return isEnabled ? AJColor.textPrimary : AJColor.textTertiary
        case .ghost: return isEnabled ? AJColor.textPrimary : AJColor.textTertiary
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return isEnabled ? AJColor.action : AJColor.actionDisabled
        case .secondary, .ghost: return .clear
        }
    }
}

public extension ButtonStyle where Self == AJButtonStyle {
    static var ajPrimary: AJButtonStyle { AJButtonStyle(.primary) }
    static var ajSecondary: AJButtonStyle { AJButtonStyle(.secondary) }
    static var ajGhost: AJButtonStyle { AJButtonStyle(.ghost) }
}

/// Square icon-only button (e.g. Back). Always give it an accessibility label.
public struct AJIconButton: View {
    let icon: AJIcon
    let accessibilityLabel: String
    let action: () -> Void

    public init(_ icon: AJIcon, accessibilityLabel: String, action: @escaping () -> Void) {
        self.icon = icon
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(aj: icon)
                .font(.system(size: AJSize.iconSmall, weight: .semibold))
                .foregroundStyle(AJColor.textPrimary)
                .frame(width: AJSize.minTouch, height: AJSize.minTouch)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
