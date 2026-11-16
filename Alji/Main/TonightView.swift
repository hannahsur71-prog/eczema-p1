import SwiftUI
import AljiDesignSystem

/// Tonight: one screen, one button. Changes by itself from bedtime, to goodnight, to the morning check-in, to the result.
struct TonightView: View {
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router

    @State private var itch: String?
    @State private var rating = 0
    @State private var fall: String?
    @State private var wakes: String?

    private var child: String { appState.child }

    var body: some View {
        VStack(spacing: 14) {
            switch appState.phase() {
            case .bedtime: bedtime
            case .after: after
            case .morning: morning
            case .result: result
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }

    // MARK: Bedtime

    @ViewBuilder
    private var bedtime: some View {
        let story = TonightPlan.story(appState)
        AJMoon(size: 150)
        Text(appState.isNewStoryTonight ? "New story tonight for \(child)" : "Tonight with \(child)").ajText(.label, color: AJColor.accentWarm)
        Text(story.title.personalized(child)).ajText(.display)
        Text("\(TonightPlan.minutes(appState)) minutes · screen-free for \(child)").ajText(.callout, color: AJColor.textSecondary)
        Button("Start tonight's ritual") { router.panel = .skin }
            .buttonStyle(.ajPrimary)
            .padding(.top, 14)
        HStack(spacing: 10) {
            Button("Change story") { appState.selectedTab = .stories }.buttonStyle(.ajOutline)
            Button("Tonight's plan") { router.panel = .plan }.buttonStyle(.ajOutline)
        }
        Text(quietLine).ajText(.subhead, color: AJColor.textTertiary).padding(.top, 10)
    }

    /// A quiet line of real progress under the buttons.
    private var quietLine: String {
        let night = appState.nights.count + 1
        let stats = ProgressStats(nights: appState.nights)
        if let faster = stats.minutesFasterThisWeek, faster > 0 {
            return "Night \(night) · \(child) fell asleep \(faster) minutes faster this week"
        }
        return night == 1 ? "Night 1 · \(child)'s first star is waiting" : "Night \(night) of \(child)'s bedtime ritual"
    }

    // MARK: After the ritual

    @ViewBuilder
    private var after: some View {
        AJMoon(size: 150)
        AJHighlightedTitle("Goodnight, *\(child)*", style: .display)
        Text("Rest now. One quiet notification in the morning will ask how the night went.")
            .ajText(.callout, color: AJColor.textSecondary)
    }

    // MARK: Morning

    @ViewBuilder
    private var morning: some View {
        Text("Good morning").ajText(.label, color: AJColor.accentWarm)
        AJHighlightedTitle("How did *\(child)* sleep?")
        VStack(alignment: .leading, spacing: AJSpacing.md + 2) {
            CheckInGroup(title: "How itchy was last night?", options: CheckIn.itch, selection: $itch)
            CheckInGroup(title: "How long did \(child) take to fall asleep?", options: CheckIn.fall, selection: $fall)
            CheckInGroup(title: "Wake-ups in the night?", options: CheckIn.wakes, selection: $wakes)
            VStack(alignment: .leading, spacing: AJSpacing.xs) {
                Text("Did \(child) enjoy last night's story?").ajText(.callout)
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
        }
        .multilineTextAlignment(.leading)
        .padding(.top, 6)
        Button("See how last night went") {
            guard let itch, let fall, let wakes else { return }
            appState.saveMorning(itch: itch, rating: rating, fallMinutes: CheckIn.fallMinutes(fall), wakes: CheckIn.wakeCount(wakes))
        }
        .buttonStyle(.ajPrimary)
        .disabled(itch == nil || fall == nil || wakes == nil)
        .padding(.top, AJSpacing.xs)
    }

    // MARK: Result

    @ViewBuilder
    private var result: some View {
        let last = appState.nights.last
        let fell = last?.fallMinutes ?? 0
        let wakeCount = last?.wakes ?? 0
        let first = appState.nights.dropLast().first { $0.fallMinutes != nil }
        let compare: String = {
            guard let firstFall = first?.fallMinutes else { return "This is your starting point." }
            return fell < firstFall ? "On night 1 it was \(firstFall)." : "Night 1 was \(firstFall). Hard nights happen."
        }()
        let wakeLine = wakeText(wakeCount) + (first?.wakes.map { " On night 1 there were \(countText($0))." } ?? "")
        AJMoon(size: 110)
        Text("Last night").ajText(.label, color: AJColor.accentWarm)
        AJHighlightedTitle("\(child) fell asleep in *\(fell) minutes*.", style: .display)
        Text(compare).ajText(.headline, color: AJColor.accentWarm)
        Text(wakeLine).ajText(.callout, color: AJColor.textSecondary)
        // A small reward every morning, from the very first night.
        VStack(alignment: .leading, spacing: AJSpacing.xxs) {
            Text("Star \(appState.nights.count) is on \(child)'s moon").ajText(.footnoteStrong, color: AJColor.accentWarm)
            Text(morningTip(last?.itch)).ajText(.subhead)
            Text("Tonight: \(TonightPlan.story(appState).title.personalized(child))").ajText(.footnote, color: AJColor.textSecondary)
        }
        .multilineTextAlignment(.leading)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AJColor.accentWarm.opacity(0.1), in: RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous).strokeBorder(AJColor.accentWarm.opacity(0.45), lineWidth: 1.5))
        .padding(.top, 6)
        ShareLink(item: "\(child) fell asleep in \(fell) minutes last night. \(compare) \(wakeLine)") {
            Text("Share with your partner")
        }
        .buttonStyle(.ajPrimary)
        .padding(.top, AJSpacing.md)
        Button("See all progress") { appState.selectedTab = .progress }.buttonStyle(.ajGhost)
    }
}

private extension TonightView {
    /// One line that answers what the parent just told us.
    func morningTip(_ itch: String?) -> String {
        switch itch {
        case "A bit itchy": return "A bit itchy, and \(child) still settled. The ritual is doing its job."
        case "Very itchy": return "Itchy nights are the hardest. If the skin is flaring tonight, choose Flaring for the gentler story."
        default: return "A calm night. The same time tonight keeps it going."
        }
    }

