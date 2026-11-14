import SwiftUI

/// A living reference of the design system. Open it in an Xcode preview,
/// or show it from a debug menu, to review every token and component.
public struct HBCatalogView: View {
    @State private var selectedLength = 10
    @State private var tileTone: HBStatusTile.Tone = .calm
    @State private var selectedStory = 0

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HBSpacing.xl) {
                HBScreenHeader(eyebrow: "Design system", title: "Hushbalm",
                               subtitle: "One font family, one palette, one set of components.", isHero: true)

                colors
                typography
                buttons
                selection
                containers
            }
            .padding(.horizontal, HBSpacing.screenGutter)
            .padding(.vertical, HBSpacing.xl)
        }
        .background(HBColor.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Sections

    private var colors: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Color")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: HBSpacing.sm) {
                ForEach(Swatch.all) { swatch in
                    HStack(spacing: HBSpacing.sm) {
                        RoundedRectangle(cornerRadius: HBRadius.sm, style: .continuous)
                            .fill(swatch.color)
                            .frame(width: 40, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: HBRadius.sm, style: .continuous)
                                .strokeBorder(HBColor.border, lineWidth: 1))
                        Text(swatch.name).hbText(.footnote)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var typography: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Type · SF Pro Rounded", trailing: "Scales with Dynamic Type")
            ForEach(HBTextStyle.allCases, id: \.self) { style in
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.name).hbText(.label, color: HBColor.textSecondary)
                    Text("Warm the lotion in your hands").hbText(style)
                }
            }
        }
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Buttons")
            Button("Begin 10-min ritual") {}.buttonStyle(.hbPrimary)
            Button("Dim screen") {}.buttonStyle(.hbSecondary)
            Button("Skip tonight") {}.buttonStyle(.hbGhost)
            Button("Save and see report") {}.buttonStyle(.hbPrimary).disabled(true)
            HBIconButton(.back, accessibilityLabel: "Back") {}
        }
    }

    private var selection: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Selection")
            HStack(spacing: HBSpacing.xs) {
                ForEach([5, 10, 20], id: \.self) { minutes in
                    HBChip("\(minutes) min", isSelected: selectedLength == minutes) { selectedLength = minutes }
                }
            }
            HBStatusTile(title: "Behind knees", subtitle: subtitle(for: tileTone), tone: tileTone) {
                tileTone = next(after: tileTone)
            }
            HBRadioRow(title: "Sleepy Otter and the Cool River", subtitle: "Calm river sounds",
                       isSelected: selectedStory == 0) { selectedStory = 0 }
            HBRadioRow(title: "Yearly", subtitle: "7-day free trial", trailing: "$49.99",
                       isSelected: selectedStory == 1) { selectedStory = 1 }
        }
    }

    private var containers: some View {
        VStack(alignment: .leading, spacing: HBSpacing.sm) {
            HBSectionHeader("Containers & feedback")
            HBCard {
                HBSectionHeader("Where does skin need care?", trailing: "3 areas")
                Text("Tap once for dry, twice for flaring.").hbText(.footnote, color: HBColor.textSecondary)
            }
            HStack(spacing: HBSpacing.xs) {
                HBBadge("Glide · dry skin", tone: .calm)
                HBBadge("Pat · flaring", tone: .warm)
            }
            HBSegmentedProgress(total: 5, current: 2, fraction: 0.4)
            HBNotice("Using a prescribed cream? Apply it first, exactly as your doctor directed.")
        }
    }

    // MARK: Helpers

    private func next(after tone: HBStatusTile.Tone) -> HBStatusTile.Tone {
        switch tone {
        case .neutral: return .calm
        case .calm: return .warm
        case .warm: return .neutral
        }
    }

    private func subtitle(for tone: HBStatusTile.Tone) -> String {
        switch tone {
        case .neutral: return "Not tonight"
        case .calm: return "Dry · glide"
        case .warm: return "Flaring · pat"
        }
    }
}

private struct Swatch: Identifiable {
    let name: String
    let color: Color
    var id: String { name }

    static let all: [Swatch] = [
        Swatch(name: "background", color: HBColor.background),
        Swatch(name: "surface", color: HBColor.surface),
        Swatch(name: "surfaceRaised", color: HBColor.surfaceRaised),
        Swatch(name: "border", color: HBColor.border),
        Swatch(name: "textPrimary", color: HBColor.textPrimary),
        Swatch(name: "textSecondary", color: HBColor.textSecondary),
        Swatch(name: "accentCalm", color: HBColor.accentCalm),
        Swatch(name: "accentWarm", color: HBColor.accentWarm)
    ]
}

#Preview("Design system") {
    HBCatalogView()
}
