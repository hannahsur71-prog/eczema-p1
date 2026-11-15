import SwiftUI
import AljiDesignSystem

struct TonightView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @State private var showRitual = false
    @State private var showSettings = false
    @State private var showUpgrade = false

    /// Free version: 5-minute ritual and the first story only.
    private var isPremium: Bool { store.isSubscribed }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.lg) {
                    HStack(alignment: .top) {
                        AJScreenHeader(eyebrow: greeting, title: "Tonight for \(appState.answers.displayChild)")
                        AJIconButton(.settings, accessibilityLabel: "Settings") { showSettings = true }
                    }

                    AJCard {
                        AJSectionHeader("Where does skin need care?", trailing: zoneSummary)
                        Text("Tap once for dry, twice for flaring, again to clear.")
                            .ajText(.footnote, color: AJColor.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: AJSpacing.xs), GridItem(.flexible())],
                                  spacing: AJSpacing.xs) {
                            ForEach(CareZone.allCases) { zone in
                                let state = appState.tonightZones[zone]
                                AJStatusTile(title: zone.label,
                                             subtitle: state?.label ?? "Not tonight",
                                             tone: state == nil ? .neutral : (state == .dry ? .calm : .warm)) {
                                    appState.cycle(zone)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AJSpacing.sm) {
                        AJSectionHeader("Ritual length")
                        HStack(spacing: AJSpacing.xs) {
                            ForEach([5, 10, 20], id: \.self) { minutes in
                                let locked = !isPremium && minutes != 5
                                AJChip(locked ? "\(minutes) min · Premium" : "\(minutes) min",
                                       isSelected: effectiveMinutes == minutes) {
                                    if locked { showUpgrade = true } else { appState.tonightMinutes = minutes }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AJSpacing.sm) {
                        AJSectionHeader("Lumi's massage story", trailing: "Guides your hands")
                        ForEach(MassageStoryLibrary.all) { story in
                            let locked = !isPremium && story.id != MassageStoryLibrary.sleepyComet.id
                            AJRadioRow(title: story.title,
                                       subtitle: (locked ? "Premium · " : "") + "\(story.ages) · \(story.blurb)",
                                       isSelected: effectiveMassageStoryID == story.id) {
                                if locked { showUpgrade = true } else { appState.tonightMassageStoryID = story.id }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AJSpacing.sm) {
                        AJSectionHeader("Drift-off story", trailing: "Plays after the massage")
                        ForEach(StoryLibrary.all) { story in
                            let locked = !isPremium && story.id != StoryLibrary.otter.id
                            AJRadioRow(title: story.title, subtitle: locked ? "Premium · \(story.blurb)" : story.blurb,
                                       isSelected: effectiveStoryID == story.id) {
                                if locked { showUpgrade = true } else { appState.tonightStoryID = story.id }
                            }
                        }
                    }

                    AJNotice("Using a prescribed cream? Apply it first, exactly as your doctor directed. Skip broken, oozing or infected skin.")

                    Button("Begin \(effectiveMinutes)-min ritual") { showRitual = true }
                        .buttonStyle(.ajPrimary)
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.vertical, AJSpacing.lg)
            }
            .background(StarryBackground(opacity: 0.3, seed: 19))
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showRitual) {
                RitualPlayerView(
                    steps: RitualBuilder.steps(for: appState.tonightZones,
                                               story: MassageStoryLibrary.story(effectiveMassageStoryID),
                                               grownUp: appState.answers.relationship.storyName),
                    story: StoryLibrary.story(effectiveStoryID),
                    minutes: effectiveMinutes)
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showUpgrade) { PaywallView(context: .upgrade) }
        }
    }

    private var effectiveMinutes: Int { isPremium ? appState.tonightMinutes : 5 }
    private var effectiveMassageStoryID: String {
        isPremium ? appState.tonightMassageStoryID : MassageStoryLibrary.sleepyComet.id
    }
    private var effectiveStoryID: String { isPremium ? appState.tonightStoryID : StoryLibrary.otter.id }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var zoneSummary: String {
        let count = appState.tonightZones.count
        return count == 0 ? "Whole body, gently" : "\(count) \(count == 1 ? "area" : "areas")"
    }
}
