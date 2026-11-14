import SwiftUI
import HushbalmDesignSystem

/// The onboarding funnel. Structure follows the proven sleep-app pattern
/// (personal quiz → results → "you're not alone" → how it helps → social proof →
/// features → reminder → building your plan → custom plan → a 1-minute taste of the
/// ritual (the "gotcha moment") → first win → paywall that remembers their goal),
/// with copy that sells the transformation, not the features.
enum OnboardingStep: Hashable {
    case welcome, parentName, childName, age
    case quiz(Int)
    case zones, analyzing, results, notAlone, howItHelps, socialProof, features, reminder, buildingPlan, plan, taste, firstWin

    static var ordered: [OnboardingStep] {
        [.welcome, .parentName, .childName, .age]
        + QuizBank.questions.indices.map { OnboardingStep.quiz($0) }
        + [.zones, .analyzing, .results, .notAlone, .howItHelps, .socialProof, .features, .reminder, .buildingPlan, .plan, .taste, .firstWin]
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
        .background(HBColor.background.ignoresSafeArea())
    }

    private var topBar: some View {
        HStack(spacing: HBSpacing.sm) {
            HBIconButton(.back, accessibilityLabel: "Back") { back() }
            HBProgressBar(progress: Double(index) / Double(steps.count - 1))
        }
        .padding(.horizontal, HBSpacing.screenGutter)
        .padding(.top, HBSpacing.xs)
    }

    @ViewBuilder
    private func screen(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome: WelcomeScreen(next: next)
        case .parentName: ParentNameScreen(next: next)
        case .childName: ChildNameScreen(next: next)
        case .age: AgeScreen(next: next)
        case .quiz(let number): QuizScreen(question: QuizBank.questions[number], next: next)
        case .zones: ZonesScreen(next: next)
        case .analyzing: AnalyzingScreen(next: next)
        case .results: ResultsScreen(next: next)
        case .notAlone: NotAloneScreen(next: next)
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