    func countText(_ count: Int) -> String { count >= 3 ? "3+" : "\(count)" }

    func wakeText(_ count: Int) -> String {
        switch count {
        case 0: return "No wake-ups."
        case 1: return "1 wake-up."
        default: return "\(countText(count)) wake-ups."
        }
    }
}

// MARK: - Tonight's plan

/// Tonight's story and the family's own timeline around it.
enum TonightPlan {
    @MainActor
    static func story(_ appState: AppState) -> StoryItem {
        StoryCatalog.item(appState.tonightStoryID, custom: appState.customStory) ?? StoryCatalog.all[0]
    }

    @MainActor
    static func minutes(_ appState: AppState) -> Int {
        max(1, StoryCatalog.totalMinutes(story(appState), short: appState.massageIsShort))
    }

    /// Rows of (time, title, detail), counted back from the child's sleep time.
    @MainActor
    static func rows(_ appState: AppState) -> [(time: String, title: String, detail: String)] {
        let answers = appState.answers
        // The reminder fires 30 minutes before the chosen sleep time.
        let bed = answers.reminderHour * 60 + answers.reminderMinute + 30
        let ritual = minutes(appState)
        let child = appState.child
        func time(_ minutes: Int) -> String {
            let hour = (minutes / 60 + 11) % 12 + 1
            return "\(hour):" + String(format: "%02d", minutes % 60)
        }
        return [
            (time(bed - 60), "Screens off", "No TV or tablets from here"),
            (time(bed - 45), "Dim the lights", "Lamps only, warm light"),
            (time(bed - ritual - 25), "Lukewarm bath", "5–10 minutes, then pat dry"),
            (time(bed - ritual - 14), "Prescribed cream first", "Exactly as \(child)'s doctor directed"),
            (time(bed - ritual - 12), story(appState).title.personalized(child), "\(ritual)-minute massage story"),
            (time(bed - 12), "Affirmations, playing softly", "Kind words in the background, up to 2 hours"),
            (time(bed), "Asleep", "Log tonight in 2 seconds")
        ]
    }
}

/// "How's the skin tonight?" The story starts as soon as the parent chooses.
struct SkinTonightPanel: View {
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router

