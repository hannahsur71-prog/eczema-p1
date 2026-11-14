import SwiftUI
import HushbalmDesignSystem

/// Full-screen ritual player. The parent glances at it; the child never needs to see it.
struct RitualPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var engine: RitualEngine
    @State private var dimmed = false
    @State private var showLog = false
    private let minutes: Int

    init(steps: [RitualStep], story: Story, minutes: Int) {
        _engine = State(initialValue: RitualEngine(steps: steps, story: story, minutes: minutes))
        self.minutes = minutes
    }

    var body: some View {
        ZStack {
            StarryBackground(opacity: 0.3, seed: 5)
            switch engine.phase {
            case .massage: massage
            case .story, .finished: afterMassage
            }
            if dimmed { dimOverlay }
        }
        .onAppear { engine.start() }
        .onDisappear { if engine.phase == .massage { engine.stop() } }
        .sheet(isPresented: $showLog, onDismiss: { dismiss() }) {
            NightLogView(minutes: minutes, storyID: engine.story.id)
        }
        .statusBarHidden(dimmed)
    }

    // MARK: Massage phase

    private var massage: some View {
        let step = engine.currentStep
        return VStack(spacing: HBSpacing.lg) {
            HStack {
                Button("End") { engine.stop(); dismiss() }.buttonStyle(.hbGhost).frame(width: 90)
                Spacer()
                Text("Step \(engine.index + 1) of \(engine.steps.count)").hbText(.footnote, color: HBColor.textSecondary)
                Spacer()
                HBIconButton(.dim, accessibilityLabel: "Dim screen") { dimmed = true }
            }
            HBSegmentedProgress(total: engine.steps.count, current: engine.index, fraction: engine.stepFraction)

            Spacer()
            VStack(spacing: HBSpacing.md) {
                HBBadge(step.badge, tone: step.kind == .pat || step.kind == .warm ? .warm : .calm)
                Text(step.title).hbText(.title).multilineTextAlignment(.center)
                StepIllustration(kind: step.kind)
                Text(step.script).hbText(.body).multilineTextAlignment(.center)
                Text("\(timeText(engine.remaining)) left in this step")
                    .hbText(.footnote, color: HBColor.textSecondary)
            }
            Spacer()

            HBCard {
                HStack(spacing: HBSpacing.sm) {
                    Image(hb: .music).hbIcon(HBSize.iconSmall, color: HBColor.accentCalm)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.story.title).hbText(.callout)
                        Text("Story starts after the massage").hbText(.footnote, color: HBColor.textSecondary)
                    }
                }
                HStack(spacing: HBSpacing.xs) {
                    Button(engine.isPlaying ? "Pause" : "Resume") { engine.togglePause() }.buttonStyle(.hbSecondary)
                    Button("Next step") { engine.nextStep() }.buttonStyle(.hbSecondary)
                }
                HStack(spacing: HBSpacing.xs) {
                    HBChip("Voice \(engine.voiceOn ? "on" : "off")", isSelected: engine.voiceOn) { engine.voiceOn.toggle() }
                    HBChip("Music \(engine.musicOn ? "on" : "off")", isSelected: engine.musicOn) { engine.musicOn.toggle() }
                }
            }
        }
        .padding(.horizontal, HBSpacing.screenGutter)
        .padding(.vertical, HBSpacing.md)
    }

    // MARK: Story / done

    private var afterMassage: some View {
        VStack(spacing: HBSpacing.lg) {
            Spacer()
            HBStar(size: 64)
                .frame(width: 100, height: 100)
                .background(HBColor.surface, in: Circle())
            HBScreenHeader(
                title: engine.phase == .story ? "Massage done." : "Sweet dreams.",
                subtitle: engine.phase == .story
                    ? "\(engine.story.title) is playing. The music will fade on its own. Rest a hand on \(appState.answers.displayChild)'s back if they like it."
                    : "The story is over and the music is fading out.",
                isHero: true)
            Spacer()
            Button("Dim screen") { dimmed = true }.buttonStyle(.hbSecondary)
            Button("Log tonight (once they're asleep)") { engine.stop(); showLog = true }.buttonStyle(.hbPrimary)
            Button("Close") { engine.stop(); dismiss() }.buttonStyle(.hbGhost)
        }
        .padding(.horizontal, HBSpacing.screenGutter)
        .padding(.vertical, HBSpacing.md)
    }

    private var dimOverlay: some View {
        Button { dimmed = false } label: {
            ZStack(alignment: .bottom) {
                HBColor.dimmed.ignoresSafeArea()
                // Like glow stickers on the ceiling after lights out: barely there.
                HBStarField(count: 12, seed: 3, opacity: 0.12).ignoresSafeArea()
                VStack(spacing: HBSpacing.xxs) {
                    Text(engine.phase == .massage ? "Now: \(engine.currentStep.title)" : "Story playing")
                        .hbText(.callout, color: HBColor.textDimmed)
                    Text("Tap anywhere to wake").hbText(.footnote, color: HBColor.textDimmed)
                }
                .padding(.bottom, HBSpacing.xxl)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Screen dimmed. Tap to wake.")
    }

    private func timeText(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

/// Simple hand-motion illustration for each technique.
private struct StepIllustration: View {
    let kind: RitualStep.Kind

    var body: some View {
        ZStack {
            Circle().fill(HBColor.surface)
            Image(systemName: symbol)
                .hbIcon(56, color: kind == .pat || kind == .warm ? HBColor.accentWarm : HBColor.accentCalm)
        }
        .frame(width: 150, height: 150)
        .accessibilityLabel(label)
    }

    private var symbol: String {
        switch kind {
        case .warm: return "hands.clap"
        case .glide: return "hand.draw"
        case .pat: return "hand.raised"
        case .calm: return "arrow.clockwise.circle"
        }
    }

    private var label: String {
        switch kind {
        case .warm: return "Rub your palms together to warm the lotion"
        case .glide: return "Long, slow glide along the skin"
        case .pat: return "Soft press with a flat palm, then lift"
        case .calm: return "Big, slow circles on the back"
        }
    }
}
