import SwiftUI
import AljiDesignSystem

struct LibraryView: View {
    @Environment(StoreManager.self) private var store
    @State private var tab = 0
    @State private var openTechnique: MassageTechnique?
    @State private var showUpgrade = false

    /// Free version includes the two core techniques and the first story.
    private let freeTechniques: Set<String> = ["glide", "pat"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.lg) {
                    AJScreenHeader(title: "Library")
                    HStack(spacing: AJSpacing.xs) {
                        AJChip("Massages", isSelected: tab == 0) { tab = 0 }
                        AJChip("Stories", isSelected: tab == 1) { tab = 1 }
                    }
                    if tab == 0 {
                        ForEach(MassageLibrary.all) { technique in
                            let locked = !store.isSubscribed && !freeTechniques.contains(technique.id)
                            row(title: technique.title, subtitle: technique.detail, locked: locked) {
                                if locked { showUpgrade = true } else { openTechnique = technique }
                            }
                        }
                    } else {
                        ForEach(StoryLibrary.all) { story in
                            let locked = !store.isSubscribed && story.id != StoryLibrary.otter.id
                            row(title: story.title, subtitle: "\(story.minutes) min · \(story.blurb)", locked: locked) {
                                if locked { showUpgrade = true }
                            }
                        }
                        Text("Pick tonight's story on the Tonight tab.").ajText(.footnote, color: AJColor.textSecondary)
                    }
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.vertical, AJSpacing.lg)
            }
            .background(AJColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $openTechnique) { TechniqueDetail(technique: $0) }
            .sheet(isPresented: $showUpgrade) { PaywallView(context: .upgrade) }
        }
    }

    private func row(title: String, subtitle: String, locked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AJSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).ajText(.headline)
                    Text(subtitle).ajText(.footnote, color: AJColor.textSecondary)
                }
                Spacer()
                if locked {
                    HStack(spacing: 4) {
                        Image(aj: .lock).ajIcon(12, color: AJColor.accentWarm)
                        Text("Premium").ajText(.label, color: AJColor.accentWarm)
                    }
                }
            }
            .padding(AJSpacing.md)
            .frame(maxWidth: .infinity, minHeight: AJSize.rowMinHeight, alignment: .leading)
            .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct TechniqueDetail: View {
    let technique: MassageTechnique

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AJSpacing.lg) {
                AJScreenHeader(eyebrow: technique.detail, title: technique.title)
                ForEach(Array(technique.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: AJSpacing.sm) {
                        Text("\(index + 1)")
                            .ajText(.headline, color: AJColor.onAccent)
                            .frame(width: 30, height: 30)
                            .background(AJColor.accentCalm, in: Circle())
                        Text(step).ajText(.body)
                    }
                }
                AJNotice(AppConfig.medicalDisclaimer)
            }
            .padding(AJSpacing.screenGutter)
        }
        .background(AJColor.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
