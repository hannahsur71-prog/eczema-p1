import SwiftUI

// Onboarding and paywall parts, matching the approved prototype.
// Screens are built only from these; no one-off styling in app code.

/// A title where words wrapped in *asterisks* are highlighted in sky blue.
/// Example: `AJHighlightedTitle("How old is *Maya*?")`
public struct AJHighlightedTitle: View {
    let markup: String
    let style: AJTextStyle

    public init(_ markup: String, style: AJTextStyle = .title) {
        self.markup = markup
        self.style = style
    }

    public var body: some View {
        let parts = markup.components(separatedBy: "*")
        return parts.indices
            .reduce(Text("")) { result, index in
                index % 2 == 1
                    ? result + Text(parts[index]).foregroundStyle(AJColor.accentCalm)
                    : result + Text(parts[index])
            }
            .ajText(style)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(markup.replacingOccurrences(of: "*", with: ""))
    }
}

/// A quiz answer. Unselected: outlined surface. Selected: filled gold with dark text.
public struct AJOptionRow: View {
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
                Text(title).ajText(.body, color: isSelected ? AJColor.onAccent : AJColor.textPrimary)
                if let subtitle {
                    Text(subtitle).ajText(.footnote, color: isSelected ? AJColor.onAccent : AJColor.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, AJSpacing.sm)
            .frame(maxWidth: .infinity,
                   minHeight: isCompact ? AJSize.optionGridMinHeight : AJSize.optionMinHeight,
                   alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                    .fill(isSelected ? AJColor.accentWarm : AJColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                    .strokeBorder(isSelected ? AJColor.accentWarm : AJColor.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isMultiSelect ? "Select all that apply" : "")
    }
}

/// The short, tailored reply shown under an answer before Continue.
public struct AJFeedbackNote: View {
    let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(aj: .check).ajIcon(16, color: AJColor.accentCalm).accessibilityHidden(true)
            Text(text).ajText(.subhead)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, AJSpacing.sm)
        .background(AJColor.accentCalm.opacity(0.14), in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous)
                .strokeBorder(AJColor.accentCalm.opacity(0.6), lineWidth: 1.5)
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

/// Single-line text input (child's name, "Something else? Tell us").
public struct AJTextField: View {
    let placeholder: String
    @Binding var text: String

    public init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    public var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AJColor.textSecondary))
            .ajText(.body)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .padding(.horizontal, 18)
            .frame(minHeight: AJSize.optionMinHeight)
            .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous)
                    .strokeBorder(AJColor.accentCalm, lineWidth: 1.5)
            )
            .accessibilityLabel(placeholder)
    }
}

/// Onboarding progress: a sky-blue track with a gold moon thumb that travels as you go.
public struct AJProgressBar: View {
    let progress: Double

    public init(progress: Double) { self.progress = min(max(progress, 0), 1) }

