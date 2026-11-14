import SwiftUI

/// A selectable pill: age groups, ritual length, library tabs, log tags.
public struct HBChip: View {
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
                .hbText(.callout, color: isSelected ? HBColor.onAccent : HBColor.textPrimary)
                .padding(.horizontal, HBSpacing.md)
                .frame(minHeight: HBSize.minTouch)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous)
                        .fill(isSelected ? HBColor.accentCalm : HBColor.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : HBColor.border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A two-line tile whose fill shows a state. Used for the body-area grid.
public struct HBStatusTile: View {
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
                Text(title).hbText(.callout, color: foreground)
                Text(subtitle).hbText(.footnote, color: tone == .neutral ? HBColor.textSecondary : HBColor.onAccent)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .padding(.horizontal, HBSpacing.sm)
            .background(RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous)
                    .strokeBorder(tone == .neutral ? HBColor.border : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double-tap to change")
    }

    private var fill: Color {
        switch tone {
        case .neutral: return HBColor.background
        case .calm: return HBColor.accentCalm
        case .warm: return HBColor.accentWarm
        }
    }

    private var foreground: Color { tone == .neutral ? HBColor.textPrimary : HBColor.onAccent }
}

/// A full-width choice row with a radio indicator: stories, plans.
public struct HBRadioRow: View {
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
            HStack(spacing: HBSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).hbText(.headline)
                    if let subtitle { Text(subtitle).hbText(.footnote, color: HBColor.textSecondary) }
                }
                Spacer(minLength: HBSpacing.xs)
                if let trailing { Text(trailing).hbText(.headline) }
                Circle()
                    .strokeBorder(isSelected ? HBColor.accentCalm : HBColor.border,
                                  lineWidth: isSelected ? 6 : 2)
                    .frame(width: 22, height: 22)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, HBSpacing.md)
            .frame(minHeight: HBSize.rowMinHeight)
            .background(
                RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous)
                    .fill(isSelected ? HBColor.surfaceRaised : HBColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous)
                    .strokeBorder(isSelected ? HBColor.accentCalm : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
