import SwiftUI
import SwiftData
import StoreKit
import AljiDesignSystem

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
            AJScreenHeader(eyebrow: "Takes 2 seconds",
                           title: "How itchy was \(appState.answers.displayChild) tonight?")
            HStack(spacing: AJSpacing.xs) {
                ForEach(1...5, id: \.self) { value in
                    AJChip("\(value)", isSelected: itch == value) { itch = value }
                        .accessibilityLabel("Itch \(value) of 5")
                }
            }
            HStack {
                Text("Calm").ajText(.footnote, color: AJColor.textSecondary)
                Spacer()
                Text("Very itchy").ajText(.footnote, color: AJColor.textSecondary)
            }
            AJSectionHeader("Anything to note?", trailing: "Optional")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: AJSpacing.xs), GridItem(.flexible())], spacing: AJSpacing.xs) {
                ForEach(NightTags.all, id: \.self) { tag in
                    AJChip(tag, isSelected: tags.contains(tag)) {
                        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                    }
                }
            }
        } footer: {
            Button("Save tonight") { save() }
                .buttonStyle(.ajPrimary)
                .disabled(itch == 0)
            Button("Skip") { dismiss() }.buttonStyle(.ajGhost)
        }
        .background(AJColor.background.ignoresSafeArea())
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
