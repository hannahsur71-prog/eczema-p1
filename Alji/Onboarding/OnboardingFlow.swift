import SwiftUI
import StoreKit
import AVFoundation
import AljiDesignSystem

/// The onboarding, paywall and welcome flow. A screen-for-screen build of the approved prototype.
struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @Environment(\.requestReview) private var requestReview

    @State private var draft = OnboardingDraft()
    @State private var index = 0
    /// -1 until the 1-minute ritual starts, then the current step.
    @State private var tasteIndex = -1
    @State private var tasteLeft = 0
    @State private var tasteRun = 0
    @State private var voice = OnboardingVoice()

    /// Seconds per step of the 1-minute ritual.
    private let tasteSeconds = 20

    var body: some View {
        let list = OnboardingScript.screens(draft)
        let screen = list[min(index, list.count - 1)]
        VStack(spacing: 0) {
            header(screen, count: list.count)
            ScrollView {
                OnboardingContent(screen: screen, draft: $draft, index: index, tasteIndex: tasteIndex,
                                  tasteLeft: tasteLeft, tasteSeconds: tasteSeconds,
                                  onAnswer: { answered(screen) }, onContinue: { primary(screen, in: list) })
                    .padding(.horizontal, AJSpacing.screenGutter)
                    .padding(.top, AJSpacing.lg)
                    .padding(.bottom, AJSpacing.sm)
                    .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            footer(screen, in: list)
        }
        .background(OnboardingSky())
        .animation(.easeInOut(duration: 0.25), value: index)
        .task(id: index) {
            guard screen.autoAdvances else { return }
            try? await Task.sleep(for: .seconds(2.8))
            if !Task.isCancelled { go(to: index + 1, in: list) }
        }
        .task(id: tasteRun) {
            guard tasteIndex >= 0 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                if tasteLeft > 1 {
                    tasteLeft -= 1
                } else {
                    advanceTaste(in: list)
                    return
                }
            }
        }
        .onDisappear { voice.stop() }
    }

    // MARK: Frame

    @ViewBuilder
    private func header(_ screen: OBScreen, count: Int) -> some View {
        if screen.showsBar {
            HStack(spacing: 14) {
                AJIconButton(.back, accessibilityLabel: "Back") { back() }
                AJProgressBar(progress: Double(index) / Double(max(1, count - 1)))
            }
            .padding(.horizontal, AJSpacing.screenGutter)
            .padding(.top, AJSpacing.xs)
        } else if screen.showsClose {
            HStack {
                Spacer()
                AJIconButton(.close, accessibilityLabel: "Close") { go(to: .offer) }
            }
            .padding(.horizontal, 18)
            .padding(.top, AJSpacing.xs)
        }
    }

    @ViewBuilder
    private func footer(_ screen: OBScreen, in list: [OBScreen]) -> some View {
        VStack(spacing: AJSpacing.xs) {
            if let label = primaryLabel(screen) {
                Button(label) { primary(screen, in: list) }
                    .buttonStyle(.ajPrimary)
                    .disabled(isPrimaryDisabled(screen) || store.isPurchasing)
            }
            if screen.kind == .paywall {
                finePrint
            }
            if let error = store.errorMessage, screen.kind == .paywall || screen.kind == .offer {
                Text(error).ajText(.footnote, color: AJColor.coralText).multilineTextAlignment(.center)
            }
            if let secondary = screen.secondary, !(screen.kind == .taste && tasteIndex >= 0) {
                Button(secondary) { secondaryAction(screen, in: list) }.buttonStyle(.ajGhost)
            }
            if screen.showsLegal {
                HStack(spacing: 28) {
                    Button("Restore") { Task { await store.restore(); if store.isSubscribed { go(to: .welcome) } } }
                    Link("Terms & Conditions", destination: AppConfig.termsURL)
                    Link("Privacy Policy", destination: AppConfig.privacyURL)
                }
                .ajText(.footnote, color: AJColor.textSecondary)
                .underline()
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AJSpacing.screenGutter)
        .padding(.top, 10)
        .padding(.bottom, AJSpacing.md)
        .background(AJColor.background)
    }

    private var finePrint: some View {
        let yearlyPrice = store.yearly?.displayPrice ?? "$59.99"
        let monthlyPrice = store.monthly?.displayPrice ?? "$9.99"
        let perMonth = store.yearly?.monthlyPriceText ?? "$5"
        let trialDays = store.yearly?.trialDays ?? 3
        let lead = draft.isYearly ? "\(trialDays) days free, then " : "Billed monthly · "
        let price = draft.isYearly ? "\(yearlyPrice)/yr · only \(perMonth)/month" : "\(monthlyPrice)/month, cancel anytime"
        return (Text(lead) + Text(price).foregroundStyle(AJColor.accentCalm))
            .ajText(.subhead)
            .multilineTextAlignment(.center)
    }

    // MARK: Buttons

    private func primaryLabel(_ screen: OBScreen) -> String? {
        switch screen.kind {
        case .taste where tasteIndex >= 0: return "Next step"
        case .paywall:
            let trialDays = store.yearly?.trialDays ?? 3
            return draft.isYearly ? "Start my \(trialDays)-day free trial" : "Continue for \(store.monthly?.displayPrice ?? "$9.99")/month"
        case .offer:
            return "Start for \(store.yearlyOffer?.displayPrice ?? "$34.99")/year"
        default: return screen.cta
        }
    }

    private func isPrimaryDisabled(_ screen: OBScreen) -> Bool {
        switch screen.kind {
        case .question: return draft.q[screen.key] == nil
        case .multi: return (draft.multi[screen.key] ?? []).isEmpty
        case .input: return (screen.key == "child" ? draft.child : draft.parent).trimmingCharacters(in: .whitespaces).isEmpty
        case .commit: return !draft.promised
        default: return false
        }
    }

    private func primary(_ screen: OBScreen, in list: [OBScreen]) {
        if isPrimaryDisabled(screen) { return }
        switch screen.kind {
        case .taste:
            if tasteIndex < 0 { startTaste(step: 0) } else { advanceTaste(in: list) }
        case .single where screen.key == "reminder":
            Task {
                let parts = reminderTime
                appState.answers.wantsReminder = await ReminderScheduler.enable(hour: parts.hour, minute: parts.minute, childName: draft.childName)
                go(to: index + 1, in: list)
            }
        case .rate:
            requestReview()
            go(to: index + 1, in: list)
        case .paywall:
            buy(draft.isYearly ? store.yearly : store.monthly)
        case .offer:
            buy(store.yearlyOffer)
        case .welcome:
            finish()
        default:
            go(to: index + 1, in: list)
        }
    }

    private func secondaryAction(_ screen: OBScreen, in list: [OBScreen]) {
        switch screen.kind {
        case .offer: finish()
        default: go(to: index + 1, in: list)
        }
    }

    /// Quiz answers without a tailored reply move on by themselves, like the prototype.
    private func answered(_ screen: OBScreen) {
        guard screen.kind == .question, screen.feedback.isEmpty, !screen.hasOther || draft.q[screen.key] != "other" else { return }
        let current = index
        Task {
            try? await Task.sleep(for: .milliseconds(380))
            if index == current { index = current + 1 }
        }
    }

    // MARK: Navigation

    private func go(to target: Int, in list: [OBScreen]) {
        voice.stop()
        tasteIndex = -1
        index = max(0, min(list.count - 1, target))
    }

    private func go(to kind: OBKind) {
        let list = OnboardingScript.screens(draft)
        if let target = list.firstIndex(where: { $0.kind == kind }) { go(to: target, in: list) }
    }

    private func back() {
        let list = OnboardingScript.screens(draft)
        var target = index - 1
        while target > 0 && list[target].autoAdvances { target -= 1 }
        go(to: target, in: list)
    }

    // MARK: 1-minute ritual

    private func startTaste(step: Int) {
        tasteIndex = step
        tasteLeft = tasteSeconds
        tasteRun += 1
        voice.speak(OnboardingScript.tasteSteps(draft)[step].story)
    }

    private func advanceTaste(in list: [OBScreen]) {
        let next = tasteIndex + 1
        if next >= OnboardingScript.tasteSteps(draft).count {
            draft.lit = 1
            appState.answers.completedTaste = true
            go(to: index + 1, in: list)
        } else {
            startTaste(step: next)
        }
    }

    // MARK: Purchase and finish

    private func buy(_ product: Product?) {
        guard let product else {
            store.errorMessage = "Subscriptions aren't available right now. Please try again in a moment."
            return
        }
        store.errorMessage = nil
        Task {
            if await store.purchase(product) { go(to: .welcome) }
        }
    }

    private var reminderTime: (hour: Int, minute: Int) {
        // The reminder fires 30 minutes before the chosen sleep time.
        switch draft.picks["reminder"] {
        case "1900": return (18, 30)
        case "2000": return (19, 30)
        case "2030": return (20, 0)
        default: return (19, 0)
        }
    }

    /// Saves the answers and leaves onboarding.
    private func finish() {
        voice.stop()
        var answers = appState.answers
        answers.childName = draft.child.trimmingCharacters(in: .whitespaces)
        answers.parentName = draft.parentName
        answers.ageGroup = AgeGroup(rawValue: draft.picks["age"] ?? "") ?? .toddler
        answers.relationship = Relationship(rawValue: draft.picks["relationship"] ?? "") ?? .mom
        answers.usualZones = draft.zones.compactMap { CareZone(rawValue: $0) }
        var quiz: [String: [String]] = draft.q.mapValues { [$0] }
        quiz["goals"] = draft.goals
        quiz["severity"] = [draft.picks["severity"] ?? "moderate"]
        for (key, text) in draft.other where !text.trimmingCharacters(in: .whitespaces).isEmpty {
            quiz["\(key)Other"] = [text]
        }
        answers.quiz = quiz
        let parts = reminderTime
        answers.reminderHour = parts.hour
        answers.reminderMinute = parts.minute
        appState.answers = answers
        if !store.isSubscribed { appState.paywallDismissed = true }
        appState.hasCompletedOnboarding = true
    }
}

/// Reads the ritual story aloud in a slow, soft voice.
final class OnboardingVoice {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.82
        utterance.volume = 0.9
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
