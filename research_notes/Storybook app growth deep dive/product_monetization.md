# Storybook (Familify Corp): Product, Onboarding, Paywall, Pricing and Retention Teardown

Method note (written Nov 2026): every WebFetch failed because the hosts are not on this session's network allowlist. The blocked hosts were screensdesign.com, apps.apple.com, alts.co, kingscrowd.com and stacksocial.com, so I stopped trying others. Every finding below comes from search-engine snippets of the cited pages, not from full page reads. Verify the important numbers on the live pages before publishing. Labels used: "company claim" means self-reported by Familify or its listings and marketing; "independent" means third-party data or user reports. Many sources are undated, and where that is so I have marked the year as approximate.

## 1. Onboarding (quiz, screen order, account, permissions)

### Takeaway
The ScreensDesign UI breakdown describes a 30-step personalization quiz. It frames the quiz as a "consultation" that builds investment before any price is shown, and a soft paywall with a 7-day free trial comes after it. Confirmed quiz inputs are the child's name, age, ADHD or neurodivergence, love language, and whether the child sleeps in their own room. I could not recover the full screen-by-screen order.

### Cited Findings
- ScreensDesign lists 30 onboarding steps and a soft paywall that shows a free trial. The subscription offer appears only after the long personalization quiz. The breakdown calls the quiz a personalized consultation that builds investment before payment is requested (independent teardown, undated, likely 2024–2025). [ScreensDesign](https://screensdesign.com/showcase/storybook-sleep-meditation)
- The quiz asks for the child's name and age, plus specific needs such as ADHD and the child's love language. [ScreensDesign](https://screensdesign.com/showcase/storybook-sleep-meditation)
- The reviewer flags the quiz length as a possible source of friction. [ScreensDesign](https://screensdesign.com/showcase/storybook-sleep-meditation)
- The app asks for an App Store review after a positive moment, such as the user rating a story highly. [ScreensDesign](https://screensdesign.com/showcase/storybook-sleep-meditation)
- ScreensDesign estimates the target users as parents of children aged roughly 2–10. Its revenue estimate for Storybook is only about $1.0K/mo, and the Calm comparison page lists Storybook at under $5k. Both look implausibly low next to the company-reported figures in section 6, so treat them as unreliable. [ScreensDesign](https://screensdesign.com/showcase/storybook-sleep-meditation); [ScreensDesign Calm page](https://screensdesign.com/apps/calm/)
- The App Store listing says parents can indicate whether the child sleeps in their own room or is neurodivergent, so content can be tailored (company claim). [App Store](https://apps.apple.com/us/app/storybook-sleep-meditation/id1355190474)
- The product combines audio stories, guided massages, meditations and positive affirmations into a personalized daily routine. [ScreensDesign via search](https://screensdesign.com/showcase/storybook-sleep-meditation)
- For comparison within the same category on ScreensDesign: Meditopia has 27 steps with the paywall at the end of onboarding, a 7-day trial converting to annual, and warm-up screens before permission prompts. Pura Mente has 12 steps and a timeline-style paywall. Calm uses mandatory account creation. [Meditopia](https://screensdesign.com/showcase/meditopia-sleep-meditation); [Pura Mente](https://screensdesign.com/showcase/pura-mente-sleep-meditation); [Calm](https://screensdesign.com/apps/calm/)

### Inferences
- A 30-step quiz followed by a "your personalized plan" soft paywall is the standard quiz-funnel pattern used by Noom-style apps. It plays on sunk cost and the sense of a personalized result. The ADHD, love-language and own-room questions double as segmentation data for content and ads.
- Asking for a review right after a high story rating is a deliberate tactic for lifting store ratings. Its effect may be offset by the 3.9★ Play rating (section 7).

### Gaps
- The full ordered list of the 30 screens, the exact question wording, and the remaining questions (sleep problems, bedtime, wake-ups) could not be retrieved because screensdesign.com was blocked.
- I could not confirm when account creation happens (before or after the paywall, or whether it is mandatory), the timing of the notification-permission prompt, or whether a pre-permission "warm-up" screen is used.

## 2. Paywall (type, trial, plans, anchoring, exit offers, web checkout)

### Takeaway
The paywall is soft (dismissible) and appears after the quiz. It centers on a 7-day free trial converting to annual billing, with a day-5 reminder promised. Plans seen across listings are yearly (several price points), monthly at $14.99, and discounted first-year offers. Discounted web and reseller funnels exist on get.storybook-app.com and storybook-app.com/en/specialoffer.

### Cited Findings
- The paywall is soft and offers a free trial after the quiz (independent). [ScreensDesign](https://screensdesign.com/showcase/storybook-sleep-meditation)
- The 7-day trial is confirmed in a separate snippet: after the quiz, a soft paywall offers a 7-day free trial. [ScreensDesign via search](https://screensdesign.com/showcase/storybook-sleep-meditation)
- The web "special offer" page promises unlimited free access for 7 days, a reminder on day 5 that the trial is ending, and cancellation any time before day 7 (company claim). [Storybook special offer](https://www.storybook-app.com/en/specialoffer)
- Terms state that unless users cancel at least 24 hours before the trial ends, they are charged the full amount of the selected plan. Yearly plans auto-renew each year. No refunds are given after payment, except for faulty apps within the first 30 days. [User Agreement](https://www.storybook-app.com/user-agreement)
- In-app purchase listings show "Storybook Premium Yearly" at $59.99, a $89.99 yearly SKU, discounted 1-year plans at $47.99 and $49.99, and a monthly plan at $14.99 (App Store US, snippet; listing date uncertain). [App Store](https://apps.apple.com/us/app/storybook-sleep-meditation/id1355190474); [App Store alt listing](https://apps.apple.com/us/app/storybook-calm-bedtime-sleep/id1355190474)
- Web and reseller landing pages exist at get.storybook-app.com/en/ and /en/reseller/home/FAMILIFY/. [get.storybook-app.com](https://get.storybook-app.com/en/); [reseller page](https://get.storybook-app.com/en/reseller/home/FAMILIFY/)
- Coupon aggregators list "65% OFF" codes for Storybook (Oct 2025). These are low-reliability aggregator claims and may refer to a different "Storybook". [Tenereteam](https://storybook-app.tenereteam.com/coupons)

### Inferences
- A $14.99/mo plan shown beside a yearly plan in the $47.99–$89.99 range works as a price anchor: the annual plan works out to roughly $4–7.50/mo, about a 50–70% "saving". The several yearly SKUs ($47.99, $49.99, $59.99, $89.99) look like A/B test cells, intro offers or win-back and exit discounts.
- The separate /specialoffer web page and reseller funnel suggest web-to-app checkout, used to avoid store fees and to run paid-social quiz funnels.

### Gaps
- I could not confirm whether an exit or "abandon paywall" discount appears in the app, what it is, or when it triggers.
- I could not confirm the web-checkout price points or the payment processor; get.storybook-app.com could not be fetched.
- I could not confirm whether the paywall shows a trial timeline graphic, social proof or plan toggles.

## 3. Pricing history and experiments

### Takeaway
Listed US annual pricing moved upward over time. User reports trace $46 → $56 → about $90/yr. The official US price was $59.99/yr in store copy, and an $89.99/yr SKU exists. The company said that A/B testing showed it could raise the yearly price to $89.99, with increases of 50–85% that did not significantly hurt conversion. Regional pricing varies widely. I found no lifetime plan.

### Cited Findings
- During the Republic crowdfunding raise (about 2022), the founders said: "After A/B testing different price points we have found an opportunity to increase the yearly price to 89.99 USD." They also said prices rose 50–85% "without a significant affection to the conversion rates" in most countries. This is a company claim, relayed by alts.co. [alts.co](https://alts.co/should-you-invest-in-storybook-a-sleep-app-for-parents/)
- One user review (justuseapp, undated) says the price went from $46 to $56 to "now $90" per year. A separate review describes a $56 yearly charge after a trial. Both are independent but anecdotal. [justuseapp contact/reviews](https://justuseapp.com/en/app/1355190474/storybook-sleep-massage-app/contact); [justuseapp reviews](https://justuseapp.com/en/app/1355190474/storybook-sleep-meditation/reviews)
- An older article (about 2023) says Storybook was free to download with a $49.99 yearly plan. [bedtime-stories.fun / search snippet](https://www.bedtime-stories.fun/blog/best-bedtime-story-apps)
- App Store and Google Play copy states: "Subscription is priced at $59.99/year for United States customers." [App Store](https://apps.apple.com/us/app/storybook-sleep-meditation/id1355190474); [Google Play](https://play.google.com/store/apps/details?id=app.storybook.story&hl=en_US)
- Regional yearly prices are $39.99 in Tunisia, SAR 179.99 in Saudi Arabia (about $48) and RM199.90 in Malaysia (about $45). [App Store TN](https://apps.apple.com/tn/app/storybook-calm-bedtime-sleep/id1355190474); [App Store SA](https://apps.apple.com/sa/app/storybook-sleep-meditation/id1355190474); [App Store MY](https://apps.apple.com/my/app/storybook-sleep-meditation/id1355190474)
- StackSocial (and its Futurism shop syndication) sold one year of Storybook Premium for $29 or $29.99, marketed as an "$89.99 value". There was also a Spanish-language version of the deal. The deal is undated and possibly expired. [StackSocial](https://www.stacksocial.com/sales/1-year-of-storybook-premium-baby-sleep-app-for-better-bedtime-for-only-29); [StackSocial ES](https://www.stacksocial.com/sales/aplicacion-storybook-baby-sleep-suscripcion-premium-de-1-ano-por-solo-29); [Futurism shop](https://shop.futurism.com/sales/1-year-of-storybook-premium-baby-sleep-app-for-better-bedtime-for-only-29)
- No lifetime plan was found in any listing or search result. [search across App Store / alts.co results](https://apps.apple.com/us/app/storybook-calm-bedtime-sleep/id1355190474)

### Inferences
- The likely sequence is about $46–49.99 (2019–2021), then $56–59.99, then an $89.99 test or rollout (about 2022 onward). The $59.99 store-copy figure may be a stale legal disclosure while the $89.99 SKU is live, or the reverse. The StackSocial "$89.99 value" framing suggests $89.99 was the list price at the time of that deal.
- StackSocial deals at about a 67% discount act as a low-cost acquisition and liquidation channel, and they also make $89.99 look like the "real" price.

### Gaps
- I found no dated price timeline, and could not confirm the current (Nov 2026) US price; the store pages could not be fetched.
- The design of the company's A/B test (cells, sample sizes, the conversion figures behind the claim) was not disclosed.

## 4. Content (library, types, cadence, languages, personalization)

### Takeaway
The store listings claim more than 400 tracks and more than 100 massage techniques for ages 0–12, with new content weekly. A newer reseller page claims more than 500 stories and more than 200 relaxation techniques. Content comes in five languages. The product pitch rests on personalized daily routines built from stories, massage, meditation and affirmations.

### Cited Findings
- The App Store and Google Play listings claim "over 400 content tracks" and "more than 100 massage techniques" for children 0–12, with new weekly content (company claim). [App Store](https://apps.apple.com/us/app/storybook-sleep-meditation/id1355190474); [Google Play](https://play.google.com/store/apps/details?id=app.storybook.story&hl=en_US)
- The reseller page claims more than 500 original audio stories and more than 200 relaxation techniques, with a new batch each week. This is likely a newer company claim that conflicts with the store copy. [get.storybook-app.com reseller](https://get.storybook-app.com/en/reseller/home/FAMILIFY/)
- Languages listed are English, Arabic, Japanese, Portuguese and Spanish. [App Store](https://apps.apple.com/us/app/storybook-calm-bedtime-sleep/id1355190474); [get.storybook-app.com](https://get.storybook-app.com/en/)
- Content types are audio stories, guided parent-child massages, meditations and positive affirmations, combined into a personalized daily routine. [ScreensDesign](https://screensdesign.com/showcase/storybook-sleep-meditation)
- Users can build personalized routines by choosing stories, sounds or massage techniques in the Routine settings. [appexploring](https://www.appexploring.com/app/storybook-calm-bedtime-sleep/)
- A 2026 roundup calls the massage guidance genuinely differentiating but less relevant for older children. Third parties disagree on the core age range, giving 0–4 or 1–7. [bedtime-stories.fun 2026](https://www.bedtime-stories.fun/blog/best-bedtime-story-apps)
- Some users say the stories and meditations are "subpar and way too short" (independent, Google Play). [Google Play](https://play.google.com/store/apps/details?id=app.storybook.story&hl=en_US)
- Latest versions seen: 5.2.37 dated Dec 17, 2025, on an APK mirror; 5.3.29 on an App Store listing (undated). [APKPure](https://m.apkpure.com/storybook-calm-bedtime-sleep/app.storybook.story); [App Store TN](https://apps.apple.com/tn/app/storybook-calm-bedtime-sleep/id1355190474)

### Inferences
- The massage content (infant and toddler touch techniques) is the main point of difference from Calm Kids, Moshi and similar apps. Its value fades as children age, which is a natural churn driver as children pass about age 6.

### Gaps
- I found no narrator names or celebrity voices, and could not confirm whether every track is narrated in all five languages.
- I could not retrieve the "What's New" release history, so I have no feature-level timeline (AI stories, programs, etc.).
- The name change from "Sleep & Massage" to "Sleep & Meditation" to "Calm Bedtime, Sleep" is visible in listing URLs and titles, but I found no dates for it.

## 5. Retention and engagement

### Takeaway
Retention rests on a personalized daily routine, a weekly content drop, and the parent-child bedtime ritual. I found no evidence of streaks, and Family Sharing support is unconfirmed. Churn is driven by trial conversions users did not expect and by children outgrowing the content. No retention metrics are public.

### Cited Findings
- The app positions itself around a personalized daily routine (stories, massage, meditation, affirmations). [ScreensDesign](https://screensdesign.com/showcase/storybook-sleep-meditation)
- The app has a Routine settings menu for customizing nightly content. [appexploring](https://www.appexploring.com/app/storybook-calm-bedtime-sleep/)
- The weekly content cadence is claimed in both store listings and on the reseller page. [App Store](https://apps.apple.com/us/app/storybook-sleep-meditation/id1355190474); [reseller](https://get.storybook-app.com/en/reseller/home/FAMILIFY/)
- A day-5 trial-ending reminder is promised on the web offer. [special offer](https://www.storybook-app.com/en/specialoffer)
- Self-reported outcome figures: 80% of children sleep better and 89% of users report a better connection with their children (Crunchbase, company claim). Marketing pages also cite "92%" and "96%" satisfaction figures from internal data. [Crunchbase](https://www.crunchbase.com/organization/storybook); [storybook-app.com](https://www.storybook-app.com/en)
- None of the results mention streaks for Storybook; streaks were found only for the competitor Little Story Box. Family Sharing was not mentioned in any result. [search snippets: Little Story Box](https://apps.apple.com/us/app/id6754278437); [Google Play](https://play.google.com/store/apps/details?id=app.storybook.story&hl=en_US)

### Inferences
- Annual-first billing is itself the main retention mechanism: the effective churn decision happens once a year at renewal, which also means renewal complaints cluster at that point.

### Gaps
- I found no churn, D1/D7/D30 retention, renewal rate or session-frequency data.
- I could not confirm the nightly reminder or notification cadence, or whether there is a parent account or multi-child profiles.

## 6. Monetization metrics (disclosed)

### Takeaway
The only hard metrics come from crowdfunding disclosures and investor posts, and they are company-reported and mostly dated 2020–2023. Reported figures are $393K revenue (2020) and $581K (FY20 per Kingscrowd; inconsistent with the $393K), 71% gross margin, more than 9,000 paid subscribers (about 2022), and later more than $1M ARR with a 3:1 LTV:CAC. No conversion rate, ARPU or trial-to-paid rate is disclosed.

### Cited Findings
- From the Republic campaign (about 2022), per alts.co: more than 9,000 paid subscribers, more than 3,000 five-star reviews, $393K revenue in 2020, and 1.5M downloads (company claim). [alts.co](https://alts.co/should-you-invest-in-storybook-a-sleep-app-for-parents/)
- Kingscrowd lists the 2022 Republic raise at a $12M valuation cap, with $581K revenue for FY20 and a 71% gross margin. The FY20 figure conflicts with alts.co's $393K for 2020, possibly because of gross vs. net-of-store-fees revenue or calendar vs. fiscal year. [Kingscrowd](https://kingscrowd.com/storybook-app-on-republic-2022/)
- A Substack post (Ganas, undated, about 2023–2024) says the company "surpassed $1M ARR last year" with a 3:1 LTV:CAC ratio. This is relayed and unverified. [lolitataub substack](https://lolitataub.substack.com/p/special-edition-ganas-and-i-invested)
- KLI Capital cites 59% quarterly sales growth (undated). [KLI Capital](https://www.klicapital.vc/post/why-we-invested-in-storybook-a-commitment-to-family-wellness)
- Another investor write-up claims more than 3.5M downloads and "tens of thousands of active paying subscribers" across 155 countries. Familify's site claims more than 4M downloads (company claims, undated). [search snippet: CB Insights/KLI](https://www.cbinsights.com/company/storybook); [Familify](https://familify.com/)
- Independent estimates vary widely. Tracxn puts annual revenue at $1M–$10M as of Dec 31, 2023, and ZoomInfo at under $5M. One app-analytics page shows about $30K/month, and ScreensDesign shows about $1K/month. [Tracxn](https://tracxn.com/d/companies/storybook/__cJk88HpZWEMGwtEPByRUH5qTcFsjfZJ_eeS7IA5-q9c); [ZoomInfo](https://www.zoominfo.com/c/storybook-app/558040127); [parsers.vc](https://parsers.vc/startup/storybook-app.com/)
- Company: Familify Corp, Miami FL, founded 2018. Familify's newer product, Theo App, reportedly grew revenue 5x in 2025. [CB Insights](https://www.cbinsights.com/company/storybook); [Familify](https://familify.com/)

### Inferences
- Implied ARPU: $393K ÷ 9K subscribers is about $44 per subscriber per year, which fits the roughly $46–49.99 annual price in 2020–2021. At $1M ARR and roughly $50–60 net per subscriber, that implies about 17–20K paying subscribers (about 2023). These are rough calculations, not disclosed figures.
- Paying subscribers ÷ downloads is roughly 9K/1.5M, about 0.6% of lifetime installs paying at a point in time. That is low, but typical of the category.

### Gaps
- No install-to-trial, trial-to-paid, paywall conversion, ARPU, LTV in dollars, CAC in dollars, or renewal rate has been disclosed. The Republic offering page and Form C were not reachable.

## 7. Billing and support complaints (product risks)

### Takeaway
The complaints are consistent: charges after the trial that users did not expect, cancellation flows that failed, and continued billing after deleting the app. These are made worse by strict terms (cancel at least 24h before the trial ends; no refunds). The pattern weighs on ratings (3.9★ on Google Play against a claimed 4.8 on the company site) and carries regulatory and chargeback risk.

### Cited Findings
- A Google Play reviewer says the in-app cancel option showed "technical error" for 7 days, and the annual plan then charged them anyway. [Google Play](https://play.google.com/store/apps/details?id=app.storybook.story&hl=en_US)
- The developer replied that cancellation must happen in the Play Store, and offered quick refunds by email (info@familify.com). Some users say support was "super supportive" with refunds. [Google Play](https://play.google.com/store/apps/details?id=app.storybook.story&hl=en_AU)
- Users report being charged "wayyy before the free trial ended" and the yearly plan being activated during the trial. [justuseapp reviews](https://justuseapp.com/en/app/1355190474/storybook-sleep-massage-app/reviews)
- A 2022 reviewer says deleting the app or "unsubscribing" in the app did not stop Apple billing. [justuseapp](https://justuseapp.com/en/app/1355190474/storybook-sleep-massage-app/reviews)
- A justuseapp user calls the app "definitely a scam", citing the $46 → $56 → $90 price creep and a limited free tier. Others say they were charged for a full year after cancelling during the trial. [justuseapp contact](https://justuseapp.com/en/app/1355190474/storybook-sleep-massage-app/contact)
- Google Play shows 1M+ downloads and about 3.9★ from about 3.7K reviews. The company site claims a 4.8 rating and "#1 parenting app" in 90–150+ countries (company claim). [Google Play](https://play.google.com/store/apps/details?id=app.storybook.story&hl=en_US); [storybook-app.com](https://www.storybook-app.com/)
- The terms say users are charged unless they cancel at least 24h before the trial ends, with no refunds after payment except for faulty apps within 30 days. [User Agreement](https://www.storybook-app.com/user-agreement)

### Inferences
- Annual-only trial conversion at a high price ($59.99–$89.99), combined with web checkout (cancellation outside the store), creates FTC "click-to-cancel" and negative-option exposure, plus chargeback and refund costs. The 50–85% price increase probably made this complaint pattern worse.

### Gaps
- I found no complaint volumes, BBB or Trustpilot data, refund-rate data or regulatory actions specific to Storybook.
