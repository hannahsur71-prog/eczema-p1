import SwiftUI
import StoreKit
import AljiDesignSystem

/// The paywall.
/// - Headline remembers the goal they picked in the quiz ("…lotion time without the fight starts tonight").
/// - Yearly is preselected, shown per month, with a 7-day free trial; monthly has no trial.
/// - An honest timeline names the real price and the real charge date. The trial reminder is ON.
/// - Visible close (unless AppConfig.paywallIsHard). Saying no opens a second, cheaper offer,
///   then the free version. No fake timers, no invented reviews.
struct PaywallView: View {
    enum Context { case onboarding, upgrade }

    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    var context: Context = .onboarding

    @State private var selectedID = AppConfig.yearlyProductID
    @State private var showOffer = false

    private var showsClose: Bool { context == .upgrade || !AppConfig.paywallIsHard }
    private var selected: Product? { store.products[selectedID] }
    private var trialApplies: Bool {
        selectedID == AppConfig.yearlyProductID && store.yearlyTrialEligible && (store.yearly?.trialDays ?? 0) > 0
    }

    var body: some View {
        let a = appState.answers
        VStack(spacing: 0) {
            closeBar
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.lg) {
                    AJScreenHeader(title: a.paywallHeadline,
                                   subtitle: "\(a.displayChild)'s plan: a \(a.recommendedMinutes)-minute massage-and-story ritual, made for eczema skin.",
                                   isHero: true)

                    BeforeAfterCard(before: beforeText(a), after: "A calm \(a.recommendedMinutes)-minute ritual \(a.displayChild) asks for")

                    plans

                    if trialApplies, let yearly = store.yearly {
                        TrialTimeline(price: yearly.displayPrice, trialDays: yearly.trialDays ?? 7)
                    } else {
                        VStack(alignment: .leading, spacing: AJSpacing.sm) {
                            AJBenefitRow("Every ritual, story and technique")
                            AJBenefitRow("Gentle flare-night guidance")
                            AJBenefitRow("Doctor-ready report, in 2 seconds a night")
                        }
                    }
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.bottom, AJSpacing.lg)
            }
            footer
        }
        .background(StarryBackground(opacity: 0.35, seed: 11))
        .task { if !store.hasLoaded { await store.load() } }
        .fullScreenCover(isPresented: $showOffer) {
            SecondOfferView(isPresented: $showOffer, onDecline: declineEverything)
        }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    // MARK: Pieces

    @ViewBuilder private var closeBar: some View {
        HStack {
            Spacer()
            if showsClose {
                AJIconButton(.close, accessibilityLabel: "Close") { closeTapped() }
            }
        }
        .padding(.horizontal, AJSpacing.screenGutter)
        .padding(.top, AJSpacing.xs)
        .frame(minHeight: AJSize.minTouch)
    }

    @ViewBuilder private var plans: some View {
        VStack(spacing: AJSpacing.sm) {
            if let yearly = store.yearly {
                PlanCard(title: "Yearly",
                         priceLine: "\(yearly.monthlyPriceText ?? yearly.displayPrice)/mo",
                         detail: yearlyDetail(yearly),
                         badge: savingsBadge(yearly: yearly),
                         isSelected: selectedID == yearly.id) { selectedID = yearly.id }
            }
            if let monthly = store.monthly {
                PlanCard(title: "Monthly",
                         priceLine: "\(monthly.displayPrice)/mo",
                         detail: "Billed monthly. No free trial.",
                         badge: nil,
                         isSelected: selectedID == monthly.id) { selectedID = monthly.id }
            }
            if store.yearly == nil && store.monthly == nil {
                HStack(spacing: AJSpacing.sm) {
                    ProgressView().tint(AJColor.textSecondary)
                    Text(store.hasLoaded ? "Plans unavailable. Check your connection." : "Loading plans…")
                        .ajText(.footnote, color: AJColor.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: AJSpacing.xs) {
            Button {
                guard let product = selected else { return }
                Task { await buy(product) }
            } label: {
                if store.isPurchasing {
                    ProgressView().tint(AJColor.onAccent)
                } else {
                    Text(trialApplies ? "Start \(appState.answers.displayChild)'s free week" : "Start \(appState.answers.displayChild)'s calmer bedtimes")
                }
            }
            .buttonStyle(.ajPrimary)
            .disabled(selected == nil || store.isPurchasing)

            Text(underButtonLine)
                .ajText(.footnote, color: AJColor.textSecondary)
                .multilineTextAlignment(.center)

            LegalLinks()
        }
        .padding(.horizontal, AJSpacing.screenGutter)
        .padding(.top, AJSpacing.sm)
        .padding(.bottom, AJSpacing.xs)
        .background(AJColor.background)
    }

    /// The honest line under the button: price, date, auto-renew, cancel.
    private var underButtonLine: String {
        guard let product = selected else { return "Auto-renews. Cancel anytime in Settings." }
        if trialApplies, let days = product.trialDays {
            let end = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
            return "Free until \(end.formatted(.dateTime.month(.abbreviated).day())), then \(product.displayPrice)/year. Auto-renews. Cancel anytime in Settings."
        }
        return "\(product.displayPrice)/\(product.periodWord). Auto-renews. Cancel anytime in Settings at least 24 hours before renewal."
    }

    // MARK: Actions

    private func buy(_ product: Product) async {
        let hadTrial = trialApplies
        guard await store.purchase(product) else { return }
        if hadTrial, let end = store.trialEndDate {
            await ReminderScheduler.scheduleTrialReminder(trialEnds: end, price: product.displayPrice)
        }
        appState.showWelcomeAfterPurchase = true
        if context == .upgrade { dismiss() }
    }

    private func closeTapped() {
        switch context {
        case .upgrade: dismiss()
        case .onboarding:
            if store.yearlyOffer != nil { showOffer = true } else { declineEverything() }
        }
    }

    private func declineEverything() {
        if !AppConfig.paywallIsHard { appState.paywallDismissed = true }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })
    }

    private func yearlyDetail(_ yearly: Product) -> String {
        if store.yearlyTrialEligible, let days = yearly.trialDays {
            return "\(days) days free, then \(yearly.displayPrice)/year"
        }
        return "\(yearly.displayPrice) billed once a year"
    }

    private func beforeText(_ a: OnboardingAnswers) -> String {
        switch a.selected("lotionTime").first {
        case "tears": return "Tears and battles at lotion time"
        case "runs": return "Chasing \(a.displayChild) with the moisturizer"
        case "wriggles": return "Wriggling, rushed lotion time"
        default: return "Long, tiring bedtimes"
        }
    }

    private func savingsBadge(yearly: Product) -> String {
        guard let monthly = store.monthly, monthly.price > 0 else { return "BEST VALUE" }
        let saving = (1 - (yearly.price / 12) / monthly.price) * 100
        let percent = NSDecimalNumber(decimal: saving).intValue
        return percent > 0 ? "BEST VALUE · SAVE \(percent)%" : "BEST VALUE"
    }
}

