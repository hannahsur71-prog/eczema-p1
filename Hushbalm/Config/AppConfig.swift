import Foundation

/// Everything you need to change before submitting to the App Store lives here.
enum AppConfig {
    static let appName = "Hushbalm" // TODO: final app name

    // MARK: Subscriptions (must match App Store Connect and Products.storekit)
    // Pricing follows the category leaders: annual plan with a 7-day free trial (Storybook's
    // structure), trial on the yearly plan ONLY so the yearly is the obvious choice.
    static let yearlyProductID = "com.hushbalm.app.premium.yearly"     // $59.99 / year, 7-day free trial
    static let monthlyProductID = "com.hushbalm.app.premium.monthly"   // $9.99 / month, no trial
    /// Shown only on the "not right now?" second offer.
    static let yearlyOfferProductID = "com.hushbalm.app.premium.yearly.offer" // $34.99 / year, no trial

    /// Days before the trial ends that we send the reminder notification.
    static let trialReminderDaysBefore = 2

    /// false (recommended): visible close button → second offer → limited free version.
    /// true: unskippable paywall with no free version. Honest-paywall guidance and EU consumer
    /// rules favor a visible close; flip only if you've decided otherwise.
    static let paywallIsHard = false
    static let allProductIDs: Set<String> = [yearlyProductID, monthlyProductID, yearlyOfferProductID]

    // MARK: Legal links (required by App Store guideline 3.1.2 on the paywall)
    static let termsURL = URL(string: "https://example.com/terms")!     // TODO: your Terms of Use
    static let privacyURL = URL(string: "https://example.com/privacy")! // TODO: your Privacy Policy
    static let supportEmail = "support@example.com"                     // TODO

    // MARK: Founder story (social proof screen)
    // TODO: write this in your own words. Keep it true.
    static let founderName = "Hannah"
    static let founderNote = """
    I've had eczema my whole life. I know how tedious lotion is, and how long the nights get when the itch won't stop. \
    I built this so bedtime can be the calmest part of your family's day, not the hardest.
    """

    // MARK: Reviews
    /// Real reviews from beta families ONLY (with their permission).
    /// Never invent reviews: it breaks App Store rules and consumer-protection law.
    /// When empty, the social-proof screen shows the founder story instead.
    static let testimonials: [Testimonial] = []

    static let medicalDisclaimer = """
    Hushbalm is a bedtime routine guide, not medical care. It does not diagnose or treat eczema. \
    Follow your doctor's treatment plan and skip broken, oozing or infected skin.
    """
}

struct Testimonial: Identifiable, Hashable {
    let id = UUID()
    let quote: String
    let name: String   // e.g. "Jess, mom of a 3-year-old"
}
