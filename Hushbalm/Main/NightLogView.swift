import SwiftUI
import SwiftData
import StoreKit
import HushbalmDesignSystem

/// The 2-second nightly check-in that builds the doctor report.
struct NightLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview
    @Environment(AppState.self) private var appState
    @Query private var logs: [NightLog]
    let minutes: Int
    let storyID: String

    @State private var itch = 0
    @State private var tags: Set<String> = []

    var body: some View {
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "Takes 2 seconds",
                           title: "How itchy was \(appState.answers.displayChild) tonight?")
            HStack(spacing: HBSpacing.xs) {
                ForEach(1...5, id: \.self) { value in
                    HBChip("\(value)", isSelected: itch == value) { itch = value }
                        .accessibilityLabel("Itch \(value) of 5")
                }
            }
            HStack {
                Text("Calm").hbText(.footnote, color: HBColor.textSecondary)
                Spacer()
                Text("Very itchy").hbText(.footnote, color: HBColor.textSecondary)
            }
            HBSectionHeader("Anything to note?", trailing: "Optional")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: HBSpacing.xs), GridItem(.flexible())], spacing: HBSpacing.xs) {
                ForEach(NightTags.all, id: \.self) { tag in
                    HBChip(tag, isSelected: tags.contains(tag)) {
                        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                    }
                }
            }
        } footer: {
            Button("Save tonight") { save() }
                .buttonStyle(.hbPrimary)
                .disabled(itch == 0)
            Button("Skip") { dismiss() }.buttonStyle(.hbGhost)
        }
        .background(HBColor.background.ignoresSafeArea())
    }

    private func save() {
        let log = NightLog(itch: itch, tags: Array(tags).sorted(),
                           zoneIDs: appState.tonightZones.keys.map(\.rawValue).sorted(),
                           ritualMinutes: minutes, storyID: storyID)
        context.insert(log)
        try? context.save()
        // Ask for a rating after the third logged night, when they've seen real value.
        if logs.count + 1 == 3 { requestReview() }
        dismiss()
    }
}
