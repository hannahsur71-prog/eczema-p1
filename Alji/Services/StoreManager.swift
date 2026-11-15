import Foundation
import Observation
import StoreKit

/// StoreKit 2 subscriptions. No third-party SDK needed.
/// To use RevenueCat later, replace the internals of this class; the views only use its public API.
@MainActor
@Observable
final class StoreManager {
    private(set) var products: [String: Product] = [:]
    private(set) var isSubscribed = false
    private(set) var isPurchasing = false
    private(set) var hasLoaded = false
    /// When the current free trial ends (nil if not in a trial).
    private(set) var trialEndDate: Date?
    /// Whether this Apple ID can still get the yearly plan's free trial.
    private(set) var yearlyTrialEligible = false
    var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refreshEntitlements()
            }
        }
    }

    var yearly: Product? { products[AppConfig.yearlyProductID] }
    var monthly: Product? { products[AppConfig.monthlyProductID] }
    var yearlyOffer: Product? { products[AppConfig.yearlyOfferProductID] }

    func load() async {
        do {
            let list = try await Product.products(for: AppConfig.allProductIDs)
            products = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        } catch {
            errorMessage = "Couldn't load plans. Check your connection and try again."
        }
        if let yearly, yearly.subscription?.introductoryOffer != nil {
            yearlyTrialEligible = await yearly.subscription?.isEligibleForIntroOffer ?? false
        }
        await refreshEntitlements()
        hasLoaded = true
    }

    func refreshEntitlements() async {
        var active = false
        var trialEnd: Date?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if AppConfig.allProductIDs.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
                if transaction.offerType == .introductory {
                    trialEnd = transaction.expirationDate
                }
            }
        }
        isSubscribed = active
        trialEndDate = trialEnd
    }

    /// Returns true when the purchase completed and the subscription is active.
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    errorMessage = "We couldn't verify that purchase. Please contact support."
                    return false
                }
                await transaction.finish()
                await refreshEntitlements()
                return isSubscribed
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = "Restore failed. Please try again."
        }
        await refreshEntitlements()
        if !isSubscribed && errorMessage == nil {
            errorMessage = "No active subscription found for this Apple ID."
        }
    }
}

extension Product {
    /// "$5.00" — yearly price shown per month, the paywall's anchor.
    var monthlyPriceText: String? {
        guard let period = subscription?.subscriptionPeriod else { return nil }
        let months: Decimal
        switch period.unit {
        case .year: months = 12 * Decimal(period.value)
        case .month: months = Decimal(period.value)
        default: return nil
        }
        return (price / months).formatted(priceFormatStyle)
    }

    /// Free-trial length in days, if this product has one.
    var trialDays: Int? {
        guard let offer = subscription?.introductoryOffer, offer.paymentMode == .freeTrial else { return nil }
        let unitDays: Int
        switch offer.period.unit {
        case .day: unitDays = 1
        case .week: unitDays = 7
        case .month: unitDays = 30
        case .year: unitDays = 365
        @unknown default: return nil
        }
        return unitDays * offer.period.value
    }

    /// "$0.96" — price per week for yearly plans, used as a paywall anchor.
    var weeklyPriceText: String? {
        guard let period = subscription?.subscriptionPeriod else { return nil }
        let weeks: Decimal
        switch period.unit {
        case .year: weeks = 52 * Decimal(period.value)
        case .month: weeks = Decimal(period.value) * 52 / 12
        case .week: weeks = Decimal(period.value)
        case .day: weeks = Decimal(period.value) / 7
        @unknown default: return nil
        }
        guard weeks > 0 else { return nil }
        return (price / weeks).formatted(priceFormatStyle)
    }

    /// "year" / "month"
    var periodWord: String {
        switch subscription?.subscriptionPeriod.unit {
        case .year?: return "year"
        case .month?: return "month"
        case .week?: return "week"
        case .day?: return "day"
        default: return "period"
        }
    }
}
