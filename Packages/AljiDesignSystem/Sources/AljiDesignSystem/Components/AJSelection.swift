import SwiftUI

/// A selectable pill: age groups, ritual length, library tabs, log tags.
public struct AJChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    public init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .ajText(.callout, color: isSelected ? AJColor.onAccent : AJColor.textPrimary)
                .padding(.horizontal, AJSpacing.md)
                .frame(minHeight: AJSize.minTouch)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                        .fill(isSelected ? AJColor.accentCalm : AJColor.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : AJColor.border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A two-line tile whose fill shows a state. Used for the body-area grid.
public struct AJStatusTile: View {
    public enum Tone { case neutral, calm, warm }

    let title: String
    let subtitle: String
    let tone: Tone
    let action: () -> Void

    public init(title: String, subtitle: String, tone: Tone, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).ajText(.callout, color: foreground)
                Text(subtitle).ajText(.footnote, color: tone == .neutral ? AJColor.textSecondary : AJColor.onAccent)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.horizontal, AJSpacing.sm)
            .background(RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                    .strokeBorder(tone == .neutral ? AJColor.border : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double-tap to change")
    }

    private var fill: Color {
        switch tone {
        case .neutral: return AJColor.background
        case .calm: return AJColor.accentCalm
        case .warm: return AJColor.accentWarm
        }
    }

    private var foreground: Color { tone == .neutral ? AJColor.textPrimary : AJColor.onAccent }
}

/// A full-width choice row with a radio indicator: stories, plans.
public struct AJRadioRow: View {
    let title: String
    let subtitle: String?
    let trailing: String?
    let isSelected: Bool
    let action: () -> Void

    public init(title: String, subtitle: String? = nil, trailing: String? = nil,
                isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: AJSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).ajText(.headline)
                    if let subtitle { Text(subtitle).ajText(.footnote, color: AJColor.textSecondary) }
                }
                Spacer(minLength: AJSpacing.xs)
                if let trailing { Text(trailing).ajText(.headline) }
                Circle()
                    .strokeBorder(isSelected ? AJColor.accentCalm : AJColor.border,
                                  lineWidth: isSelected ? 6 : 2)
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, AJSpacing.md)
            .frame(minHeight: AJSize.rowMinHeight)
            .background(
                RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous)
                    .fill(isSelected ? AJColor.surfaceRaised : AJColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous)
                    .strokeBorder(isSelected ? AJColor.accentCalm : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
