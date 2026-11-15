# Hushbalm (working name)

A screen-free bedtime ritual app for families with eczema. The parent massages moisturizer in,
guided by a calm voice and spa music, then the child drifts off to a story. Native iOS, SwiftUI,
StoreKit 2, SwiftData. No third-party SDKs.

## Run it (Mac + Xcode 15 or newer)
```bash
brew install xcodegen
xcodegen generate
open Hushbalm.xcodeproj
```
Pick an iPhone simulator and press Run. Purchases work locally through `Hushbalm/Resources/Products.storekit`
(no App Store account needed for testing). Reset test purchases in Xcode: Debug › StoreKit › Manage Transactions.

> This code was written in a Linux environment without Xcode, so it has not been compiled yet.
> Expect a few small fixes on the first build.

## How the app is laid out
```
Packages/HushbalmDesignSystem   Design system: one font (Figtree, 12 styles), colors, spacing, onboarding and paywall parts
Hushbalm/App                    App entry + root flow
Hushbalm/Onboarding             The funnel (the most important part of the app)
Hushbalm/Paywall                Paywall, second offer, welcome-after-purchase
Hushbalm/Main                   Tonight, ritual player, night log, report, library, settings
Hushbalm/Models                 Quiz, answers, care zones, stories, ritual builder, night logs
Hushbalm/Services               StoreKit, ritual engine (voice + music), reminders
Hushbalm/Config/AppConfig.swift Everything to change before launch
scripts/check-fonts.sh          Fails if any screen styles fonts outside the design system
```

## The funnel
Promise → founder story (mom's massage, glow-star ceiling) → child's name → age → your relationship
(Lumi's stories then say "Mommy", "Grandpa"…) → your name → eczema areas → then question → cited insight:
night waking → "7 in 10 kids" · lotion time → "it's not you" · touch response → adapted plan ·
AAD + 1998 study on massage · bedtime length, parent sleep, feelings → "it helps you too" (2023 trials) ·
what you've tried · goals → struggle score → transformation timeline → features → reminder →
building the plan → custom plan → **1-minute taste of Lumi's massage story** → first win → paywall.
A glowing star travels the progress bar.

Safety rule from the AAD: no massage on actively flaring skin. Flaring areas get gentle smoothing only.

Paywall rules: the headline remembers the goal they picked; yearly preselected and shown per month;
7-day free trial on yearly only; an honest timeline with the real price and charge date; trial reminder
on by default; visible close; "no" opens a cheaper second offer, then the free version
(5-minute ritual, first story, two core techniques). Set `AppConfig.paywallIsHard = true` for an
unskippable paywall instead.

Pricing: $59.99/year (7-day free trial), $9.99/month, second offer $34.99/year.

## Before you submit to the App Store
- [ ] Final name, bundle id and Team ID (`project.yml`, `AppConfig.swift`)
- [ ] App icon (1024×1024) in `Hushbalm/Resources/Assets.xcassets/AppIcon.appiconset`
- [ ] Create the 3 subscriptions in App Store Connect with the exact product IDs in `AppConfig.swift`,
      in one subscription group, with the 7-day free trial on the yearly plan
- [ ] Real Terms of Use and Privacy Policy URLs, and a support email
- [ ] Rewrite the founder note in your own words; add real beta reviews only, with permission
- [ ] Replace the device voice with recorded narration and the generated pad with licensed spa music
- [ ] Have a dermatologist or pediatric massage professional review the technique scripts
- [ ] App Store privacy labels: data is stored only on the device (no accounts, no analytics yet)
- [ ] Test the full flow in TestFlight, including buying, cancelling, restoring and the free version

## Evidence used in the app
- Eczema Society of Canada caregiver survey (361 families): sleep disturbance in 70% of children with
  eczema and 55% of caregivers.
- Schachner, Field et al., *Pediatric Dermatology* 1998: children with eczema whose parents massaged their
  cream in for 20 minutes nightly for a month improved more than controls; parents' anxiety dropped.
- Rezaei et al., 2023 randomized trial (140 infants): a 15-minute bedtime massage improved sleep onset,
  night wakings and longest sleep stretch; mothers slept longer.