    var body: some View {
        BottomPanel(onClose: { router.panel = nil }) {
            AJSheetHeader("How's *\(appState.child)'s* skin tonight?") { router.panel = nil }
            HStack(spacing: 10) {
                Button { router.open(.player(storyID: TonightPlan.story(appState).id, isFlare: false, greets: true)) } label: {
                    VStack(spacing: 6) {
                        Text("Calm").ajText(.title2)
                        Text("Tonight's full massage story").ajText(.footnote)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(AJColor.action, in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
                }
                Button { router.open(.player(storyID: "flareStory", isFlare: true, greets: true)) } label: {
                    VStack(spacing: 6) {
                        Text("Flaring").ajText(.title2)
                        Text("A shorter, gentler story. Cream only on flaring spots.").ajText(.footnote, color: AJColor.coralText)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 120)
                    .background(AJColor.coral.opacity(0.16), in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous).strokeBorder(AJColor.coral, lineWidth: 1.5))
                }
            }
            .buttonStyle(.plain)
            Text("The story starts as soon as you choose.")
                .ajText(.footnote, color: AJColor.textTertiary)
                .frame(maxWidth: .infinity)
        }
    }
}

struct TonightPlanPanel: View {
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router

    var body: some View {
        BottomPanel(onClose: { router.panel = nil }) {
            AJSheetHeader("Tonight's plan") { router.panel = nil }
            ForEach(Array(TonightPlan.rows(appState).enumerated()), id: \.offset) { _, row in
                HStack(spacing: AJSpacing.sm) {
                    Text(row.time).ajText(.footnoteStrong, color: AJColor.accentWarm).frame(width: 40, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(row.title).ajText(.subhead).bold()
                        Text(row.detail).ajText(.footnote, color: AJColor.textSecondary)
                    }
                    .padding(.horizontal, AJSpacing.sm)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
                }
                .accessibilityElement(children: .combine)
            }
            Button("Getting-ready checklist") { router.open(.ready) }.buttonStyle(.ajOutline)
        }
    }
}

// MARK: - Before we begin

/// An optional checklist before the massage. Nothing is required.
struct ReadyChecklistView: View {
    @Environment(AppState.self) private var appState
    @Environment(MainRouter.self) private var router
    @State private var done: Set<String> = []
    @State private var isFlare = false

    private let items: [(id: String, label: String, hint: String)] = [
        ("screens", "Screens off", "No TV or tablets in the hour before bed"),
        ("lights", "Lights dimmed", "Warm lamps only"),
        ("room", "Cool room, cotton pajamas", "Heat and scratchy fabrics can make itch worse"),
        ("bath", "Bath done, skin still damp", "Lukewarm, 5 to 10 minutes, then pat dry"),
        ("rx", "Prescribed cream on first", "Exactly as your doctor directed. Skip if not prescribed."),
        ("cream", "Moisturizer within reach", "A generous amount, warmed in your hands")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.md) {
                    HStack {
                        AJIconButton(.back, accessibilityLabel: "Back") { router.close() }
                        Spacer()
                        Text("\(done.count) of \(items.count) ready").ajText(.subhead, color: AJColor.accentWarm)
                    }
                    AJHighlightedTitle("Before we begin")
                    AJSwitchRow("Skin flaring tonight?", detail: "Switches to the shorter, gentler story", isOn: $isFlare)
                    Text("Tick what's done. Nothing here is required, but each one makes tonight easier.")
                        .ajText(.callout, color: AJColor.textSecondary)
                    VStack(spacing: 10) {
                        ForEach(items, id: \.id) { item in
                            AJChecklistRow(item.label, detail: item.hint, isDone: done.contains(item.id)) {
                                if done.contains(item.id) { done.remove(item.id) } else { done.insert(item.id) }
                            }
                        }
                    }
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.top, AJSpacing.xs)
            }
            Button(isFlare ? "Start the gentle massage" : "Start the massage story") {
                router.open(.player(storyID: isFlare ? "flareStory" : TonightPlan.story(appState).id, isFlare: isFlare, greets: true))
            }
            .buttonStyle(.ajPrimary)
            .padding(.horizontal, AJSpacing.screenGutter)
            .padding(.vertical, AJSpacing.md)
        }
    }
}
