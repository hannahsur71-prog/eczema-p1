import SwiftUI
import AljiDesignSystem

/// Stories: one library of massage stories, bedtime stories, affirmations and calm moments.
struct StoriesView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @Environment(MainRouter.self) private var router
    @State private var favoritesOnly = false

    private var items: [StoryItem] {
        StoryCatalog.library(custom: appState.customStory).filter { !favoritesOnly || appState.favorites.contains($0.id) }
    }

    private var sections: [(title: String, detail: String, isWide: Bool, items: [StoryItem])] {
        [("Massage stories", "The story guides your hands", true, items.filter { $0.kind == .massage }),
         ("Bedtime stories", "Audio only, 5 to 20 minutes", false, items.filter { $0.kind == .bedtimeStory }),
         ("Affirmations", "Kind words to fall asleep to", false, items.filter { $0.kind == .affirmation }),
         ("Calm moments", "Breathing, and two minutes for you", false, items.filter { $0.kind == .calm })]
            .filter { !$0.items.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AJSpacing.md + 2) {
            AJHighlightedTitle("Stories")
            HStack(spacing: AJSpacing.xs) {
                AJChoiceChip("All", isSelected: !favoritesOnly) { favoritesOnly = false }
                AJChoiceChip("Favorites", isSelected: favoritesOnly) { favoritesOnly = true }
            }
            if !favoritesOnly { createCard }
            ForEach(sections, id: \.title) { section in
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title).ajText(.title2).accessibilityAddTraits(.isHeader)
                        Text(section.detail).ajText(.subhead, color: AJColor.textSecondary)
                    }
                    if section.isWide {
                        VStack(spacing: 10) { ForEach(section.items) { card($0, isWide: true) } }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 10) { ForEach(section.items) { card($0, isWide: false) } }
                        }
                        .padding(.horizontal, -AJSpacing.screenGutter)
                        .contentMargins(.horizontal, AJSpacing.screenGutter, for: .scrollContent)
                    }
                }
            }
            if favoritesOnly && sections.isEmpty {
                Text("No favorites yet. Tap the heart on any story to keep it here.").ajText(.callout, color: AJColor.textSecondary)
            }
        }
    }

    private var createCard: some View {
        Button {
            if store.isSubscribed { router.open(.create) } else { router.showsUpgrade = true }
        } label: {
            HStack(spacing: 14) {
                Image(aj: .sparkles)
                    .ajIcon(24, color: AJColor.onAccent)
                    .frame(width: 48, height: 48)
                    .background(AJColor.accentWarm, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create a story for \(appState.child)").ajText(.bodyStrong)
                    Text("About anything they love, or a lesson you want to teach").ajText(.footnote, color: AJColor.textSecondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AJSpacing.md)
            .padding(.vertical, 14)
            .frame(minHeight: 84)
            .background(AJColor.accentWarm.opacity(0.1), in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous).strokeBorder(AJColor.accentWarm, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func card(_ item: StoryItem, isWide: Bool) -> some View {
        let isLocked = !store.isSubscribed && !StoryCatalog.freeIDs.contains(item.id)
        return AJStoryCard(title: item.title.personalized(appState.child), meta: item.meta, color: Color(hex: item.color), isWide: isWide) {
            router.openStory(item.id, isSubscribed: store.isSubscribed)
        }
        .overlay(alignment: .topTrailing) {
            if isLocked {
                Image(aj: .lock)
                    .ajIcon(12, color: AJColor.accentWarm)
                    .padding(AJSpacing.xs)
                    .background(AJColor.background.opacity(0.7), in: Circle())
                    .padding(AJSpacing.xs)
                    .accessibilityLabel("Needs a subscription")
            }
        }
    }
}

// MARK: - Story page

/// What a story is, how long tonight, why it helps, and Begin.
struct StoryDetailView: View {
    let storyID: String
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router

    var body: some View {
        if let item = StoryCatalog.item(storyID, custom: appState.customStory) {
            content(item)
        } else {
            Color.clear.onAppear { router.close() }
        }
    }

    private func content(_ item: StoryItem) -> some View {
        @Bindable var state = appState
        let child = appState.child
        let color = Color(hex: item.color)
        let isFavorite = appState.favorites.contains(item.id)
        let fact = StoryCatalog.facts[item.factKey] ?? StoryCatalog.facts["quality"]
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.md + 2) {
                    VStack(spacing: 0) {
                        HStack {
                            AJIconButton(.back, accessibilityLabel: "Back") { router.close() }
                            Spacer()
                            Button { appState.toggleFavorite(item.id) } label: {
                                Image(aj: isFavorite ? .heart : .heartOutline).ajIcon(22).frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Favorite")
                            .accessibilityAddTraits(isFavorite ? .isSelected : [])
                        }
                        AJStar(size: 84).padding(.vertical, AJSpacing.lg)
                    }
                    .padding(.horizontal, -6)
                    Text(item.title.personalized(child)).ajText(.display)
                    FlowLayout(spacing: 10) {
                        ForEach(item.chips, id: \.self) { chip in
                            Text(chip.personalized(child))
                                .ajText(.subhead)
                                .padding(.horizontal, AJSpacing.md)
                                .padding(.vertical, 9)
                                .background(Color.white.opacity(0.16), in: Capsule())
                        }
                    }
                    Text(item.summary.personalized(child)).ajText(.callout)
                    if item.kind == .massage {
                        lengthBlock(title: "How long tonight?",
                                    note: "Shorter skips a few extra strokes but keeps the whole story and the calm ending. Gentle narration with soft music underneath.") {
                            AJSegmentedPicker("Massage length", options: [
                                (value: false, label: "Full · \(StoryCatalog.totalMinutes(item, short: false)) min"),
                                (value: true, label: "Shorter · \(StoryCatalog.totalMinutes(item, short: true)) min")
                            ], selection: $state.massageIsShort)
                        }
                    } else if item.hasChapters {
                        lengthBlock(title: "Story length",
                                    note: "Audio only. Longer stories add more adventures; the calm ending stays the same.") {
                            AJSegmentedPicker("Story length", options: StoryLength.allCases.map { (value: $0, label: "\($0.minutes) min") },
                                              selection: $state.storyLength)
                        }
                    }
                    HStack(alignment: .top, spacing: 10) {
                        factTile("Age", item.age)
                        factTile("Length", item.length)
                        factTile("Content type", item.kindLabel)
                    }
                    Text("Benefits:").ajText(.title2).accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: AJSpacing.sm) {
                        ForEach(item.benefits, id: \.self) { AJBenefitRow($0.personalized(child)) }
                    }
                    .padding(.horizontal, AJSpacing.md + 2)
                    .padding(.vertical, AJSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous))
                    if let fact {
                        AJFactCard(eyebrow: "Why it helps", text: fact.text, source: fact.source)
                    }
                    Text("For children with mild to moderate eczema, alongside their prescribed care. Review pending: pediatric dermatologist and certified infant massage educator. No massage on actively flaring or broken skin. Not medical advice.")
                        .ajText(.subhead, color: AJColor.textSecondary)
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.bottom, AJSpacing.lg)
            }
            .background(alignment: .top) {
                LinearGradient(colors: [color, color.opacity(0)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 320)
                    .ignoresSafeArea(edges: .top)
            }
            Button("Begin") { begin(item) }
                .buttonStyle(.ajPrimary)
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.vertical, AJSpacing.md)
        }
    }

    private func lengthBlock<Picker: View>(title: String, note: String, @ViewBuilder picker: () -> Picker) -> some View {
        VStack(alignment: .leading, spacing: AJSpacing.xs) {
            Text(title).ajText(.subhead).bold()
            picker()
            Text(note).ajText(.footnote, color: AJColor.textSecondary)
        }
    }

    private func factTile(_ label: String, _ value: String) -> some View {
        VStack(spacing: 6) {
            Text(label).ajText(.footnoteStrong)
            Text(value)
                .ajText(.subhead)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 84)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func begin(_ item: StoryItem) {
        if item.isAudio {
            router.open(.audio(item.id))
        } else {
            // The story they chose becomes tonight's story (the gentle flare story is always offered separately).
            if item.id != "flareStory" { appState.chooseTonightStory(item.id) }
            router.open(.player(storyID: item.id, isFlare: item.id == "flareStory", greets: false))
        }
    }
}

// MARK: - Create a story

struct CreateStoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router
    @State private var request = CustomStoryRequest()

    var body: some View {
        let child = appState.child
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.md) {
                    AJIconButton(.back, accessibilityLabel: "Back") { router.close() }
                    AJHighlightedTitle("Create a story for \(child)")
                    Text("Lumi writes a massage story \(child) can feel: every part of the story is a touch.")
                        .ajText(.subhead, color: AJColor.textSecondary)
                    Text("What does \(child) love?").ajText(.callout)
                    FlowLayout(spacing: AJSpacing.xs) {
                        ForEach(StoryCatalog.topics, id: \.id) { topic in
                            AJChoiceChip(topic.label, isSelected: request.text.isEmpty && request.topic == topic.id) {
                                request.topic = topic.id
                                request.text = ""
                            }
                        }
                    }
                    AJTextField("Or type anything: grandma's garden, a red tractor…", text: $request.text)
                    Text("What should the story help with?").ajText(.callout)
                    FlowLayout(spacing: AJSpacing.xs) {
                        ForEach(StoryCatalog.lessons, id: \.id) { lesson in
                            AJChoiceChip(lesson.label, isSelected: request.lesson == lesson.id) { request.lesson = lesson.id }
                        }
                    }
                    Text("Lumi writes the words. The massage strokes always come from Snuzzle's reviewed routine, and you can read the story before you play it.")
                        .ajText(.footnote, color: AJColor.textTertiary)
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.top, AJSpacing.xs)
            }
            .scrollDismissesKeyboard(.interactively)
            Button("Write \(child)'s story") {
                appState.customStory = request
                router.open(.creating)
            }
            .buttonStyle(.ajPrimary)
            .padding(.horizontal, AJSpacing.screenGutter)
            .padding(.vertical, AJSpacing.md)
        }
        .onAppear { if let saved = appState.customStory { request = saved } }
    }
}

/// Shows and speaks the new story's title and first line, then opens the story.
struct CreatingStoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router
    @State private var isShown = false

    var body: some View {
        let child = appState.child
        let story = StoryCatalog.customStory(appState.customStory ?? CustomStoryRequest())
        let firstLine = (story.steps.first?.story.components(separatedBy: ". ").first ?? "") + "."
        VStack(spacing: AJSpacing.md) {
            AJMoon(size: 110)
            Text("\(child)'s new story").ajText(.label, color: AJColor.accentWarm)
            Text(story.title).ajText(.title).opacity(isShown ? 1 : 0)
            Text("“\(firstLine)”").italic().ajText(.headline, color: AJColor.textSecondary).opacity(isShown ? 1 : 0)
            Text("Lumi is writing the rest…").ajText(.subhead, color: AJColor.textTertiary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            withAnimation(.easeOut(duration: 0.6)) { isShown = true }
            if appState.voiceOn { router.narrator.speak("\(story.title). \(firstLine)") }
            try? await Task.sleep(for: .seconds(5.2))
            if !Task.isCancelled && router.screen == .creating { router.open(.detail(StoryCatalog.customID)) }
        }
    }
}
