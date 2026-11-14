import SwiftUI
import StoreKit
import HushbalmDesignSystem

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
                VStack(alignment: .leading, spacing: HBSpacing.lg) {
                    HBScreenHeader(title: a.paywallHeadline,
                                   subtitle: "\(a.displayChild)'s plan: a \(a.recommendedMinutes)-minute massage-and-story ritual, made for eczema skin.",
                                   isHero: true)

                    BeforeAfterCard(before: beforeText(a), after: "A calm \(a.recommendedMinutes)-minute ritual \(a.displayChild) asks for")

                    plans

                    if trialApplies, let yearly = store.yearly {
                        TrialTimeline(price: yearly.displayPrice, trialDays: yearly.trialDays ?? 7)
                    } else {
                        VStack(alignment: .leading, spacing: HBSpacing.sm) {
                            HBBenefitRow("Every ritual, story and technique")
                            HBBenefitRow("Gentle flare-night guidance")
                            HBBenefitRow("Doctor-ready report, in 2 seconds a night")
                        }
                    }
                }
                .padding(.horizontal, HBSpacing.screenGutter)
                .padding(.bottom, HBSpacing.lg)
            }
            footer
        }
        .background(HBColor.background.ignoresSafeArea())
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
                HBIconButton(.close, accessibilityLabel: "Close") { closeTapped() }
            }
        }
        .padding(.horizontal, HBSpacing.screenGutter)
        .padding(.top, HBSpacing.xs)
        .frame(minHeight: HBSize.minTouch)
    }

    @ViewBuilder private var plans: some View {
        VStack(spacing: HBSpacing.sm) {
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
                HStack(spacing: HBSpacing.sm) {
                    ProgressView().tint(HBColor.textSecondary)
                    Text(store.hasLoaded ? "Plans unavailable. Check your connection." : "Loading plans…")
                        .hbText(.footnote, color: HBColor.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: HBSpacing.xs) {
            Button {
                guard let product = selected else { return }
                Task { await buy(product) }
            } label: {
                if store.isPurchasing {
                    ProgressView().tint(HBColor.onAccent)
                } else {
                    Text(trialApplies ? "Start \(appState.answers.displayChild)'s free week" : "Start \(appState.answers.displayChild)'s calmer bedtimes")
                }
            }
            .buttonStyle(.hbPrimary)
            .disabled(selected == nil || store.isPurchasing)

            Text(underButtonLine)
                .hbText(.footnote, color: HBColor.textSecondary)
                .multilineTextAlignment(.center)

            LegalLinks()
        }
        .padding(.horizontal, HBSpacing.screenGutter)
        .padding(.top, HBSpacing.sm)
        .padding(.bottom, HBSpacing.xs)
        .background(HBColor.background)
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
        HBCard {
            Text("How your free week works").hbText(.headline)
            row(when: "Today", text: "Every ritual, story and the doctor report unlock.", tone: HBColor.accentCalm)
            row(when: reminder.formatted(.dateTime.month(.abbreviated).day()),
                text: "We'll remind you that your trial is ending. The reminder is on.", tone: HBColor.accentCalm)
            row(when: end.formatted(.dateTime.month(.abbreviated).day()),
                text: "You're charged \(price) for the year. Cancel anytime before, and you pay nothing.", tone: HBColor.accentWarm)
        }
    }

    private func row(when: String, text: String, tone: Color) -> some View {
        HStack(alignment: .top, spacing: HBSpacing.sm) {
            Circle().fill(tone).frame(width: 12, height: 12).padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(when).hbText(.label, color: tone)
                Text(text).hbText(.body)
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
                HBIconButton(.close, accessibilityLabel: "Close") { decline() }
            }
            .padding(.horizontal, HBSpacing.screenGutter)
            .padding(.top, HBSpacing.xs)
            ScrollView {
                VStack(alignment: .leading, spacing: HBSpacing.lg) {
                    HBBadge("A smaller price", tone: .warm)
                    HBScreenHeader(
                        title: "Not ready to pay full price? Start \(child)'s calm nights for less.",
                        subtitle: "Same full plan. A lower yearly price, offered once.",
                        isHero: true)
                    if let offer = store.yearlyOffer {
                        HBCard {
                            if let regular = store.yearly {
                                Text("Regular plan: \(regular.displayPrice)/year")
                                    .hbText(.callout, color: HBColor.textSecondary)
                                    .strikethrough(true, color: HBColor.textSecondary)
                            }
                            Text("\(offer.displayPrice)/year").hbText(.display, color: HBColor.accentWarm)
                            if let monthly = offer.monthlyPriceText {
                                Text("That's \(monthly) a month, billed today.").hbText(.body)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: HBSpacing.sm) {
                        HBBenefitRow("Every ritual, story and technique")
                        HBBenefitRow("The doctor-ready report")
                        HBBenefitRow("Cancel anytime in Settings")
                    }
                }
                .padding(.horizontal, HBSpacing.screenGutter)
            }
            VStack(spacing: HBSpacing.xs) {
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
                        ProgressView().tint(HBColor.onAccent)
                    } else {
                        Text("Start for \(store.yearlyOffer?.displayPrice ?? "less")/year")
                    }
                }
                .buttonStyle(.hbPrimary)
                .disabled(store.yearlyOffer == nil || store.isPurchasing)
                if let offer = store.yearlyOffer {
                    Text("\(offer.displayPrice) charged today, then every year. Auto-renews. Cancel anytime in Settings.")
                        .hbText(.footnote, color: HBColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Button(AppConfig.paywallIsHard ? "Back to plans" : "Continue with the free version") { decline() }
                    .buttonStyle(.hbGhost)
                LegalLinks()
            }
            .padding(.horizontal, HBSpacing.screenGutter)
            .padding(.vertical, HBSpacing.sm)
        }
        .background(HBColor.background.ignoresSafeArea())
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
        HStack(spacing: HBSpacing.xs) {
            column(title: "Now", text: before, tone: HBColor.accentWarm)
            column(title: "With your plan", text: after, tone: HBColor.accentCalm)
        }
    }

    private func column(title: String, text: String, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: HBSpacing.xxs) {
            Text(title).hbText(.label, color: tone)
            Text(text).hbText(.callout)
            Spacer(minLength: 0)
        }
        .padding(HBSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(HBColor.surface, in: RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous))
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
            HStack(spacing: HBSpacing.sm) {
                VStack(alignment: .leading, spacing: HBSpacing.xxs) {
                    if let badge { HBBadge(badge, tone: .warm) }
                    Text(title).hbText(.headline)
                    Text(detail).hbText(.footnote, color: HBColor.textSecondary)
                }
                Spacer(minLength: HBSpacing.xs)
                Text(priceLine).hbText(.headline)
                Circle()
                    .strokeBorder(isSelected ? HBColor.accentWarm : HBColor.border, lineWidth: isSelected ? 7 : 2)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
            }
            .padding(HBSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous)
                .fill(isSelected ? HBColor.surfaceRaised : HBColor.surface))
            .overlay(RoundedRectangle(cornerRadius: HBRadius.lg, style: .continuous)
                .strokeBorder(isSelected ? HBColor.accentWarm : HBColor.border, lineWidth: 2))
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
        HStack(spacing: HBSpacing.lg) {
            Button("Restore") { Task { await store.restore() } }
            Link("Terms", destination: AppConfig.termsURL)
            Link("Privacy", destination: AppConfig.privacyURL)
        }
        .hbText(.footnote, color: HBColor.textSecondary)
        .frame(minHeight: HBSize.minTouch)
    }
}

