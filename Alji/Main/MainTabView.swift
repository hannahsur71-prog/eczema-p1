import SwiftUI
import AljiDesignSystem

/// The main app: three tabs, with full-screen pages (story, player, audio) shown over them.
struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var router = MainRouter()
    @State private var showSettings = false

    var body: some View {
        ZStack {
            tabs
            if let panel = router.panel {
                switch panel {
                case .skin: SkinTonightPanel()
                case .plan: TonightPlanPanel()
                }
            }
            if let screen = router.screen {
                page(screen)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(MainSky())
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: router.screen)
        .animation(.easeInOut(duration: 0.2), value: router.panel)
        .environment(router)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: Bindable(router).showsUpgrade) { PaywallView(context: .upgrade) }
    }

    private var tabs: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.lg) {
                    childButton
                    switch appState.selectedTab {
                    case .tonight: TonightView()
                    case .stories: StoriesView()
                    case .progress: ProgressTabView()
                    }
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.top, AJSpacing.xs)
                .padding(.bottom, AJSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            tabBar
        }
        .background(MainSky())
    }

    /// The child's name. Opens settings (one child for now).
    private var childButton: some View {
        Button { showSettings = true } label: {
            HStack(spacing: 10) {
                Text(String(appState.child.prefix(1)).uppercased())
                    .ajText(.headline, color: AJColor.onAccent)
                    .frame(width: 42, height: 42)
                    .background(AJColor.accentWarm, in: Circle())
                Text(appState.child).ajText(.title2)
                Image(aj: .chevronDown).ajIcon(12)
            }
            .padding(.leading, 6)
            .padding(.trailing, AJSpacing.md)
            .frame(height: 52)
            .background(AJColor.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(AJColor.borderQuiet, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(appState.child). Settings")
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.tonight, "Tonight", .home)
            tabButton(.stories, "Stories", .stories)
            tabButton(.progress, "Progress", .progress)
        }
        .padding(.top, 10)
        .padding(.horizontal, 6)
        .background(AJColor.background.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.14)).frame(height: 1) }
    }

    private func tabButton(_ tab: MainTab, _ label: String, _ icon: AJIcon) -> some View {
        let isOn = appState.selectedTab == tab
        let color = isOn ? AJColor.accentCalm : AJColor.textTertiary
        return Button { appState.selectedTab = tab } label: {
            VStack(spacing: AJSpacing.xxs) {
                Image(aj: icon).ajIcon(AJSize.iconMedium, color: color)
                Text(label).ajText(.footnote, color: color)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    @ViewBuilder
    private func page(_ screen: MainScreen) -> some View {
        switch screen {
        case .detail(let id): StoryDetailView(storyID: id)
        case .ready: ReadyChecklistView()
        case .player(let id, let isFlare, let greets): MassagePlayerView(storyID: id, isFlare: isFlare, greets: greets)
        case .end(let id, let minutes, let isFlare): RitualEndView(storyID: id, minutes: minutes, isFlare: isFlare)
        case .dark: AffirmationsDarkView()
        case .audio(let id): AudioPlayerView(storyID: id)
        case .create: CreateStoryView()
        case .creating: CreatingStoryView()
        }
    }
}

/// The app's background: deep blue at the top, fading into the night indigo.
struct MainSky: View {
    var body: some View {
        ZStack(alignment: .top) {
            AJColor.background
            LinearGradient(colors: [Color(hex: 0x16245C), Color(hex: 0x1F2C68), AJColor.background],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 300)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// A dimmed backdrop with a panel rising from the bottom, like the prototype's sheets.
struct BottomPanel<Content: View>: View {
    let onClose: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AJSpacing.sm) { content }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.top, AJSpacing.md + AJSpacing.xxs)
                .padding(.bottom, AJSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26, style: .continuous)
                        .fill(Color(hex: 0x2B2760))
                        .ignoresSafeArea(edges: .bottom)
                )
        }
        .transition(.opacity)
    }
}
