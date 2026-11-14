import SwiftUI
import StoreKit
import HushbalmDesignSystem

/// The "gotcha moment" before the paywall: a real, 1-minute taste of the ritual,
/// with voice cues and music, before any payment.
struct TasteRitualScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void
    @State private var engine: RitualEngine?
    @State private var started = false

    var body: some View {
        let child = appState.answers.displayChild
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "Night 1 · 1 minute",
                           title: started ? "Just listen and follow along." : "Let's try it with \(child), right now.",
                           subtitle: started ? nil : "Grab the moisturizer. Turn up the volume, set the phone down, and follow the voice.")
            if let engine, started {
                HBCard {
                    HBSegmentedProgress(total: engine.steps.count, current: engine.index, fraction: engine.stepFraction)
                    HBBadge(engine.currentStep.badge, tone: engine.currentStep.kind == .pat ? .warm : .calm)
                    Text(engine.currentStep.title).hbText(.title2)
                    Text(engine.currentStep.script).hbText(.body)
                    Text("“\(engine.currentStep.narration)”").hbText(.footnote, color: HBColor.textSecondary)
                }
            } else {
                HBCard {
                    HBBenefitRow("Warm the lotion in your hands")
                    HBBenefitRow("One slow glide on \(firstZone.label.lowercased())")
                    HBBenefitRow("Slow, calming back circles")
                }
            }
        } footer: {
            if !started {
                Button("Start the 1-minute ritual") { start() }.buttonStyle(.hbPrimary)
                Button("Skip for now") { next() }.buttonStyle(.hbGhost)
            } else if engine?.phase == .finished {
                Button("Continue", action: next).buttonStyle(.hbPrimary)
            } else {
                Button("Next step") { engine?.nextStep() }.buttonStyle(.hbSecondary)
                Button("Skip for now") { engine?.stop(); next() }.buttonStyle(.hbGhost)
            }
        }
        .onChange(of: engine?.phase) { _, phase in
            if phase == .finished { appState.answers.completedTaste = true; advanceSoon(next) }
        }
        .onDisappear { if engine?.phase != .finished { engine?.stop() } }
    }

    private var firstZone: CareZone { appState.answers.usualZones.first ?? .arms }

    private func start() {
        let zone = firstZone
        let steps = RitualBuilder.steps(for: [zone: .dry], story: MassageStoryLibrary.sleepyComet)
        let ritual = RitualEngine(steps: steps, story: StoryLibrary.otter, minutes: 1,
                                  includesStory: false, stepSecondsOverride: 20)
        engine = ritual
        started = true
        ritual.start()
    }
}

/// The first win, then straight to the paywall.
struct FirstWinScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.requestReview) private var requestReview
    let finish: () -> Void

    var body: some View {
        let a = appState.answers
        OnboardingScaffold {
            Spacer(minLength: HBSpacing.lg)
            Image(hb: .sparkles)
                .hbIcon(40, color: HBColor.accentWarm)
                .frame(width: 84, height: 84)
                .background(HBColor.surface, in: Circle())
                .accessibilityHidden(true)
            HBScreenHeader(
                title: a.completedTaste ? "Night 1, done." : "Night 1 is waiting.",
                subtitle: a.completedTaste
                    ? "That's how every night with \(a.displayChild) can feel: calm hands, a soft voice, no battle."
                    : "Tonight, the full ritual takes \(a.recommendedMinutes) minutes, and \(a.displayChild) just lies back and listens.",
                isHero: true)
            HBCard {
                HBStat(value: "1 of 30", caption: "nights in \(a.displayChild)'s plan")
            }
        } footer: {
            Button("See \(a.displayChild)'s full plan", action: finish).buttonStyle(.hbPrimary)
        }
        .task {
            // Ask for an App Store rating only after they've actually tried the ritual.
            if a.completedTaste {
                try? await Task.sleep(for: .seconds(1.2))
                requestReview()
            }
        }
    }
}
