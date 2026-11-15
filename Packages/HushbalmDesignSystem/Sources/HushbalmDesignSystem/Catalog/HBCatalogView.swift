import SwiftUI

/// A living reference of the design system. Open it in an Xcode preview,
/// or show it from a debug menu, to review every token and component.
public struct HBCatalogView: View {
    @State private var selectedLength = 10
    @State private var tileTone: HBStatusTile.Tone = .calm
    @State private var selectedStory = 0

    @State private var demoAnswer = 1
    @State private var demoName = ""
    @State private var demoPlan = 0
    @State private var demoChecked = true

    public init() { HBFonts.register() }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HBSpacing.xl) {
                HBScreenHeader(eyebrow: "Design system", title: "Hushbalm",
                               subtitle: "One font family, one palette, one set of components.", isHero: true)

                stars
                colors
                typography
                buttons
                onboarding
                paywall
                selection
                containers
            }
            .padding(.horizontal, HBSpacing.screenGutter)
            .padding(.vertical, HBSpacing.xl)
        }
        .background(HBColor.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Sections

    private var stars: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Stars", trailing: "Glow-sticker motif")
            HStack(spacing: HBSpacing.md) {
                HBStar(size: 32)
                HBStar(size: 24)
                HBStar(size: 32, isLit: false)
            }
            HBStarCeiling(total: 12, lit: 7)
            ZStack {
                RoundedRectangle(cornerRadius: HBRadius.xl, style: .continuous).fill(HBColor.background)
                HBStarField(count: 10, seed: 2)
            }
            .frame(height: 120)
        }
    }

    private var colors: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Color")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HBSpacing.sm) {
                ForEach(Swatch.all) { swatch in
                    HStack(spacing: HBSpacing.sm) {
                        RoundedRectangle(cornerRadius: HBRadius.sm, style: .continuous)
                            .fill(swatch.color)
                            .frame(width: 40, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: HBRadius.sm, style: .continuous)
                                .strokeBorder(HBColor.border, lineWidth: 1))
                        Text(swatch.name).hbText(.footnote)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Type · Figtree", trailing: "Scales with Dynamic Type")
            ForEach(HBTextStyle.allCases, id: \.self) { style in
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.name).hbText(.label, color: HBColor.textSecondary)
                    Text("Warm the cream in your hands").hbText(style)
                }
            }
        }
    }

    private var onboarding: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Onboarding")
            HBProgressBar(progress: 0.4)
            HBHighlightedTitle("How warm is *Maya's* room at night?")
            HBOptionRow("Cool", isSelected: demoAnswer == 0) { demoAnswer = 0 }
            HBOptionRow("Warm or stuffy", isSelected: demoAnswer == 1) { demoAnswer = 1 }
            HBFeedbackNote("Worth changing: heat and sweat are common itch triggers.")
            HBTextField("Name or nickname", text: $demoName)
            HBStat(value: "7 in 10", caption: "children with eczema have disrupted sleep.")
            HBSourceNote("Eczema Society of Canada caregiver survey.")
            HBComparisonBars(eyebrow: "Time to fall asleep", nowValue: "70 min",
                             goalLabel: "Goal with a nightly ritual", goalValue: "15 min", goalFraction: 15.0 / 70.0)
            HBResultCard(value: "−55 min", caption: "a night, back for you both.")
            HBTimelineRow(time: "7:08", title: "Massage story", detail: "10 min · moisturizer on damp skin", icon: .sparkles)
            HBTimelineRow(time: "7:30", title: "Asleep", detail: "Log tonight in 2 seconds", icon: .dim, tint: HBColor.accentCalm, isLast: true)
            HBChecklistRow("Lights dimmed", detail: "Warm lamps only", isDone: demoChecked) { demoChecked.toggle() }
        }
    }

    private var paywall: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Paywall")
            HBBenefitRow("Massage stories that guide your hands")
            HBBenefitRow("Bedtime stories and affirmations, screen-free")
            HBPlanCard(title: "Yearly", price: "$59.99 a year · $5 a month", badge: "3 days free", isSelected: demoPlan == 0) { demoPlan = 0 }
            HBPlanCard(title: "Monthly", price: "$9.99 a month", isSelected: demoPlan == 1) { demoPlan = 1 }
            HBTrialSteps([
                HBTrialStep(title: "Full access", when: "Today", icon: .sparkles, tint: HBColor.accentWarm),
                HBTrialStep(title: "We remind you", when: "Day 2", icon: .bell, tint: HBColor.accentCalm),
                HBTrialStep(title: "Billing starts", when: "Day 3", icon: .check, tint: HBColor.action)
            ])
            Button("Start my 3-day free trial") {}.buttonStyle(.hbPrimary)
            Button("Skip for now") {}.buttonStyle(.hbGhost)
        }
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Buttons")
            Button("Begin 10-min ritual") {}.buttonStyle(.hbPrimary)
            Button("Dim screen") {}.buttonStyle(.hbSecondary)
            Button("Skip tonight") {}.buttonStyle(.hbGhost)
            Button("Save and see report") {}.buttonStyle(.hbPrimary).disabled(true)
            HBIconButton(.back, accessibilityLabel: "Back") {}
        }
    }

    private var selection: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Selection")
            HStack(spacing: HBSpacing.xs) {
                ForEach([5, 10, 20], id: \.self) { minutes in
                    HBChip("\(minutes) min", isSelected: selectedLength == minutes) { selectedLength = minutes }
                }
            }
            HBStatusTile(title: "Behind knees", subtitle: subtitle(for: tileTone), tone: tileTone) {
                tileTone = next(after: tileTone)
            }
            HBRadioRow(title: "Sleepy Otter and the Cool River", subtitle: "Calm river sounds",
                       isSelected: selectedStory == 0) { selectedStory = 0 }
            HBRadioRow(title: "Yearly", subtitle: "7-day free trial", trailing: "$49.99",
                       isSelected: selectedStory == 1) { selectedStory = 1 }
        }
    }

    private var containers: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Containers & feedback")
            HBCard {
                HBSectionHeader("Where does skin need care?", trailing: "3 areas")
                Text("Tap once for dry, twice for flaring.").hbText(.footnote, color: HBColor.textSecondary)
            }
            HStack(spacing: HBSpacing.xs) {
                HBBadge("Glide · dry skin", tone: .calm)
                HBBadge("Pat · flaring", tone: .warm)
            }
            HBSegmentedProgress(total: 5, current: 2, fraction: 0.4)
            HBNotice("Using a prescribed cream? Apply it first, exactly as your doctor directed.")
        }
    }

    // MARK: Helpers

    private func next(after tone: HBStatusTile.Tone) -> HBStatusTile.Tone {
        switch tone {
        case .neutral: return .calm
        case .calm: return .warm
        case .warm: return .neutral
        }
    }

    private func subtitle(for tone: HBStatusTile.Tone) -> String {
        switch tone {
        case .neutral: return "Not tonight"
        case .calm: return "Dry · glide"
        case .warm: return "Flaring · pat"
        }
    }
}

private struct Swatch: Identifiable {
    let name: String
    let color: Color
    var id: String { name }

    static let all: [Swatch] = [
        Swatch(name: "background", color: HBColor.background),
        Swatch(name: "surface", color: HBColor.surface),
        Swatch(name: "surfaceRaised", color: HBColor.surfaceRaised),
        Swatch(name: "border", color: HBColor.border),
        Swatch(name: "textPrimary", color: HBColor.textPrimary),
        Swatch(name: "textSecondary", color: HBColor.textSecondary),
        Swatch(name: "accentCalm", color: HBColor.accentCalm),
        Swatch(name: "accentWarm", color: HBColor.accentWarm),
        Swatch(name: "action", color: HBColor.action),
        Swatch(name: "surfaceDeep", color: HBColor.surfaceDeep),
        Swatch(name: "textTertiary", color: HBColor.textTertiary),
        Swatch(name: "coral", color: HBColor.coral)
    ]
}

#Preview("Design system") {
    HBCatalogView()
}
