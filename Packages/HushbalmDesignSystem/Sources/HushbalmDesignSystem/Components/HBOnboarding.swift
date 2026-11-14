import SwiftUI

/// A quiz answer row. Single-select shows a radio, multi-select a checkbox.
public struct HBOptionRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isMultiSelect: Bool
    let action: () -> Void

    public init(_ title: String, subtitle: String? = nil, isSelected: Bool,
                isMultiSelect: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isMultiSelect = isMultiSelect
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: HBSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).hbText(.callout)
                    if let subtitle { Text(subtitle).hbText(.footnote, color: HBColor.textSecondary) }
                }
                Spacer(minLength: HBSpacing.xs)
                indicator.accessibilityHidden(true)
            }
            .padding(.horizontal, HBSpacing.md)
            .padding(.vertical, HBSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
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

    @ViewBuilder private var indicator: some View {
        if isMultiSelect {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? HBColor.accentCalm : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : HBColor.border, lineWidth: 2)
                )
                .overlay(
                    Image(hb: .check)
                        .hbIcon(12, color: HBColor.onAccent)
                        .opacity(isSelected ? 1 : 0)
                )
                .frame(width: 22, height: 22)
        } else {
            Circle()
                .strokeBorder(isSelected ? HBColor.accentCalm : HBColor.border, lineWidth: isSelected ? 6 : 2)
                .frame(width: 22, height: 22)
        }
    }
}

/// Thin progress bar shown at the top of onboarding.
public struct HBProgressBar: View {
    let progress: Double

    public init(progress: Double) { self.progress = min(max(progress, 0), 1) }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(HBColor.surfaceRaised)
                Capsule().fill(HBColor.accentCalm).frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.3), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

/// Big number + caption, for results and stats.
public struct HBStat: View {
    let value: String
    let caption: String
    let tone: HBBadge.Tone

    public init(value: String, caption: String, tone: HBBadge.Tone = .calm) {
        self.value = value
        self.caption = caption
        self.tone = tone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.xxs) {
            Text(value).hbText(.display, color: tone == .calm ? HBColor.accentCalm : HBColor.accentWarm)
            Text(caption).hbText(.footnote, color: HBColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A checkmark bullet with text, for benefit lists.
public struct HBBenefitRow: View {
    let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        HStack(alignment: .top, spacing: HBSpacing.sm) {
            Image(hb: .check)
                .hbIcon(14, color: HBColor.onAccent)
                .frame(width: 24, height: 24)
                .background(HBColor.accentCalm, in: Circle())
                .accessibilityHidden(true)
            Text(text).hbText(.body)
            Spacer(minLength: 0)
        }
    }
}
