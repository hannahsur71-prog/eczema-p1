import SwiftUI
import HushbalmDesignSystem

// MARK: - Welcome

struct WelcomeScreen: View {
    let next: () -> Void

    var body: some View {
        OnboardingScaffold {
            Spacer(minLength: HBSpacing.xl)
            Image(hb: .tonight)
                .hbIcon(44, color: HBColor.accentWarm)
                .frame(width: 88, height: 88)
                .background(HBColor.surface, in: Circle())
                .accessibilityHidden(true)
            HBScreenHeader(
                title: "Bedtime can be the calmest part of your day.",
                subtitle: "A gentle massage-and-story ritual that turns lotion time into the moment your child looks forward to. No screen for them, ever.",
                isHero: true)
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                HBBenefitRow("Made for families living with eczema")
                HBBenefitRow("Your hands, guided step by step")
                HBBenefitRow("They drift off to a calming story")
            }
        } footer: {
            Button("Build my child's bedtime plan", action: next).buttonStyle(.hbPrimary)
            Text("Takes about 2 minutes").hbText(.footnote, color: HBColor.textSecondary)
        }
    }
}

// MARK: - Names

struct ParentNameScreen: View {
    @Environment(AppState.self) private var appState
    @FocusState private var focused: Bool
    let next: () -> Void

    var body: some View {
        @Bindable var state = appState
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "About you", title: "First, what should we call you?",
                           subtitle: "We'll use it to personalize your plan.")
            NameField(placeholder: "Your first name", text: $state.answers.parentName, focused: $focused)
        } footer: {
            Button("Continue", action: next).buttonStyle(.hbPrimary)
        }
        .onAppear { focused = true }
    }
}

struct ChildNameScreen: View {
    @Environment(AppState.self) private var appState
    @FocusState private var focused: Bool
    let next: () -> Void

    var body: some View {
        @Bindable var state = appState
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "About your child",
                           title: "Nice to meet you, \(appState.answers.displayParent). Who are we tucking in?",
                           subtitle: "Their first name, so the ritual feels like theirs.")
            NameField(placeholder: "Child's first name", text: $state.answers.childName, focused: $focused)
        } footer: {
            Button("Continue", action: next).buttonStyle(.hbPrimary)
        }
        .onAppear { focused = true }
    }
}

private struct NameField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        TextField(placeholder, text: $text)
            .hbText(.headline)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.continue)
            .focused(focused)
            .padding(.horizontal, HBSpacing.md)
            .frame(height: HBSize.buttonHeight)
            .background(HBColor.surface, in: RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous)
                .strokeBorder(HBColor.border, lineWidth: 1.5))
            .accessibilityLabel(placeholder)
    }
}

// MARK: - Age

struct AgeScreen: View {
    @Environment(AppState.self) private var appState
    @State private var advanced = false
    let next: () -> Void

    private func go() {
        guard !advanced else { return }
        advanced = true
        next()
    }

    var body: some View {
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "About \(appState.answers.displayChild)",
                           title: "How old is \(appState.answers.displayChild)?",
                           subtitle: "We'll choose gentle techniques and story lengths that fit.")
            VStack(spacing: HBSpacing.sm) {
                ForEach(AgeGroup.allCases) { group in
                    HBOptionRow(group.label, isSelected: appState.answers.ageGroup == group) {
                        appState.answers.ageGroup = group
                        advanceSoon(go)
                    }
                }
            }
        } footer: {
            Button("Continue", action: go).buttonStyle(.hbPrimary)
        }
    }
}

// MARK: - Quiz

struct QuizScreen: View {
    @Environment(AppState.self) private var appState
    @State private var advanced = false
    let question: QuizQuestion
    let next: () -> Void

    private func go() {
        guard !advanced else { return }
        advanced = true
        next()
    }

    var body: some View {
        let selected = appState.answers.selected(question.id)
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "Your bedtime", title: question.title(for: appState.answers),
                           subtitle: question.subtitle)
            VStack(spacing: HBSpacing.sm) {
                ForEach(question.options) { option in
                    HBOptionRow(fill(option.title), isSelected: selected.contains(option.id),
                                isMultiSelect: question.allowsMultiple) {
                        toggle(option.id)
                    }
                }
            }
        } footer: {
            Button("Continue", action: go)
                .buttonStyle(.hbPrimary)
                .disabled(selected.isEmpty)
        }
    }

    private func fill(_ text: String) -> String {
        text.replacingOccurrences(of: "{child}", with: appState.answers.displayChild)
            .replacingOccurrences(of: "{parent}", with: appState.answers.displayParent)
    }

    private func toggle(_ optionID: String) {
        var current = appState.answers.selected(question.id)
        if question.allowsMultiple {
            if let found = current.firstIndex(of: optionID) { current.remove(at: found) } else { current.append(optionID) }
            appState.answers.quiz[question.id] = current
        } else {
            appState.answers.quiz[question.id] = [optionID]
            advanceSoon(go)
        }
    }
}

// MARK: - Usual zones

struct ZonesScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void

    var body: some View {
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "Their skin",
                           title: "Where does \(appState.answers.displayChild)'s eczema usually show up?",
                           subtitle: "Select all that apply. You can change this any night.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: HBSpacing.xs), GridItem(.flexible())],
                      spacing: HBSpacing.xs) {
                ForEach(CareZone.allCases) { zone in
                    HBChip(zone.label, isSelected: appState.answers.usualZones.contains(zone)) {
                        if let found = appState.answers.usualZones.firstIndex(of: zone) {
                            appState.answers.usualZones.remove(at: found)
                        } else {
                            appState.answers.usualZones.append(zone)
                        }
                    }
                }
            }
        } footer: {
            Button("Continue", action: next)
                .buttonStyle(.hbPrimary)
                .disabled(appState.answers.usualZones.isEmpty)
        }
    }
}

/// Moves on shortly after a single-choice tap, so the selection is visible first.
func advanceSoon(_ next: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { next() }
}
