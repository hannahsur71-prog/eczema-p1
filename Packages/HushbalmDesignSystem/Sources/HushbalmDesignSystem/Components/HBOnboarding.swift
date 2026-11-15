import SwiftUI

// Onboarding and paywall parts, matching the approved prototype.
// Screens are built only from these; no one-off styling in app code.

/// A title where words wrapped in *asterisks* are highlighted in sky blue.
/// Example: `HBHighlightedTitle("How old is *Maya*?")`
public struct HBHighlightedTitle: View {
    let markup: String
    let style: HBTextStyle

    public init(_ markup: String, style: HBTextStyle = .title) {
        self.markup = markup
        self.style = style
    }

    public var body: some View {
        let parts = markup.components(separatedBy: "*")
        return parts.indices
            .reduce(Text("")) { result, index in
                index % 2 == 1
                    ? result + Text(parts[index]).foregroundStyle(HBColor.accentCalm)
                    : result + Text(parts[index])
            }
            .hbText(style)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(markup.replacingOccurrences(of: "*", with: ""))
    }
}

/// A quiz answer. Unselected: outlined surface. Selected: filled gold with dark text.
public struct HBOptionRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let isMultiSelect: Bool
    let isCompact: Bool
    let action: () -> Void

    public init(_ title: String, subtitle: String? = nil, isSelected: Bool,
                isMultiSelect: Bool = false, isCompact: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.isMultiSelect = isMultiSelect
        self.isCompact = isCompact
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).hbText(.body, color: isSelected ? HBColor.onAccent : HBColor.textPrimary)
                if let subtitle {
                    Text(subtitle).hbText(.footnote, color: isSelected ? HBColor.onAccent : HBColor.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, HBSpacing.sm)
            .frame(maxWidth: .infinity,
                   minHeight: isCompact ? HBSize.optionGridMinHeight : HBSize.optionMinHeight,
                   alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous)
                    .fill(isSelected ? HBColor.accentWarm : HBColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous)
                    .strokeBorder(isSelected ? HBColor.accentWarm : HBColor.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isMultiSelect ? "Select all that apply" : "")
    }
}

/// The short, tailored reply shown under an answer before Continue.
public struct HBFeedbackNote: View {
    let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(hb: .check).hbIcon(16, color: HBColor.accentCalm).accessibilityHidden(true)
            Text(text).hbText(.subhead)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, HBSpacing.sm)
        .background(HBColor.accentCalm.opacity(0.14), in: RoundedRectangle(cornerRadius: HBRadius.button, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HBRadius.button, style: .continuous)
                .strokeBorder(HBColor.accentCalm.opacity(0.6), lineWidth: 1.5)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

/// Single-line text input (child's name, "Something else? Tell us").
public struct HBTextField: View {
    let placeholder: String
    @Binding var text: String

    public init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(HBColor.textSecondary))
            .hbText(.body)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .padding(.horizontal, 18)
            .frame(minHeight: HBSize.optionMinHeight)
            .background(HBColor.surface, in: RoundedRectangle(cornerRadius: HBRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: HBRadius.button, style: .continuous)
                    .strokeBorder(HBColor.accentCalm, lineWidth: 1.5)
            )
            .accessibilityLabel(placeholder)
    }
}

/// Onboarding progress: a sky-blue track with a gold moon thumb that travels as you go.
public struct HBProgressBar: View {
    let progress: Double

    public init(progress: Double) { self.progress = min(max(progress, 0), 1) }