    public var body: some View {
        GeometryReader { geo in
            let thumb: CGFloat = 36
            let travel = max(0, geo.size.width - thumb)
            ZStack(alignment: .leading) {
                Capsule().fill(AJColor.surfaceRaised).frame(height: 14)
                Capsule().fill(AJColor.accentCalm).frame(width: thumb / 2 + travel * progress, height: 14)
                Circle()
                    .fill(AJColor.accentWarm)
                    .frame(width: thumb, height: thumb)
                    .overlay(AJStar(size: 18).accessibilityHidden(true))
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
public struct AJStat: View {
    let value: String
    let caption: String
    let tone: AJBadge.Tone

    public init(value: String, caption: String, tone: AJBadge.Tone = .calm) {
        self.value = value
        self.caption = caption
        self.tone = tone
    }

    public var body: some View {
        VStack(spacing: AJSpacing.xxs) {
            Text(value).ajText(.stat, color: tone == .calm ? AJColor.accentCalm : AJColor.accentWarm)
            Text(caption).ajText(.callout).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// The source line under a research claim.
public struct AJSourceNote: View {
    let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text).ajText(.footnote, color: AJColor.textTertiary).frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A gold star with one short line, for paywall benefits. Three at most.
public struct AJBenefitRow: View {
    let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        HStack(alignment: .center, spacing: AJSpacing.sm) {
            AJStar(size: 20).accessibilityHidden(true)
            Text(text).ajText(.callout)
            Spacer(minLength: 0)
        }
    }
}

/// "Now" against "Goal" as two bars, so the benefit reads at a glance.
public struct AJComparisonBars: View {
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
            Text(eyebrow).ajText(.label, color: AJColor.textSecondary)
            bar(label: nowLabel, value: nowValue, valueColor: AJColor.coralText, fill: AJColor.coral, fraction: 1)
            bar(label: goalLabel, value: goalValue, valueColor: AJColor.accentCalm, fill: AJColor.accentCalm, fraction: goalFraction)
        }
        .padding(AJSpacing.md)
        .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func bar(label: String, value: String, valueColor: Color, fill: Color, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).ajText(.subhead)
                Spacer()
                Text(value).ajText(.callout, color: valueColor)
            }
            GeometryReader { geo in
                Capsule().fill(fill).frame(width: geo.size.width * fraction)
            }
            .frame(height: 18)
        }
    }
}

/// The hopeful result under a comparison: one big gold number and one line.
public struct AJResultCard: View {
    let value: String
    let caption: String

    public init(value: String, caption: String) {
        self.value = value
        self.caption = caption
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(value).ajText(.stat, color: AJColor.accentWarm)
            Text(caption).ajText(.callout).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(AJColor.hopeGradient, in: RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// One step of the bedtime plan: time on the left, a card on the right.
public struct AJTimelineRow: View {
    let time: String
    let title: String
    let detail: String
    let icon: AJIcon
    let tint: Color
    let isLast: Bool

    public init(time: String, title: String, detail: String, icon: AJIcon,
                tint: Color = AJColor.accentWarm, isLast: Bool = false) {
        self.time = time
        self.title = title
        self.detail = detail
        self.icon = icon
        self.tint = tint
        self.isLast = isLast
    }

    public var body: some View {
        HStack(alignment: .top, spacing: AJSpacing.sm) {
            VStack(spacing: AJSpacing.xxs) {
                Text(time).ajText(.footnote, color: AJColor.accentWarm)
                Rectangle()
                    .fill(isLast ? Color.clear : AJColor.borderQuiet)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 50)
            HStack(spacing: AJSpacing.sm) {
                Image(aj: icon)
                    .ajIcon(AJSize.iconMedium, color: tint)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: AJRadius.sm, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).ajText(.callout)
                    Text(detail).ajText(.footnote, color: AJColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(AJSpacing.sm)
            .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous))
            .overlay(alignment: .leading) {
                UnevenRoundedRectangle(topLeadingRadius: AJRadius.md, bottomLeadingRadius: AJRadius.md)
                    .fill(tint)
                    .frame(width: 4)
            }
            .padding(.bottom, 10)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A tick-off row for "Before we begin" and the bedroom checklist.
public struct AJChecklistRow: View {
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
                    .fill(isDone ? AJColor.accentCalm : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(isDone ? Color.clear : AJColor.border, lineWidth: 2)
                    )
                    .overlay(Image(aj: .check).ajIcon(14, color: AJColor.background).opacity(isDone ? 1 : 0))
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).ajText(.callout)
                    Text(detail).ajText(.footnote, color: AJColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: AJSize.rowMinHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                    .fill(isDone ? AJColor.accentCalm.opacity(0.14) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                    .strokeBorder(isDone ? AJColor.accentCalm : AJColor.borderQuiet, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isDone ? .isSelected : [])
    }
}

// MARK: - Paywall

/// A subscription plan. Yearly is preselected and carries the trial badge.
public struct AJPlanCard: View {
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
                    HStack(spacing: AJSpacing.xs) {
                        Text(title).ajText(.bodyStrong)
                        if let badge {
                            Text(badge)
                                .ajText(.footnoteStrong, color: AJColor.onAccent)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(AJColor.accentWarm, in: Capsule())
                        }
                    }
                    Text(price).ajText(.subhead, color: AJColor.textSecondary)
                }
                Spacer(minLength: 0)
                Circle()
                    .fill(isSelected ? AJColor.accentCalm : Color.clear)
                    .overlay(Circle().strokeBorder(isSelected ? Color.clear : AJColor.border, lineWidth: 2.5))
                    .overlay(Image(aj: .check).ajIcon(16, color: AJColor.background).opacity(isSelected ? 1 : 0))
                    .frame(width: 36, height: 36)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, AJSpacing.md)
            .padding(.vertical, AJSpacing.sm)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous)
                    .fill(isSelected ? AJColor.accentCalm.opacity(0.14) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous)
                    .strokeBorder(isSelected ? AJColor.accentCalm : AJColor.borderQuiet, lineWidth: isSelected ? 2 : 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One step of the trial: what happens and when ("Full access · Today").
public struct AJTrialStep: Identifiable {
    public let id = UUID()
    public let title: String
    public let when: String
    public let icon: AJIcon
    public let tint: Color

    public init(title: String, when: String, icon: AJIcon, tint: Color) {
        self.title = title
        self.when = when
        self.icon = icon
        self.tint = tint
    }
}

/// The trial shown as two or three steps in a row, so the charge date is never a surprise.
public struct AJTrialSteps: View {
    let steps: [AJTrialStep]

    public init(_ steps: [AJTrialStep]) { self.steps = steps }

    public var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(steps) { step in
                VStack(spacing: AJSpacing.xxs) {
                    Image(aj: step.icon)
                        .ajIcon(14, color: AJColor.background)
                        .frame(width: 30, height: 30)
                        .background(step.tint, in: Circle())
                        .accessibilityHidden(true)
                    Text(step.title).ajText(.footnoteStrong).multilineTextAlignment(.center)
                    Text(step.when).ajText(.footnote, color: AJColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Screen frame

/// The frame of every onboarding screen: back, progress, scrolling content, and the footer buttons.
public struct AJOnboardingScaffold<Content: View>: View {
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
                HStack(spacing: AJSpacing.xs) {
                    if let onBack {
                        AJIconButton(.back, accessibilityLabel: "Back", action: onBack)
                    }
                    if let progress {
                        AJProgressBar(progress: progress)
                    }
                }
                .padding(.horizontal, AJSpacing.md)
                .padding(.top, AJSpacing.xs)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.screenGutter) {
                    content
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.vertical, AJSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: AJSpacing.xs) {
                if let primaryTitle {
                    Button(primaryTitle, action: onPrimary)
                        .buttonStyle(.ajPrimary)
                        .disabled(!isPrimaryEnabled)
                }
                if let secondaryTitle, let onSecondary {
                    Button(secondaryTitle, action: onSecondary).buttonStyle(.ajGhost)
                }
            }
            .padding(.horizontal, AJSpacing.screenGutter)
            .padding(.top, 10)
            .padding(.bottom, AJSpacing.md)
        }
        .background(AJColor.background.ignoresSafeArea())
    }
}