// MARK: - Honest trial timeline

private struct TrialTimeline: View {
    let price: String
    let trialDays: Int

    var body: some View {
        let today = Date.now
        let end = Calendar.current.date(byAdding: .day, value: trialDays, to: today) ?? today
        let reminder = Calendar.current.date(byAdding: .day, value: -AppConfig.trialReminderDaysBefore, to: end) ?? end
        AJCard {
            Text("How your free week works").ajText(.headline)
            row(when: "Today", text: "Every ritual, story and the doctor report unlock.", tone: AJColor.accentCalm)
            row(when: reminder.formatted(.dateTime.month(.abbreviated).day()),
                text: "We'll remind you that your trial is ending. The reminder is on.", tone: AJColor.accentCalm)
            row(when: end.formatted(.dateTime.month(.abbreviated).day()),
                text: "You're charged \(price) for the year. Cancel anytime before, and you pay nothing.", tone: AJColor.accentWarm)
        }
    }

    private func row(when: String, text: String, tone: Color) -> some View {
        HStack(alignment: .top, spacing: AJSpacing.sm) {
            Circle().fill(tone).frame(width: 12, height: 12).padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(when).ajText(.label, color: tone)
                Text(text).ajText(.body)
            }
        }
    }
}

// MARK: - Second offer ("after no")