    public var body: some View {
        GeometryReader { geo in
            let thumb: CGFloat = 36
            let travel = max(0, geo.size.width - thumb)
            ZStack(alignment: .leading) {
                Capsule().fill(HBColor.surfaceRaised).frame(height: 14)
                Capsule().fill(HBColor.accentCalm).frame(width: thumb / 2 + travel * progress, height: 14)
                Circle()
                    .fill(HBColor.accentWarm)
                    .frame(width: thumb, height: thumb)
                    .overlay(HBStar(size: 18).accessibilityHidden(true))
                    .shadow(color: .black.opacity(0.35), radius: 5, y: 2)
                    .offset(x: travel * progress)
            }
            .frame(height: thumb)
        }
        .frame(height: 36)
        .animation(.easeInOut(duration: 0.35), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

/// One big number with a caption, centered. One per screen.
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
        VStack(spacing: HBSpacing.xxs) {
            Text(value).hbText(.stat, color: tone == .calm ? HBColor.accentCalm : HBColor.accentWarm)
            Text(caption).hbText(.callout).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// The source line under a research claim.
public struct HBSourceNote: View {
    let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text).hbText(.footnote, color: HBColor.textTertiary).frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A gold star with one short line, for paywall benefits. Three at most.
public struct HBBenefitRow: View {
    let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        HStack(alignment: .center, spacing: HBSpacing.sm) {
            HBStar(size: 20).accessibilityHidden(true)
            Text(text).hbText(.callout)
            Spacer(minLength: 0)
        }
    }
}

/// "Now" against "Goal" as two bars, so the benefit reads at a glance.
public struct HBComparisonBars: View {
    let eyebrow: String
    let nowLabel: String
    let nowValue: String
    let goalLabel: String
    let goalValue: String
    /// Goal bar length as a share of the "now" bar, 0...1.
    let goalFraction: Double

    public init(eyebrow: String, nowLabel: String = "Now", nowValue: String,
                goalLabel: String, goalValue: String, goalFraction: Double) {
        self.eyebrow = eyebrow
        self.nowLabel = nowLabel
        self.nowValue = nowValue
        self.goalLabel = goalLabel
        self.goalValue = goalValue
        self.goalFraction = min(max(goalFraction, 0.12), 1)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(eyebrow).hbText(.label, color: HBColor.textSecondary)
            bar(label: nowLabel, value: nowValue, valueColor: HBColor.coralText, fill: HBColor.coral, fraction: 1)
            bar(label: goalLabel, value: goalValue, valueColor: HBColor.accentCalm, fill: HBColor.accentCalm, fraction: goalFraction)
        }
        .padding(HBSpacing.md)
        .background(HBColor.surface, in: RoundedRectangle(cornerRadius: HBRadius.xl, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func bar(label: String, value: String, valueColor: Color, fill: Color, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).hbText(.subhead)
                Spacer()
                Text(value).hbText(.callout, color: valueColor)
            }
            GeometryReader { geo in
                Capsule().fill(fill).frame(width: geo.size.width * fraction)
            }
            .frame(height: 18)
        }
    }
}

/// The hopeful result under a comparison: one big gold number and one line.
public struct HBResultCard: View {
    let value: String
    let caption: String

    public init(value: String, caption: String) {
        self.value = value
        self.caption = caption
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(value).hbText(.stat, color: HBColor.accentWarm)
            Text(caption).hbText(.callout).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(HBColor.hopeGradient, in: RoundedRectangle(cornerRadius: HBRadius.xl, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// One step of the bedtime plan: time on the left, a card on the right.
public struct HBTimelineRow: View {
    let time: String
    let title: String
    let detail: String
    let icon: HBIcon
    let tint: Color
    let isLast: Bool

    public init(time: String, title: String, detail: String, icon: HBIcon,
                tint: Color = HBColor.accentWarm, isLast: Bool = false) {
        self.time = time
        self.title = title
        self.detail = detail
        self.icon = icon
        self.tint = tint
        self.isLast = isLast
    }

    public var body: some View {
        HStack(alignment: .top, spacing: HBSpacing.sm) {
            VStack(spacing: HBSpacing.xxs) {
                Text(time).hbText(.footnote, color: HBColor.accentWarm)
                Rectangle()
                    .fill(isLast ? Color.clear : HBColor.borderQuiet)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 50)
            HStack(spacing: HBSpacing.sm) {
                Image(hb: icon)
                    .hbIcon(HBSize.iconMedium, color: tint)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: HBRadius.sm, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).hbText(.callout)
                    Text(detail).hbText(.footnote, color: HBColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(HBSpacing.sm)
            .background(HBColor.surface, in: RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous))
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(topLeadingRadius: HBRadius.md, bottomLeadingRadius: HBRadius.md)
                    .fill(tint)
                    .frame(width: 4)
            }
            .padding(.bottom, 10)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A tick-off row for "Before we begin" and the bedroom checklist.
public struct HBChecklistRow: View {
    let title: String
    let detail: String
    let isDone: Bool
    let action: () -> Void

    public init(_ title: String, detail: String, isDone: Bool, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.isDone = isDone
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isDone ? HBColor.accentCalm : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(isDone ? Color.clear : HBColor.border, lineWidth: 2)
                    )
                    .overlay(Image(hb: .check).hbIcon(14, color: HBColor.background).opacity(isDone ? 1 : 0))
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).hbText(.callout)
                    Text(detail).hbText(.footnote, color: HBColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: HBSize.rowMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous)
                    .fill(isDone ? HBColor.accentCalm.opacity(0.14) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous)
                    .strokeBorder(isDone ? HBColor.accentCalm : HBColor.borderQuiet, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isDone ? .isSelected : [])
    }
}

// MARK: - Paywall

/// A subscription plan. Yearly is preselected and carries the trial badge.
public struct HBPlanCard: View {
    let title: String
    let price: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    public init(title: String, price: String, badge: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.price = price
        self.badge = badge
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: HBSpacing.xs) {
                        Text(title).hbText(.bodyStrong)
                        if let badge {
                            Text(badge)
                                .hbText(.footnoteStrong, color: HBColor.onAccent)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(HBColor.accentWarm, in: Capsule())
                        }
                    }
                    Text(price).hbText(.subhead, color: HBColor.textSecondary)
                }
                Spacer(minLength: 0)
                Circle()
                    .fill(isSelected ? HBColor.accentCalm : Color.clear)
                    .overlay(Circle().strokeBorder(isSelected ? Color.clear : HBColor.border, lineWidth: 2.5))
                    .overlay(Image(hb: .check).hbIcon(16, color: HBColor.background).opacity(isSelected ? 1 : 0))
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, HBSpacing.md)
            .padding(.vertical, HBSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous)
                    .fill(isSelected ? HBColor.accentCalm.opacity(0.14) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous)
                    .strokeBorder(isSelected ? HBColor.accentCalm : HBColor.borderQuiet, lineWidth: isSelected ? 2 : 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One step of the trial: what happens and when ("Full access · Today").
public struct HBTrialStep: Identifiable {
    public let id = UUID()
    public let title: String
    public let when: String
    public let icon: HBIcon
    public let tint: Color

    public init(title: String, when: String, icon: HBIcon, tint: Color) {
        self.title = title
        self.when = when
        self.icon = icon
        self.tint = tint
    }
}

/// The trial shown as two or three steps in a row, so the charge date is never a surprise.
public struct HBTrialSteps: View {
    let steps: [HBTrialStep]

    public init(_ steps: [HBTrialStep]) { self.steps = steps }

    public var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(steps) { step in
                VStack(spacing: HBSpacing.xxs) {
                    Image(hb: step.icon)
                        .hbIcon(14, color: HBColor.background)
                        .frame(width: 30, height: 30)
                        .background(step.tint, in: Circle())
                        .accessibilityHidden(true)
                    Text(step.title).hbText(.footnoteStrong).multilineTextAlignment(.center)
                    Text(step.when).hbText(.footnote, color: HBColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Screen frame

/// The frame of every onboarding screen: back, progress, scrolling content, and the footer buttons.
public struct HBOnboardingScaffold<Content: View>: View {
    let progress: Double?
    let onBack: (() -> Void)?
    let primaryTitle: String?
    let isPrimaryEnabled: Bool
    let onPrimary: () -> Void
    let secondaryTitle: String?
    let onSecondary: (() -> Void)?
    let content: Content

    public init(progress: Double? = nil,
                onBack: (() -> Void)? = nil,
                primaryTitle: String? = "Continue",
                isPrimaryEnabled: Bool = true,
                onPrimary: @escaping () -> Void = {},
                secondaryTitle: String? = nil,
                onSecondary: (() -> Void)? = nil,
                @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.onBack = onBack
        self.primaryTitle = primaryTitle
        self.isPrimaryEnabled = isPrimaryEnabled
        self.onPrimary = onPrimary
        self.secondaryTitle = secondaryTitle
        self.onSecondary = onSecondary
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            if progress != nil || onBack != nil {
                HStack(spacing: HBSpacing.xs) {
                    if let onBack {
                        HBIconButton(.back, accessibilityLabel: "Back", action: onBack)
                    }
                    if let progress {
                        HBProgressBar(progress: progress)
                    }
                }
                .padding(.horizontal, HBSpacing.md)
                .padding(.top, HBSpacing.xs)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: HBSpacing.screenGutter) {
                    content
                }
                .padding(.horizontal, HBSpacing.screenGutter)
                .padding(.vertical, HBSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: HBSpacing.xs) {
                if let primaryTitle {
                    Button(primaryTitle, action: onPrimary)
                        .buttonStyle(.hbPrimary)
                        .disabled(!isPrimaryEnabled)
                }
                if let secondaryTitle, let onSecondary {
                    Button(secondaryTitle, action: onSecondary).buttonStyle(.hbGhost)
                }
            }
            .padding(.horizontal, HBSpacing.screenGutter)
            .padding(.top, 10)
            .padding(.bottom, HBSpacing.md)
        }
        .background(HBColor.background.ignoresSafeArea())
    }
}
