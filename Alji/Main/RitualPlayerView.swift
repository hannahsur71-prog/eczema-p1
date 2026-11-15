import SwiftUI
import AljiDesignSystem

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
        return VStack(spacing: AJSpacing.lg) {
            HStack {
                Button("End") { engine.stop(); dismiss() }.buttonStyle(.ajGhost).frame(width: 90)
                Spacer()
                Text("Step \(engine.index + 1) of \(engine.steps.count)").ajText(.footnote, color: AJColor.textSecondary)
                Spacer()
                AJIconButton(.dim, accessibilityLabel: "Dim screen") { dimmed = true }
            }
            AJSegmentedProgress(total: engine.steps.count, current: engine.index, fraction: engine.stepFraction)

            Spacer()
            VStack(spacing: AJSpacing.md) {
                AJBadge(step.badge, tone: step.kind == .pat || step.kind == .warm ? .warm : .calm)
                Text(step.title).ajText(.title).multilineTextAlignment(.center)
                StepIllustration(kind: step.kind)
                Text(step.script).ajText(.body).multilineTextAlignment(.center)
                Text("“\(step.narration)”")
                    .ajText(.footnote, color: AJColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                Text("\(timeText(engine.remaining)) left in this step")
                    .ajText(.footnote, color: AJColor.textSecondary)
            }
            Spacer()

            AJCard {
                HStack(spacing: AJSpacing.sm) {
                    Image(aj: .music).ajIcon(AJSize.iconSmall, color: AJColor.accentCalm)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.story.title).ajText(.callout)
                        Text("Story starts after the massage").ajText(.footnote, color: AJColor.textSecondary)
                    }
                }
                HStack(spacing: AJSpacing.xs) {
                    Button(engine.isPlaying ? "Pause" : "Resume") { engine.togglePause() }.buttonStyle(.ajSecondary)
                    Button("Next step") { engine.nextStep() }.buttonStyle(.ajSecondary)
                }
                HStack(spacing: AJSpacing.xs) {
                    AJChip("Voice \(engine.voiceOn ? "on" : "off")", isSelected: engine.voiceOn) { engine.voiceOn.toggle() }
                    AJChip("Music \(engine.musicOn ? "on" : "off")", isSelected: engine.musicOn) { engine.musicOn.toggle() }
                }
            }
        }
        .padding(.horizontal, AJSpacing.screenGutter)
        .padding(.vertical, AJSpacing.md)
    }

    // MARK: Story / done

    private var afterMassage: some View {
        VStack(spacing: AJSpacing.lg) {
            Spacer()
            AJStar(size: 64)
                .frame(width: 100, height: 100)
                .background(AJColor.surface, in: Circle())
            AJScreenHeader(
                title: engine.phase == .story ? "Massage done." : "Sweet dreams.",
                subtitle: engine.phase == .story
                    ? "\(engine.story.title) is playing. The music will fade on its own. Rest a hand on \(appState.answers.displayChild)'s back if they like it."
                    : "The story is over and the music is fading out.",
                isHero: true)
            Spacer()
            Button("Dim screen") { dimmed = true }.buttonStyle(.ajSecondary)
            Button("Log tonight (once they're asleep)") { engine.stop(); showLog = true }.buttonStyle(.ajPrimary)
            Button("Close") { engine.stop(); dismiss() }.buttonStyle(.ajGhost)
        }
        .padding(.horizontal, AJSpacing.screenGutter)
        .padding(.vertical, AJSpacing.md)
    }

    private var dimOverlay: some View {
        Button { dimmed = false } label: {
            ZStack(alignment: .bottom) {
                AJColor.dimmed.ignoresSafeArea()
                // Like glow stickers on the ceiling after lights out: barely there.
                AJStarField(count: 12, seed: 3, opacity: 0.12).ignoresSafeArea()
                VStack(spacing: AJSpacing.xxs) {
                    Text(engine.phase == .massage ? "Now: \(engine.currentStep.title)" : "Story playing")
                        .ajText(.callout, color: AJColor.textDimmed)
                    Text("Tap anywhere to wake").ajText(.footnote, color: AJColor.textDimmed)
                }
                .padding(.bottom, AJSpacing.xxl)
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
            Circle().fill(AJColor.surface)
            Image(systemName: symbol)
                .ajIcon(56, color: kind == .pat || kind == .warm ? AJColor.accentWarm : AJColor.accentCalm)
        }
        .frame(width: 150, height: 150)
        .accessibilityLabel(label)
    }

    private var symbol: String {
        switch kind {
        case .warm: return "hands.clap"
        case .glide: return "hand.draw"
        case .pat: return "hand.point.up.left"
        case .calm: return "arrow.clockwise.circle"
        }
    }

    private var label: String {
        switch kind {
        case .warm: return "Rub your palms together to warm the lotion"
        case .glide: return "Long, slow glide along the skin"
        case .pat: return "Gently smooth the cream on, no massage"
        case .calm: return "Big, slow circles on the back"
        }
    }
}
