import SwiftUI
import AljiDesignSystem

/// The massage story, as a follow-along. Each step opens with a few seconds of "Watch first": the hands show the
/// move and the voice says what to do. Then "Your turn": the story plays while the parent follows the screen.
struct MassagePlayerView: View {
    let storyID: String
    let isFlare: Bool
    /// True when started from Tonight: shows and speaks "Good evening" first.
    let greets: Bool

    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router

    @State private var steps: [MassageStep] = []
    @State private var title = ""
    @State private var index = 0
    @State private var left = 0
    @State private var isPlaying = true
    /// True during the few seconds of "Watch first" that open each step.
    @State private var isPreview = false
    @State private var showGreeting = false
    @State private var showSound = false
    @State private var noiseKind: NoiseEngine.Kind?

    private var isShort: Bool { appState.massageIsShort }
    private var step: MassageStep? { steps.indices.contains(index) ? steps[index] : nil }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                if let step {
                    MassageStepFigure(step: step)
                        .frame(maxWidth: 340, maxHeight: .infinity)
                        .padding(.horizontal, AJSpacing.md)
                    controls(step)
                } else {
                    Spacer()
                }
            }
            if showGreeting { greeting }
            if showSound { soundPanel }
        }
        .animation(.easeInOut(duration: 0.25), value: showSound)
        .onAppear(perform: start)
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .task(id: isPlaying) {
            // One tick a second while playing.
            while isPlaying && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled || !isPlaying { return }
                if left > 1 { left -= 1 } else if isPreview { startTurn() } else { advance(1) }
            }
        }
    }

    // MARK: Parts

    private var header: some View {
        HStack(spacing: 6) {
            AJIconButton(.back, accessibilityLabel: "Back") { router.close() }
            Text(title).ajText(.callout).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            Button { showSound = true } label: {
                HStack(spacing: 6) {
                    Image(aj: .music).ajIcon(14)
                    Text("Sound").ajText(.subhead)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: AJSize.minTouch)
                .overlay(Capsule().strokeBorder(AJColor.borderQuiet, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, AJSpacing.xs)
    }

    private func controls(_ step: MassageStep) -> some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            phaseChip
            HStack(alignment: .firstTextBaseline, spacing: AJSpacing.xs) {
                Text(step.label).ajText(.title2).frame(maxWidth: .infinity, alignment: .leading)
                Text(step.reps)
                    .ajText(.footnoteStrong, color: AJColor.onAccent)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(AJColor.accentWarm, in: Capsule())
            }
            Text(step.cue.personalized(appState.child)).ajText(.callout)
            Text("“\(step.story.personalized(appState.child))”").italic().ajText(.subhead, color: AJColor.textSecondary)
            if isFlare {
                Text("Flare night: skip flaring spots, massage calm skin only.").ajText(.footnote, color: AJColor.coralText)
            }
            VStack(alignment: .leading, spacing: 6) {
                AJProgressTrack(progress: progress)
                Text(timeLeft).ajText(.footnote, color: AJColor.textSecondary)
            }
            HStack(spacing: 46) {
                Button { advance(-1) } label: {
                    Image(aj: .previous).ajIcon(22).frame(width: 48, height: 48)
                }
                .accessibilityLabel("Previous step")
                Button(action: togglePlay) {
                    Image(aj: isPlaying ? .pause : .play)
                        .ajIcon(26, color: AJColor.onAccent)
                        .frame(width: 72, height: 72)
                        .background(Color.white, in: Circle())
                }
                .accessibilityLabel(isPlaying ? "Pause" : "Play")
                Button { advance(1) } label: {
                    Image(aj: .forward).ajIcon(22).frame(width: 48, height: 48)
                }
                .accessibilityLabel("Next step")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AJSpacing.screenGutter)
        .padding(.bottom, AJSpacing.md)
    }

    /// "Watch first · 3" while the move is being shown, then "Your turn".
    private var phaseChip: some View {
        Text(isPreview ? "Watch first · \(left)" : "Your turn")
            .ajText(.footnoteStrong, color: isPreview ? AJColor.onAccent : Color(hex: 0xBDE9F7))
            .padding(.horizontal, AJSpacing.sm)
            .padding(.vertical, 5)
            .background(isPreview ? AJColor.accentWarm : AJColor.accentCalm.opacity(0.22), in: Capsule())
            .overlay(Capsule().strokeBorder(isPreview ? Color.clear : AJColor.accentCalm, lineWidth: 1.5))
            .accessibilityAddTraits(.updatesFrequently)
    }

    private var greeting: some View {
        VStack {
            (Text("Good evening, ") + Text(appState.child).foregroundStyle(AJColor.accentWarm))
                .ajText(.title2)
                .padding(.horizontal, 20)
                .padding(.vertical, AJSpacing.sm)
                .background(AJColor.background.opacity(0.9), in: Capsule())
                .overlay(Capsule().strokeBorder(AJColor.accentWarm, lineWidth: 1.5))
                .padding(.top, 76)
            Spacer()
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    private var soundPanel: some View {
        @Bindable var state = appState
        return BottomPanel(onClose: { showSound = false }) {
            AJSheetHeader("Sound") { showSound = false }
            AJSwitchRow("Story voice", detail: "Lumi reads the story aloud", isOn: $state.voiceOn)
            AJSwitchRow("Sleepy music", detail: "Soft and slow, under the story", isOn: $state.musicOn)
            AJSwitchRow("White noise", detail: "A steady hush. Studied for sleep.", isOn: noiseBinding(.white))
            AJSwitchRow("Pink noise", detail: "Softer and deeper. Some evidence.", isOn: noiseBinding(.pink))
        }
        .onChange(of: appState.voiceOn) { _, isOn in
            if isOn { speakStep() } else { router.narrator.stop() }
        }
        .onChange(of: appState.musicOn) { _, isOn in
            if isOn { router.startMusic(isPlaying) } else { router.music.fadeOut(over: 1.5) }
        }
    }

    private func noiseBinding(_ kind: NoiseEngine.Kind) -> Binding<Bool> {
        Binding(get: { noiseKind == kind }, set: { isOn in
            noiseKind = isOn ? kind : nil
            if isOn { router.noise.start(kind) } else { router.noise.stop() }
        })
    }

    // MARK: Progress

    private var lengths: [Int] { steps.map { StoryCatalog.duration($0, short: isShort) } }

    private var progress: Double {
        let total = max(1, lengths.reduce(0, +))
        let current = isPreview ? 0 : max(0, (lengths.indices.contains(index) ? lengths[index] : 0) - left)
        let done = lengths.prefix(index).reduce(0, +) + current
        return min(1, Double(done) / Double(total))
    }

    private var timeLeft: String {
        if index >= steps.count - 1 && left <= 1 { return "Almost done" }
        let total = Double(lengths.reduce(0, +))
        let minutes = max(1, Int((total * (1 - progress) / 60).rounded()))
        return "About \(minutes) min left"
    }

    // MARK: Actions

    private func start() {
        guard let item = StoryCatalog.item(storyID, custom: appState.customStory) else {
            router.close()
            return
        }
        title = item.title.personalized(appState.child)
        steps = StoryCatalog.playableSteps(item, short: isShort, child: appState.child)
        isPlaying = true
        // The parent's hands are busy, so the screen must not lock mid-massage.
        UIApplication.shared.isIdleTimerDisabled = true
        router.startMusic(appState.musicOn)
        if greets {
            showGreeting = true
            Task {
                try? await Task.sleep(for: .seconds(2.4))
                withAnimation(.easeOut(duration: 0.4)) { showGreeting = false }
            }
        }
        begin(0, greeting: greets ? "Good evening, \(appState.child). " : "")
    }

    /// Seconds of "Watch first" before each step.
    private let previewSeconds = 6

    /// Opens a step with its preview. Roll-over steps are self-explanatory, so they skip it.
    private func begin(_ newIndex: Int, greeting: String = "") {
        guard steps.indices.contains(newIndex) else { return }
        index = newIndex
        let step = steps[newIndex]
        if step.view == "turn" || step.view == "turnBack" {
            isPreview = false
            left = lengths[newIndex]
            speak(greeting + step.story.personalized(appState.child))
        } else {
            isPreview = true
            left = previewSeconds
            speak(greeting + "Watch first. \(step.cue.personalized(appState.child)).")
        }
    }

    private func startTurn() {
        isPreview = false
        left = lengths.indices.contains(index) ? lengths[index] : 0
        if let step { speak("Your turn. " + step.story.personalized(appState.child)) }
    }

    private func speak(_ text: String) {
        guard appState.voiceOn else { return }
        router.narrator.speak(text)
    }

    private func speakStep() {
        guard let step else { return }
        speak((isPreview ? step.cue : step.story).personalized(appState.child))
    }

    private func advance(_ delta: Int) {
        let next = index + delta
        if next >= steps.count {
            isPlaying = false
            router.quiet()
            let minutes = max(1, Int((Double(lengths.reduce(0, +)) / 60).rounded()))
            router.open(.end(storyID: storyID, minutes: minutes, isFlare: isFlare))
            return
        }
        begin(max(0, next))
    }

    private func togglePlay() {
        isPlaying.toggle()
        if isPlaying {
            router.startMusic(appState.musicOn)
            speakStep()
        } else {
            router.narrator.stop()
            router.music.fadeOut(over: 1.5)
        }
    }
}

// MARK: - End of the ritual

/// A new star lands on the moon and affirmations begin by themselves. Nothing is asked at night;
/// the screen goes dark after a few seconds.
struct RitualEndView: View {
    let storyID: String
    let minutes: Int
    let isFlare: Bool

    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router
    @State private var starLanded = false
    @State private var hasRecorded = false

    private let lengths: [(minutes: Int, label: String)] = [(0, "Off"), (20, "20 min"), (60, "1 hour"), (120, "2 hours")]

    var body: some View {
        VStack(spacing: AJSpacing.md + 2) {
            ZStack {
                AJMoon(size: 130)
                AJStar(size: 40)
                    .offset(x: starLanded ? 34 : -76, y: starLanded ? -40 : 110)
                    .scaleEffect(starLanded ? 1 : 0.3)
                    .rotationEffect(.degrees(starLanded ? 0 : -90))
                    .opacity(starLanded ? 1 : 0)
            }
            .frame(height: 130)
            .accessibilityHidden(true)
            Text("Sweet dreams").ajText(.display)
            Text("A new star on \(appState.child)'s moon").ajText(.callout, color: AJColor.starGlow)
            VStack(spacing: 10) {
                Text(appState.affirmationMinutes > 0 ? "Affirmations are starting" : "Affirmations are off").ajText(.callout)
                FlowLayout(spacing: AJSpacing.xs) {
                    ForEach(lengths, id: \.minutes) { option in
                        AJChoiceChip(option.label, isSelected: appState.affirmationMinutes == option.minutes) {
                            appState.affirmationMinutes = option.minutes
                            playAffirmations()
                        }
                    }
                }
                Text("They play from this device, so leave it in \(appState.child)'s room. A tablet works well if you need your phone.")
                    .ajText(.footnote, color: AJColor.textSecondary)
            }
            .padding(.top, AJSpacing.xs)
            Spacer(minLength: 0)
            Text("No questions tonight. The screen goes dark in a few seconds.").ajText(.footnote, color: AJColor.textTertiary)
            Button("Goodnight") { router.open(.dark) }.buttonStyle(.ajPrimary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, AJSpacing.lg)
        .padding(.top, AJSpacing.lg)
        .padding(.bottom, AJSpacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.2)) { starLanded = true }
            guard !hasRecorded else { return }
            hasRecorded = true
            appState.finishRitual(storyID: storyID, minutes: minutes, wasFlare: isFlare)
            playAffirmations()
            Task { await ReminderScheduler.scheduleMorningCheckIn(childName: appState.child) }
        }
        .task(id: appState.affirmationMinutes) {
            // Dim by itself. Changing the length restarts the countdown so the parent isn't cut off mid-choice.
            try? await Task.sleep(for: .seconds(9))
            if !Task.isCancelled && router.screen == .end(storyID: storyID, minutes: minutes, isFlare: isFlare) { router.open(.dark) }
        }
    }

    private func playAffirmations() {
        let lines = StoryCatalog.item("brave", custom: nil)?.lines ?? []
        router.playAffirmations(lines.joined(separator: " ").personalized(appState.child), minutes: appState.affirmationMinutes,
                                voiceOn: appState.voiceOn, musicOn: appState.musicOn)
    }
}

/// The answers used by the morning check-in.
enum CheckIn {
    static let itch = ["Calm", "A bit itchy", "Very itchy"]
    static let fall = ["Under 15 min", "15–30 min", "30–60 min", "Over an hour"]
    static let wakes = ["0", "1", "2", "3+"]

    static func fallMinutes(_ answer: String) -> Int {
        ["Under 15 min": 12, "15–30 min": 18, "30–60 min": 40, "Over an hour": 70][answer] ?? 18
    }

    static func wakeCount(_ answer: String) -> Int {
        ["0": 0, "1": 1, "2": 2, "3+": 3][answer] ?? 1
    }
}

/// One check-in question with its answer chips.
struct CheckInGroup: View {
    let title: String
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).ajText(.callout)
            FlowLayout(spacing: AJSpacing.xs) {
                ForEach(options, id: \.self) { option in
                    AJChoiceChip(option, isSelected: selection == option) { selection = option }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Affirmations in the dark

/// The screen is dark while affirmations play. Tap to wake.
struct AffirmationsDarkView: View {
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router

    private var length: String {
        let minutes = appState.affirmationMinutes
        return minutes >= 60 ? (minutes == 60 ? "1 hour" : "\(minutes / 60) hours") : "\(minutes) min"
    }

    var body: some View {
        let isOn = appState.affirmationMinutes > 0
        let dim = Color(hex: 0x6E6A94)
        Button(action: wake) {
            VStack(spacing: AJSpacing.sm) {
                AJMoon(size: 70, color: dim)
                Text(isOn ? "Affirmations are playing softly" : "Goodnight, \(appState.child)").ajText(.subhead, color: dim)
                Text((isOn ? "\(length) · " : "") + "tap to wake the screen").ajText(.footnote, color: dim)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: 0x05040F).ignoresSafeArea())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Affirmations are playing. Tap to wake the screen." : "Tap to wake the screen.")
    }

    private func wake() {
        appState.selectedTab = .tonight
        router.close()
    }
}
