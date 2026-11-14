import SwiftUI
import HushbalmDesignSystem

/// Short "did you know" screens between questions. Every fact is cited; nothing invented.
enum Insight: String, Hashable {
    case sleepFacts, notYou, touchAdapt, massageEvidence, parentToo
}

struct InsightScreen: View {
    @Environment(AppState.self) private var appState
    let insight: Insight
    let next: () -> Void

    var body: some View {
        let content = makeContent(appState.answers)
        OnboardingScaffold {
            Spacer(minLength: HBSpacing.md)
            HStack {
                Spacer()
                ZStack {
                    Circle().fill(HBColor.surface).frame(width: 150, height: 150)
                    HBStarField(count: 7, seed: content.seed, opacity: 0.9).frame(width: 130, height: 130)
                    HBStar(size: 48)
                }
                Spacer()
            }
            if let eyebrow = content.eyebrow {
                Text(eyebrow).hbText(.label, color: HBColor.accentCalm)
            }
            Text(content.title).hbText(.title).accessibilityAddTraits(.isHeader)
            Text(content.body).hbText(.body, color: HBColor.textSecondary)
            if let stat = content.stat {
                HBCard { HBStat(value: stat.value, caption: stat.caption, tone: .warm) }
            }
            if let source = content.source {
                Text(source).hbText(.footnote, color: HBColor.textSecondary)
            }
        } footer: {
            Button("Continue", action: next).buttonStyle(.hbPrimary)
        }
    }

    private struct Content {
        var eyebrow: String?
        let title: String
        let body: String
        var stat: (value: String, caption: String)?
        var source: String?
        var seed: UInt64 = 1
    }

    private func makeContent(_ a: OnboardingAnswers) -> Content {
        let child = a.displayChild
        switch insight {
        case .sleepFacts:
            return Content(
                eyebrow: "You're not alone",
                title: "Eczema keeps whole families up at night.",
                body: "The itchier the skin, the worse the sleep, for the child and for the parent.",
                stat: ("7 in 10", "children with eczema have disrupted sleep. More than half of their parents do too."),
                source: "Eczema Society of Canada caregiver survey (361 families); Tekcan et al., Pediatrics International, 2026.",
                seed: 3)
        case .notYou:
            return Content(
                eyebrow: "Good to know",
                title: "It's not you. Lotion time was never designed to feel good.",
                body: "Cold cream, a wriggly child, a long day behind you. Alji turns it into a story \(child) wants to hear, so the cream goes on while they lie still and listen.",
                seed: 5)
        case .touchAdapt:
            return touchContent(a)
        case .massageEvidence:
            return Content(
                eyebrow: "What dermatologists say",
                title: "A gentle daily massage may help reduce eczema.",
                body: "The American Academy of Dermatology says massage appears safe and suggests doing it with your child's moisturizer, but not on skin that is actively flaring. In a study, children massaged for 20 minutes with their moisturizer had less eczema than children who got moisturizer alone.",
                source: "American Academy of Dermatology, \"Massage and acupressure may help child with eczema\"; Schachner, Field et al., Pediatric Dermatology, 1998. Studies so far are small.",
                seed: 9)
        case .parentToo:
            return Content(
                eyebrow: "It helps you too",
                title: "When parents give the massage, parents feel better too.",
                body: "In a 2023 randomized trial, mothers who massaged their babies with eczema saw milder eczema and fewer flare-ups, and their own anxiety and depression scores dropped. In another trial, a nightly bedtime massage helped babies fall asleep faster, and their mothers slept longer.",
                source: "Lin et al., Frontiers in Public Health, 2023; Rezaei et al., 2023.",
                seed: 13)
        }
    }

    private func touchContent(_ a: OnboardingAnswers) -> Content {
        let child = a.displayChild
        switch a.selected("touch").first {
        case "ticklish":
            return Content(eyebrow: "Good to know", title: "Ticklish? Slower and firmer helps.",
                           body: "Light, quick strokes tickle most. Lumi's stories guide slow, steady glides, and we'll keep each scene short for \(child).", seed: 7)
        case "notFan":
            return Content(eyebrow: "Good to know", title: "We'll start small with \(child).",
                           body: "Lots of kids warm up to touch with time. \(child)'s plan starts with 5-minute rituals and just a few areas, so it never feels like too much.", seed: 7)
        case "sensitive":
            return Content(eyebrow: "Good to know", title: "Gentle comes first.",
                           body: "We'll keep the pressure feather-light, massage only calm skin, and on flaring spots just smooth the cream on. \(child)'s plan starts with 5-minute rituals.", seed: 7)
        default:
            return Content(eyebrow: "Good to know", title: "\(child) is going to love this.",
                           body: "Kids who enjoy touch usually settle quickly into a massage ritual. Lumi's long, slow glides are made for exactly that.", seed: 7)
        }
    }
}

// MARK: - Founder story

struct FounderScreen: View {
    let next: () -> Void

    var body: some View {
        OnboardingScaffold {
            HBStarCeiling(total: 12, lit: 12).padding(.vertical, HBSpacing.sm)
            Text("Why Alji exists").hbText(.label, color: HBColor.accentCalm)
            Text("“\(AppConfig.founderNote)”").hbText(.title2)
            Text("— \(AppConfig.founderName), founder").hbText(.callout, color: HBColor.textSecondary)
        } footer: {
            Button("Let's build your child's ritual", action: next).buttonStyle(.hbPrimary)
        }
    }
}

// MARK: - Relationship

struct RelationshipScreen: View {
    @Environment(AppState.self) private var appState
    @State private var advanced = false
    let next: () -> Void

    var body: some View {
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "About you",
                           title: "What's your relationship to \(appState.answers.displayChild)?",
                           subtitle: "Lumi's stories mention you by name, so it feels like your ritual.")
            VStack(spacing: HBSpacing.sm) {
                ForEach(Relationship.allCases) { relation in
                    HBOptionRow(relation.label, isSelected: appState.answers.relationship == relation) {
                        appState.answers.relationship = relation
                        advanceSoon(go)
                    }
                }
            }
        } footer: {
            Button("Continue", action: go).buttonStyle(.hbPrimary)
        }
    }

    private func go() {
        guard !advanced else { return }
        advanced = true
        next()
    }
}
