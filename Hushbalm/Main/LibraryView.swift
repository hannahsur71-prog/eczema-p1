import SwiftUI
import HushbalmDesignSystem

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
                VStack(alignment: .leading, spacing: HBSpacing.lg) {
                    HBScreenHeader(title: "Library")
                    HStack(spacing: HBSpacing.xs) {
                        HBChip("Massages", isSelected: tab == 0) { tab = 0 }
                        HBChip("Stories", isSelected: tab == 1) { tab = 1 }
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
                        Text("Pick tonight's story on the Tonight tab.").hbText(.footnote, color: HBColor.textSecondary)
                    }
                }
                .padding(.horizontal, HBSpacing.screenGutter)
                .padding(.vertical, HBSpacing.lg)
            }
            .background(HBColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $openTechnique) { TechniqueDetail(technique: $0) }
            .sheet(isPresented: $showUpgrade) { PaywallView(context: .upgrade) }
        }
    }

    private func row(title: String, subtitle: String, locked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: HBSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).hbText(.headline)
                    Text(subtitle).hbText(.footnote, color: HBColor.textSecondary)
                }
                Spacer()
                if locked {
                    HStack(spacing: 4) {
                        Image(hb: .lock).hbIcon(12, color: HBColor.accentWarm)
                        Text("Premium").hbText(.label, color: HBColor.accentWarm)
                    }
                }
            }
            .padding(HBSpacing.md)
            .frame(maxWidth: .infinity, minHeight: HBSize.rowMinHeight, alignment: .leading)
            .background(HBColor.surface, in: RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct TechniqueDetail: View {
    let technique: MassageTechnique

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HBSpacing.lg) {
                HBScreenHeader(eyebrow: technique.detail, title: technique.title)
                ForEach(Array(technique.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: HBSpacing.sm) {
                        Text("\(index + 1)")
                            .hbText(.headline, color: HBColor.onAccent)
                            .frame(width: 30, height: 30)
                            .background(HBColor.accentCalm, in: Circle())
                        Text(step).hbText(.body)
                    }
                }
                HBNotice(AppConfig.medicalDisclaimer)
            }
            .padding(HBSpacing.screenGutter)
        }
        .background(HBColor.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
