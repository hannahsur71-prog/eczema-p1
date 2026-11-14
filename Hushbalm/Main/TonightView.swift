import SwiftUI
import HushbalmDesignSystem

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
                VStack(alignment: .leading, spacing: HBSpacing.lg) {
                    HStack(alignment: .top) {
                        HBScreenHeader(eyebrow: greeting, title: "Tonight for \(appState.answers.displayChild)")
                        HBIconButton(.settings, accessibilityLabel: "Settings") { showSettings = true }
                    }

                    HBCard {
                        HBSectionHeader("Where does skin need care?", trailing: zoneSummary)
                        Text("Tap once for dry, twice for flaring, again to clear.")
                            .hbText(.footnote, color: HBColor.textSecondary)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: HBSpacing.xs), GridItem(.flexible())],
                                  spacing: HBSpacing.xs) {
                            ForEach(CareZone.allCases) { zone in
                                let state = appState.tonightZones[zone]
                                HBStatusTile(title: zone.label,
                                             subtitle: state?.label ?? "Not tonight",
                                             tone: state == nil ? .neutral : (state == .dry ? .calm : .warm)) {
                                    appState.cycle(zone)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: HBSpacing.sm) {
                        HBSectionHeader("Ritual length")
                        HStack(spacing: HBSpacing.xs) {
                            ForEach([5, 10, 20], id: \.self) { minutes in
                                let locked = !isPremium && minutes != 5
                                HBChip(locked ? "\(minutes) min · Premium" : "\(minutes) min",
                                       isSelected: effectiveMinutes == minutes) {
                                    if locked { showUpgrade = true } else { appState.tonightMinutes = minutes }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: HBSpacing.sm) {
                        HBSectionHeader("Tonight's story")
                        ForEach(StoryLibrary.all) { story in
                            let locked = !isPremium && story.id != StoryLibrary.otter.id
                            HBRadioRow(title: story.title, subtitle: locked ? "Premium · \(story.blurb)" : story.blurb,
                                       isSelected: effectiveStoryID == story.id) {
                                if locked { showUpgrade = true } else { appState.tonightStoryID = story.id }
                            }
                        }
                    }

                    HBNotice("Using a prescribed cream? Apply it first, exactly as your doctor directed. Skip broken, oozing or infected skin.")

                    Button("Begin \(effectiveMinutes)-min ritual") { showRitual = true }
                        .buttonStyle(.hbPrimary)
                }
                .padding(.horizontal, HBSpacing.screenGutter)
                .padding(.vertical, HBSpacing.lg)
            }
            .background(StarryBackground(opacity: 0.3, seed: 19))
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showRitual) {
                RitualPlayerView(
                    steps: RitualBuilder.steps(for: appState.tonightZones),
                    story: StoryLibrary.story(effectiveStoryID),
                    minutes: effectiveMinutes)
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showUpgrade) { PaywallView(context: .upgrade) }
        }
    }

    private var effectiveMinutes: Int { isPremium ? appState.tonightMinutes : 5 }
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
