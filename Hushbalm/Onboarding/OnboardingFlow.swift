import SwiftUI
import HushbalmDesignSystem

/// The onboarding funnel, rebuilt around eczema families.
/// Rhythm: question → insight → question → insight (each insight cited), then the
/// struggle score, the transformation, a 1-minute taste of the ritual and the paywall.
enum OnboardingStep: Hashable {
    case welcome, founder, childName, age, relationship, parentName, zones
    case quiz(String)
    case insight(Insight)
    case analyzing, results, howItHelps, socialProof, features, reminder, buildingPlan, plan, taste, firstWin

    static var ordered: [OnboardingStep] {
        var steps: [OnboardingStep] = [
            .welcome, .founder, .childName, .age, .relationship, .parentName, .zones,
            .quiz("nightWaking"), .insight(.sleepFacts),
            .quiz("lotionTime"), .insight(.notYou),
            .quiz("touch"), .insight(.touchAdapt),
            .insight(.massageEvidence),
            .quiz("bedtimeLength"), .quiz("parentSleep"), .quiz("bedtimeFeeling"), .insight(.parentToo),
            .quiz("tried"), .quiz("goals"),
            .analyzing, .results, .howItHelps
        ]
        // Real reviews only: the screen appears once you have them.
        if !AppConfig.testimonials.isEmpty { steps.append(.socialProof) }
        steps += [.features, .reminder, .buildingPlan, .plan, .taste, .firstWin]
        return steps
    }

    /// Screens that run themselves and shouldn't show back/progress.
    var isAutomatic: Bool { self == .analyzing || self == .buildingPlan }
}

struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @State private var index = 0
    @State private var movingForward = true

    private let steps = OnboardingStep.ordered

    var body: some View {
        let step = steps[index]
        VStack(spacing: 0) {
            if step != .welcome && !step.isAutomatic {
                topBar
            }
            screen(for: step)
                .id(index)
                .transition(.asymmetric(
                    insertion: .move(edge: movingForward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: movingForward ? .leading : .trailing).combined(with: .opacity)))
        }
        .animation(.easeInOut(duration: 0.3), value: index)
        .background(StarryBackground())
    }

    private var topBar: some View {
        HStack(spacing: HBSpacing.sm) {
            HBIconButton(.back, accessibilityLabel: "Back") { back() }
            HBStarProgress(progress: Double(index) / Double(steps.count - 1))
        }
        .padding(.horizontal, HBSpacing.screenGutter)
        .padding(.top, HBSpacing.xs)
    }

    @ViewBuilder
    private func screen(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome: WelcomeScreen(next: next)
        case .founder: FounderScreen(next: next)
        case .childName: ChildNameScreen(next: next)
        case .age: AgeScreen(next: next)
        case .relationship: RelationshipScreen(next: next)
        case .parentName: ParentNameScreen(next: next)
        case .zones: ZonesScreen(next: next)
        case .quiz(let id):
            if let question = QuizBank.question(id) {
                QuizScreen(question: question, next: next)
            }
        case .insight(let insight): InsightScreen(insight: insight, next: next)
        case .analyzing: AnalyzingScreen(next: next)
        case .results: ResultsScreen(next: next)
        case .howItHelps: HowItHelpsScreen(next: next)
        case .socialProof: SocialProofScreen(next: next)
        case .features: FeaturesScreen(next: next)
        case .reminder: ReminderScreen(next: next)
        case .buildingPlan: BuildingPlanScreen(next: next)
        case .plan: PlanScreen(next: next)
        case .taste: TasteRitualScreen(next: next)
        case .firstWin: FirstWinScreen(finish: finish)
        }
    }

    private func next() {
        guard index + 1 < steps.count else { return }
        movingForward = true
        index += 1
    }

    private func back() {
        movingForward = false
        var target = index - 1
        // Skip automatic screens when going back.
        while target > 0 && steps[target].isAutomatic { target -= 1 }
        index = max(0, target)
    }

    private func finish() {
        appState.seedTonightFromOnboarding()
        appState.hasCompletedOnboarding = true
    }
}

/// Shared layout for onboarding screens: scrollable content + pinned CTA.
struct OnboardingScaffold<Content: View, Footer: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: HBSpacing.lg) { content }
                    .padding(.horizontal, HBSpacing.screenGutter)
                    .padding(.top, HBSpacing.lg)
                    .padding(.bottom, HBSpacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: HBSpacing.xs) { footer }
                .padding(.horizontal, HBSpacing.screenGutter)
                .padding(.top, HBSpacing.sm)
                .padding(.bottom, HBSpacing.md)
                .background(HBColor.background)
        }
    }
}

/// The night-sky background with glow-sticker stars, used across Alji.
struct StarryBackground: View {
    var opacity: Double = 0.45
    var seed: UInt64 = 7

    var body: some View {
        ZStack {
            HBColor.background
            HBStarField(count: 16, seed: seed, opacity: opacity)
        }
        .ignoresSafeArea()
    }
}