// MARK: - After yes

struct WelcomeAfterPurchaseView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store

    var body: some View {
        let a = appState.answers
        OnboardingScaffold {
            Spacer(minLength: HBSpacing.xl)
            Image(hb: .heart)
                .hbIcon(36, color: HBColor.accentWarm)
                .frame(width: 80, height: 80)
                .background(HBColor.surface, in: Circle())
                .accessibilityHidden(true)
            HBScreenHeader(title: "Welcome, \(a.displayParent == "You" ? "friend" : a.displayParent).",
                           subtitle: welcomeLine(a), isHero: true)
            if let end = store.trialEndDate, let yearly = store.yearly {
                let reminder = Calendar.current.date(byAdding: .day, value: -AppConfig.trialReminderDaysBefore, to: end) ?? end
                HBCard {
                    Text("Your deal").hbText(.label, color: HBColor.accentCalm)
                    Text("Free until \(end.formatted(date: .abbreviated, time: .omitted)). We'll remind you on \(reminder.formatted(date: .abbreviated, time: .omitted)). Then \(yearly.displayPrice) a year.")
                        .hbText(.body)
                    Text("Cancel anytime in Settings.").hbText(.footnote, color: HBColor.textSecondary)
                }
            } else {
                HBNotice("Manage or cancel your subscription anytime in Settings.")
            }
        } footer: {
            Button("Go to tonight") { appState.showWelcomeAfterPurchase = false }.buttonStyle(.hbPrimary)
        }
        .background(HBColor.background.ignoresSafeArea())
    }

    private func welcomeLine(_ a: OnboardingAnswers) -> String {
        if a.wantsReminder {
            let time = Calendar.current.date(bySettingHour: a.reminderHour, minute: a.reminderMinute, second: 0, of: .now) ?? .now
            return "Every ritual is open. See you at \(time.formatted(date: .omitted, time: .shortened)) for \(a.displayChild)'s first full night."
        }
        return "Every ritual is open. \(a.displayChild)'s first full night starts whenever you're ready."
    }
}