struct SecondOfferView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @Binding var isPresented: Bool
    let onDecline: () -> Void

    var body: some View {
        let child = appState.answers.displayChild
        VStack(spacing: 0) {
            HStack {
                Spacer()
                AJIconButton(.close, accessibilityLabel: "Close") { decline() }
            }
            .padding(.horizontal, AJSpacing.screenGutter)
            .padding(.top, AJSpacing.xs)
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.lg) {
                    AJBadge("A smaller price", tone: .warm)
                    AJScreenHeader(
                        title: "Not ready to pay full price? Start \(child)'s calm nights for less.",
                        subtitle: "Same full plan. A lower yearly price, offered once.",
                        isHero: true)
                    if let offer = store.yearlyOffer {
                        AJCard {
                            if let regular = store.yearly {
                                Text("Regular plan: \(regular.displayPrice)/year")
                                    .ajText(.callout, color: AJColor.textSecondary)
                                    .strikethrough(true, color: AJColor.textSecondary)
                            }
                            Text("\(offer.displayPrice)/year").ajText(.display, color: AJColor.accentWarm)
                            if let monthly = offer.monthlyPriceText {
                                Text("That's \(monthly) a month, billed today.").ajText(.body)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: AJSpacing.sm) {
                        AJBenefitRow("Every ritual, story and technique")
                        AJBenefitRow("The doctor-ready report")
                        AJBenefitRow("Cancel anytime in Settings")
                    }
                }
                .padding(.horizontal, AJSpacing.screenGutter)
            }
            VStack(spacing: AJSpacing.xs) {
                Button {
                    guard let offer = store.yearlyOffer else { return }
                    Task {
                        if await store.purchase(offer) {
                            appState.showWelcomeAfterPurchase = true
                            isPresented = false
                        }
                    }
                } label: {
                    if store.isPurchasing {
                        ProgressView().tint(AJColor.onAccent)
                    } else {
                        Text("Start for \(store.yearlyOffer?.displayPrice ?? "less")/year")
                    }
                }
                .buttonStyle(.ajPrimary)
                .disabled(store.yearlyOffer == nil || store.isPurchasing)
                if let offer = store.yearlyOffer {
                    Text("\(offer.displayPrice) charged today, then every year. Auto-renews. Cancel anytime in Settings.")
                        .ajText(.footnote, color: AJColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Button(AppConfig.paywallIsHard ? "Back to plans" : "Continue with the free version") { decline() }
                    .buttonStyle(.ajGhost)
                LegalLinks()
            }
            .padding(.horizontal, AJSpacing.screenGutter)
            .padding(.vertical, AJSpacing.sm)
        }
        .background(StarryBackground(opacity: 0.35, seed: 23))
    }

    private func decline() {
        isPresented = false
        onDecline()
    }
}

// MARK: - Shared pieces

private struct BeforeAfterCard: View {
    let before: String
    let after: String

    var body: some View {
        HStack(spacing: AJSpacing.xs) {
            column(title: "Now", text: before, tone: AJColor.accentWarm)
            column(title: "With your plan", text: after, tone: AJColor.accentCalm)
        }
    }

    private func column(title: String, text: String, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: AJSpacing.xxs) {
            Text(title).ajText(.label, color: tone)
            Text(text).ajText(.callout)
            Spacer(minLength: 0)
        }
        .padding(AJSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
    }
}

private struct PlanCard: View {
    let title: String
    let priceLine: String
    let detail: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AJSpacing.sm) {
                VStack(alignment: .leading, spacing: AJSpacing.xxs) {
                    if let badge { AJBadge(badge, tone: .warm) }
                    Text(title).ajText(.headline)
                    Text(detail).ajText(.footnote, color: AJColor.textSecondary)
                }
                Spacer(minLength: AJSpacing.xs)
                Text(priceLine).ajText(.headline)
                Circle()
                    .strokeBorder(isSelected ? AJColor.accentWarm : AJColor.border, lineWidth: isSelected ? 7 : 2)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }
            .padding(AJSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous)
                .fill(isSelected ? AJColor.surfaceRaised : AJColor.surface))
            .overlay(RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous)
                .strokeBorder(isSelected ? AJColor.accentWarm : AJColor.border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Restore, Terms and Privacy (App Store guideline 3.1.2).
struct LegalLinks: View {
    @Environment(StoreManager.self) private var store

    var body: some View {
        HStack(spacing: AJSpacing.lg) {
            Button("Restore") { Task { await store.restore() } }
            Link("Terms", destination: AppConfig.termsURL)
            Link("Privacy", destination: AppConfig.privacyURL)
        }
        .ajText(.footnote, color: AJColor.textSecondary)
        .frame(minHeight: AJSize.minTouch)
    }
}

// MARK: - After yes

struct WelcomeAfterPurchaseView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store

    var body: some View {
        let a = appState.answers
        OnboardingScaffold {
            Spacer(minLength: AJSpacing.xl)
            AJStar(size: 56)
                .frame(width: 88, height: 88)
                .background(AJColor.surface, in: Circle())
            AJScreenHeader(title: "Welcome, \(a.displayParent == "You" ? "friend" : a.displayParent).",
                           subtitle: welcomeLine(a), isHero: true)
            if let end = store.trialEndDate, let yearly = store.yearly {
                let reminder = Calendar.current.date(byAdding: .day, value: -AppConfig.trialReminderDaysBefore, to: end) ?? end
                AJCard {
                    Text("Your deal").ajText(.label, color: AJColor.accentCalm)
                    Text("Free until \(end.formatted(date: .abbreviated, time: .omitted)). We'll remind you on \(reminder.formatted(date: .abbreviated, time: .omitted)). Then \(yearly.displayPrice) a year.")
                        .ajText(.body)
                    Text("Cancel anytime in Settings.").ajText(.footnote, color: AJColor.textSecondary)
                }
            } else {
                AJNotice("Manage or cancel your subscription anytime in Settings.")
            }
        } footer: {
            Button("Go to tonight") { appState.showWelcomeAfterPurchase = false }.buttonStyle(.ajPrimary)
        }
        .background(StarryBackground())
    }

    private func welcomeLine(_ a: OnboardingAnswers) -> String {
        if a.wantsReminder {
            let time = Calendar.current.date(bySettingHour: a.reminderHour, minute: a.reminderMinute, second: 0, of: .now) ?? .now
            return "Every ritual is open. See you at \(time.formatted(date: .omitted, time: .shortened)) for \(a.displayChild)'s first full night."
        }
        return "Every ritual is open. \(a.displayChild)'s first full night starts whenever you're ready."
    }
}
