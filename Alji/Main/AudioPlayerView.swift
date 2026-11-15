import SwiftUI
import AljiDesignSystem

/// Audio-only player for bedtime stories, affirmations and calm moments.
struct AudioPlayerView: View {
    let storyID: String
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router

    @State private var isPlaying = false
    @State private var chapter = 0
    @State private var showsText = false
    @State private var showLength = false
    @State private var showTimer = false
    @State private var timerMinutes = 60
    @State private var timerRun = 0

    private var item: StoryItem? { StoryCatalog.item(storyID, custom: nil) }
    private var parts: [StoryChapter] {
        guard let item, item.hasChapters else { return [] }
        return StoryCatalog.parts(item, length: appState.storyLength)
    }
    private var lines: [String] {
        guard let item else { return [] }
        return (item.lines.isEmpty ? [item.summary] : item.lines).map { $0.personalized(appState.child) }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: AJSpacing.xs) {
                    AJIconButton(.back, accessibilityLabel: "Back") { router.close() }
                    Text(item?.title.personalized(appState.child) ?? "").ajText(.headline).lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.top, AJSpacing.xs)
                ScrollView {
                    Group {
                        if item?.hasChapters == true { storyBody } else { linesBody }
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                }
                controls
            }
            if showLength { lengthPanel }
            if showTimer { timerPanel }
        }
        .background(LinearGradient(colors: [Color(hex: 0x4A3F8F), Color(hex: 0x2C2B5E)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: showLength)
        .animation(.easeInOut(duration: 0.2), value: showTimer)
        .onAppear {
            showsText = item?.kind == .affirmation
            play(from: 0)
        }
        .task(id: timerRun) {
            // Sleep timer: fade out when the time is up.
            try? await Task.sleep(for: .seconds(timerMinutes * 60))
            if !Task.isCancelled { pause() }
        }
    }

    // MARK: Body

    private var storyBody: some View {
        let current = parts.indices.contains(chapter) ? parts[chapter] : nil
        return VStack(spacing: AJSpacing.md) {
            AJMoon(size: 150)
            Text(chapter < parts.count - 1 ? "Chapter \(chapter + 1) of \(parts.count - 1)" : "The ending")
                .ajText(.label, color: AJColor.accentWarm)
            Text(current?.title ?? "").ajText(.title2).multilineTextAlignment(.center)
            HStack(spacing: 6) {
                ForEach(parts.indices, id: \.self) { index in
                    Capsule()
                        .fill(index < chapter ? AJColor.accentWarm : (index == chapter ? Color.white : Color.white.opacity(0.25)))
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: 220)
            .accessibilityHidden(true)
            Text("About \(appState.storyLength.minutes) minutes · audio only").ajText(.subhead, color: AJColor.textSecondary)
            HStack(spacing: 10) {
                Image(aj: .dim).ajIcon(18, color: AJColor.accentWarm)
                Text("Audio only. Turn the phone face down and let the story do the rest.").ajText(.subhead, color: AJColor.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, AJSpacing.sm)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous))
        }
    }

    @ViewBuilder
    private var linesBody: some View {
        if showsText {
            VStack(alignment: .leading, spacing: 22) {
                ForEach(lines, id: \.self) { Text($0).ajText(.title2) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            AJMoon(size: 200).padding(.top, AJSpacing.xl)
        }
    }

    private var controls: some View {
        HStack(alignment: .top) {
            if item?.hasChapters == true {
                control("\(appState.storyLength.minutes) min", .hourglass, isOn: true, label: "Story length") {
                    showLength = true
                }
            } else {
                control("Text", .text, isOn: showsText, label: "Show text") { showsText.toggle() }
            }
            Spacer(minLength: 0)
            control("Voice", .voice, isOn: appState.voiceOn, label: "Voice") {
                appState.voiceOn.toggle()
                if appState.voiceOn { play(from: chapter) } else { router.narrator.stop() }
            }
            Spacer(minLength: 0)
            Button { if isPlaying { pause() } else { play(from: chapter) } } label: {
                Image(aj: isPlaying ? .pause : .play)
                    .ajIcon(26, color: AJColor.onAccent)
                    .frame(width: 72, height: 72)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pause" : "Play")
            Spacer(minLength: 0)
            control(timerMinutes >= 60 ? "\(timerMinutes / 60) h" : "\(timerMinutes) m", .timer, isOn: false, label: "Sleep timer") {
                showTimer = true
            }
            Spacer(minLength: 0)
            control("Music", .music, isOn: appState.musicOn, label: "Background music") {
                appState.musicOn.toggle()
                if appState.musicOn { router.startMusic(isPlaying) } else { router.music.fadeOut(over: 1.5) }
            }
        }
        .padding(.horizontal, AJSpacing.screenGutter)
        .padding(.top, 20)
        .padding(.bottom, AJSpacing.md)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                .fill(Color(hex: 0x282850, opacity: 0.8))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func control(_ title: String, _ icon: AJIcon, isOn: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(aj: icon)
                    .ajIcon(20)
                    .frame(width: 52, height: 52)
                    .background(isOn ? AJColor.action : Color.white.opacity(0.18), in: Circle())
                Text(title).ajText(.footnote)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(title)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: Panels

    private var lengthPanel: some View {
        let options: [(StoryLength, String, String, String)] = [
            (.short, "Short", "About 5 min", "The beginning and the calm ending"),
            (.medium, "Medium", "About 10 min", "Adds an adventure in the middle"),
            (.long, "Long", "About 20 min", "The whole story, every chapter")]
        return BottomPanel(onClose: { showLength = false }) {
            AJSheetHeader("How long tonight?") { showLength = false }
            ForEach(options, id: \.0) { option in
                AJRadioRow(title: option.1, subtitle: option.3, trailing: option.2, isSelected: appState.storyLength == option.0) {
                    appState.storyLength = option.0
                    showLength = false
                    play(from: 0)
                }
            }
            Text("Every length ends the same calm way, so the story always lands softly.").ajText(.footnote, color: AJColor.textSecondary)
        }
    }

    private var timerPanel: some View {
        let options = [(15, "15 minutes"), (30, "30 minutes"), (60, "1 hour"), (120, "2 hours")]
        return BottomPanel(onClose: { showTimer = false }) {
            AJSheetHeader("Keep playing for") { showTimer = false }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                ForEach(options, id: \.0) { option in
                    AJChoiceChip(option.1, isSelected: timerMinutes == option.0) {
                        timerMinutes = option.0
                        timerRun += 1
                        showTimer = false
                    }
                }
            }
            Text("Audio fades out gently when the timer ends.").ajText(.footnote, color: AJColor.textSecondary)
        }
    }

    // MARK: Playback

    private func play(from start: Int) {
        guard item != nil else { return }
        isPlaying = true
        router.startMusic(appState.musicOn)
        guard appState.voiceOn else { return }
        if parts.isEmpty {
            router.narrator.speak(lines.joined(separator: " ")) { isPlaying = false }
        } else {
            speakChapter(min(max(0, start), parts.count - 1))
        }
    }

    private func speakChapter(_ index: Int) {
        let all = parts
        guard all.indices.contains(index) else {
            isPlaying = false
            router.music.fadeOut(over: 4)
            return
        }
        chapter = index
        let part = all[index]
        router.narrator.speak("\(part.title). \(part.text.personalized(appState.child))") {
            speakChapter(index + 1)
        }
    }

    private func pause() {
        isPlaying = false
        router.narrator.stop()
        router.music.fadeOut(over: 1.5)
    }
}
