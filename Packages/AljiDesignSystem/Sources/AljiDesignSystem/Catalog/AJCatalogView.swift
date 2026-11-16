import SwiftUI

/// A living reference of the design system. Open it in an Xcode preview,
/// or show it from a debug menu, to review every token and component.
public struct AJCatalogView: View {
    @State private var selectedLength = 10
    @State private var tileTone: AJStatusTile.Tone = .calm
    @State private var selectedStory = 0

    @State private var demoAnswer = 1
    @State private var demoName = ""
    @State private var demoPlan = 0
    @State private var demoChecked = true
    @State private var demoChip = 0
    @State private var demoSwitch = true
    @State private var demoShort = true

    public init() { AJFonts.register() }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AJSpacing.xl) {
                AJScreenHeader(eyebrow: "Design system", title: "Snuzzle",
                               subtitle: "One font family, one palette, one set of components.", isHero: true)

                stars
                colors
                typography
                buttons
                onboarding
                paywall
                mainApp
                selection
                containers
            }
            .padding(.horizontal, AJSpacing.screenGutter)
            .padding(.vertical, AJSpacing.xl)
        }
        .background(AJColor.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Sections

    private var stars: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Stars", trailing: "Glow-sticker motif")
            HStack(spacing: AJSpacing.md) {
                AJStar(size: 32)
                AJStar(size: 24)
                AJStar(size: 32, isLit: false)
            }
            AJStarCeiling(total: 12, lit: 7)
            ZStack {
                RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous).fill(AJColor.background)
                AJStarField(count: 10, seed: 2)
            }
            .frame(height: 120)
        }
    }

    private var colors: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Color")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AJSpacing.sm) {
                ForEach(Swatch.all) { swatch in
                    HStack(spacing: AJSpacing.sm) {
                        RoundedRectangle(cornerRadius: AJRadius.sm, style: .continuous)
                            .fill(swatch.color)
                            .frame(width: 40, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: AJRadius.sm, style: .continuous)
                                .strokeBorder(AJColor.border, lineWidth: 1))
                        Text(swatch.name).ajText(.footnote)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Type · Figtree", trailing: "Scales with Dynamic Type")
            ForEach(AJTextStyle.allCases, id: \.self) { style in
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.name).ajText(.label, color: AJColor.textSecondary)
                    Text("Warm the cream in your hands").ajText(style)
                }
            }
        }
    }

    private var onboarding: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Onboarding")
            AJProgressBar(progress: 0.4)
            AJHighlightedTitle("How warm is *Maya's* room at night?")
            AJOptionRow("Cool", isSelected: demoAnswer == 0) { demoAnswer = 0 }
            AJOptionRow("Warm or stuffy", isSelected: demoAnswer == 1) { demoAnswer = 1 }
            AJFeedbackNote("Worth changing: heat and sweat are common itch triggers.")
            AJTextField("Name or nickname", text: $demoName)
            AJStat(value: "7 in 10", caption: "children with eczema have disrupted sleep.")
            AJSourceNote("Eczema Society of Canada caregiver survey.")
            AJComparisonBars(eyebrow: "Time to fall asleep", nowValue: "70 min",
                             goalLabel: "Goal with a nightly ritual", goalValue: "15 min", goalFraction: 15.0 / 70.0)
            AJResultCard(value: "−55 min", caption: "a night, back for you both.")
            AJTimelineRow(time: "7:08", title: "Massage story", detail: "10 min · moisturizer on damp skin", icon: .sparkles)
            AJTimelineRow(time: "7:30", title: "Asleep", detail: "Log tonight in 2 seconds", icon: .dim, tint: AJColor.accentCalm, isLast: true)
            AJChecklistRow("Lights dimmed", detail: "Warm lamps only", isDone: demoChecked) { demoChecked.toggle() }
        }
    }

    private var paywall: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Paywall")
            AJBenefitRow("Massage stories that guide your hands")
            AJBenefitRow("Bedtime stories and affirmations, screen-free")
            AJPlanCard(title: "Yearly", price: "$59.99 a year · $5 a month", badge: "3 days free", isSelected: demoPlan == 0) { demoPlan = 0 }
            AJPlanCard(title: "Monthly", price: "$9.99 a month", isSelected: demoPlan == 1) { demoPlan = 1 }
            AJTrialSteps([
                AJTrialStep(title: "Full access", when: "Today", icon: .sparkles, tint: AJColor.accentWarm),
                AJTrialStep(title: "We remind you", when: "Day 2", icon: .bell, tint: AJColor.accentCalm),
                AJTrialStep(title: "Billing starts", when: "Day 3", icon: .check, tint: AJColor.action)
            ])
            Button("Start my 3-day free trial") {}.buttonStyle(.ajPrimary)
            Button("Skip for now") {}.buttonStyle(.ajGhost)
        }
    }

    private var mainApp: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Main app")
            HStack(spacing: AJSpacing.md) {
                AJMoon(size: 90)
                AJMoon(size: 40, color: AJColor.coral)
                AJMoon(size: 40, color: Color.white.opacity(0.15))
            }
            HStack(spacing: AJSpacing.xs) {
                AJChoiceChip("Calm", isSelected: demoChip == 0) { demoChip = 0 }
                AJChoiceChip("A bit itchy", isSelected: demoChip == 1) { demoChip = 1 }
            }
            Button("Tonight's plan") {}.buttonStyle(.ajOutline)
            HStack(alignment: .top, spacing: AJSpacing.sm) {
                AJStoryCard(title: "Lumi and the Sleepy Comet", meta: "10 or 20 min · 1+", width: 172, action: {}) {
                    LinearGradient(colors: [Color(hex: 0x7E63B8), AJColor.surfaceDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(AJStar(size: 44))
                }
                AJStoryCard(title: "You Are Loved", meta: "5 min · 2+", action: {}) {
                    LinearGradient(colors: [Color(hex: 0xB98A4A), AJColor.surfaceDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(AJStar(size: 34))
                }
            }
            AJSegmentedPicker("Massage length", options: [(value: false, label: "Full · 19 min"), (value: true, label: "Shorter · 8 min")],
                              selection: $demoShort)
            AJSheetHeader("How's *Maya's* skin tonight?") {}
            AJSwitchRow("Sleepy music", detail: "Soft and slow, under the story", isOn: $demoSwitch)
            AJProgressTrack(progress: 0.4)
            AJProgressTrack(progress: 0.4, isPaused: true)
            AJFactCard(eyebrow: "Why it helps",
                       text: "Children massaged for 20 minutes each night with their moisturizer had less eczema than children who got moisturizer alone.",
                       source: "Schachner, Field et al., Pediatric Dermatology, 1998")
        }
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Buttons")
            Button("Begin 10-min ritual") {}.buttonStyle(.ajPrimary)
            Button("Dim screen") {}.buttonStyle(.ajSecondary)
            Button("Skip tonight") {}.buttonStyle(.ajGhost)
            Button("Save and see report") {}.buttonStyle(.ajPrimary).disabled(true)
            AJIconButton(.back, accessibilityLabel: "Back") {}
        }
    }

    private var selection: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Selection")
            HStack(spacing: AJSpacing.xs) {
                ForEach([5, 10, 20], id: \.self) { minutes in
                    AJChip("\(minutes) min", isSelected: selectedLength == minutes) { selectedLength = minutes }
                }
            }
            AJStatusTile(title: "Behind knees", subtitle: subtitle(for: tileTone), tone: tileTone) {
                tileTone = next(after: tileTone)
            }
            AJRadioRow(title: "Sleepy Otter and the Cool River", subtitle: "Calm river sounds",
                       isSelected: selectedStory == 0) { selectedStory = 0 }
            AJRadioRow(title: "Yearly", subtitle: "7-day free trial", trailing: "$49.99",
                       isSelected: selectedStory == 1) { selectedStory = 1 }
        }
    }

    private var containers: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            AJSectionHeader("Containers & feedback")
            AJCard {
                AJSectionHeader("Where does skin need care?", trailing: "3 areas")
                Text("Tap once for dry, twice for flaring.").ajText(.footnote, color: AJColor.textSecondary)
            }
            HStack(spacing: AJSpacing.xs) {
                AJBadge("Glide · dry skin", tone: .calm)
                AJBadge("Pat · flaring", tone: .warm)
            }
            AJSegmentedProgress(total: 5, current: 2, fraction: 0.4)
            AJNotice("Using a prescribed cream? Apply it first, exactly as your doctor directed.")
        }
    }

    // MARK: Helpers

    private func next(after tone: AJStatusTile.Tone) -> AJStatusTile.Tone {
        switch tone {
        case .neutral: return .calm
        case .calm: return .warm
        case .warm: return .neutral
        }
    }

    private func subtitle(for tone: AJStatusTile.Tone) -> String {
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
        Swatch(name: "background", color: AJColor.background),
        Swatch(name: "surface", color: AJColor.surface),
        Swatch(name: "surfaceRaised", color: AJColor.surfaceRaised),
        Swatch(name: "border", color: AJColor.border),
        Swatch(name: "textPrimary", color: AJColor.textPrimary),
        Swatch(name: "textSecondary", color: AJColor.textSecondary),
        Swatch(name: "accentCalm", color: AJColor.accentCalm),
        Swatch(name: "accentWarm", color: AJColor.accentWarm),
        Swatch(name: "action", color: AJColor.action),
        Swatch(name: "surfaceDeep", color: AJColor.surfaceDeep),
        Swatch(name: "textTertiary", color: AJColor.textTertiary),
        Swatch(name: "coral", color: AJColor.coral)
    ]
}

#Preview("Design system") {
    AJCatalogView()
}
