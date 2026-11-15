import SwiftUI
import AljiDesignSystem

/// The massage story: the figure shows the stroke, the voice tells the story, and steps move on by themselves.
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
                if left > 1 { left -= 1 } else { advance(1) }
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
        let done = lengths.prefix(index).reduce(0, +) + max(0, (lengths.indices.contains(index) ? lengths[index] : 0) - left)
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
        index = 0
        left = lengths.first ?? 0
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
            speak("Good evening, \(appState.child). " + (steps.first?.story.personalized(appState.child) ?? ""))
        } else {
            speakStep()
        }
    }

    private func speak(_ text: String) {
        guard appState.voiceOn else { return }
        router.narrator.speak(text)
    }

    private func speakStep() {
        if let step { speak(step.story.personalized(appState.child)) }
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
        index = max(0, next)
        left = lengths[index]
        speakStep()
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

/// A new star lands on the moon, then a rating and a two-question check-in.
struct RitualEndView: View {
    let storyID: String
    let minutes: Int
    let isFlare: Bool

    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router
    @State private var rating = 0
    @State private var itch: String?
    @State private var cream: String?
    @State private var starLanded = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
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
                    VStack(spacing: AJSpacing.xs) {
                        Text("Did \(appState.child) enjoy the story?").ajText(.callout)
                        HStack(spacing: AJSpacing.xs) {
                            ForEach(1...5, id: \.self) { value in
                                Button { rating = value } label: {
                                    AJStar(size: 34, isLit: value <= rating).frame(width: 48, height: 48)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(value) stars")
                                .accessibilityAddTraits(value == rating ? .isSelected : [])
                            }
                        }
                    }
                    CheckInGroup(title: "How itchy was tonight?", options: CheckIn.itch, selection: $itch)
                    CheckInGroup(title: "How did cream time go?", options: CheckIn.cream, selection: $cream)
                }
                .padding(.horizontal, AJSpacing.lg)
                .padding(.top, AJSpacing.lg)
                .frame(maxWidth: .infinity)
            }
            VStack(spacing: AJSpacing.xs) {
                Button("Done. Play affirmations") { finish(logged: true) }.buttonStyle(.ajPrimary)
                Button("Skip. Remind me in the morning") { finish(logged: false) }.buttonStyle(.ajGhost)
            }
            .padding(.horizontal, AJSpacing.lg)
            .padding(.bottom, AJSpacing.md)
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.2)) { starLanded = true }
        }
    }

    private func finish(logged: Bool) {
        appState.finishRitual(storyID: storyID, minutes: minutes, wasFlare: isFlare, rating: rating,
                              itch: logged ? itch : nil, cream: logged ? cream : nil)
        router.open(.dark)
    }
}

/// The answers used by the night and morning check-ins.
enum CheckIn {
    static let itch = ["Calm", "A bit itchy", "Very itchy"]
    static let cream = ["Easy", "Some fuss", "A battle"]
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

/// After the massage: the screen goes dark and affirmations play softly for up to two hours.
struct AffirmationsDarkView: View {
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router
    @State private var startedAt = Date.now

    private let limit: TimeInterval = 2 * 60 * 60

    var body: some View {
        Button(action: wake) {
            VStack(spacing: AJSpacing.sm) {
                AJMoon(size: 70, color: Color(hex: 0x6E6A94))
                Text("Affirmations are playing softly").ajText(.subhead, color: Color(hex: 0x6E6A94))
                Text("Up to 2 hours · tap to wake the screen").ajText(.footnote, color: Color(hex: 0x6E6A94))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: 0x05040F).ignoresSafeArea())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Affirmations are playing. Tap to wake the screen.")
        .onAppear {
            startedAt = .now
            router.startMusic(appState.musicOn, volume: 0.06)
            playLoop()
        }
    }

    private func playLoop() {
        guard appState.voiceOn, Date.now.timeIntervalSince(startedAt) < limit,
              let item = StoryCatalog.item("brave", custom: nil) else {
            if Date.now.timeIntervalSince(startedAt) >= limit { router.quiet() }
            return
        }
        let text = item.lines.joined(separator: " ").personalized(appState.child)
        router.narrator.speak(text, volume: 0.6) {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(8))
                if router.screen == .dark { playLoop() }
            }
        }
    }

    private func wake() {
        appState.selectedTab = .tonight
        router.close()
    }
}
