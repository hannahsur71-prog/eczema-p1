import SwiftUI
import HushbalmDesignSystem

// MARK: - Analyzing (automatic)

struct AnalyzingScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void
    @State private var progress = 0.0
    @State private var lineIndex = 0

    private var lines: [String] {
        let child = appState.answers.displayChild
        return ["Looking at \(child)'s bedtime…",
                "Checking where skin needs the most care…",
                "Comparing with what helps families like yours…"]
    }

    var body: some View {
        VStack(spacing: HBSpacing.lg) {
            Spacer()
            ZStack {
                Circle().stroke(HBColor.surfaceRaised, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(HBColor.accentCalm, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%").hbText(.title)
            }
            .frame(width: 160, height: 160)
            Text(lines[lineIndex]).hbText(.headline).multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, HBSpacing.screenGutter)
        .task {
            for step in 1...30 {
                try? await Task.sleep(for: .milliseconds(110))
                withAnimation(.linear(duration: 0.1)) { progress = Double(step) / 30 }
                lineIndex = min(lines.count - 1, step / 10)
            }
            try? await Task.sleep(for: .milliseconds(400))
            next()
        }
    }
}

// MARK: - Results

struct ResultsScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void

    var body: some View {
        let answers = appState.answers
        let score = answers.struggleScore
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "Your results",
                           title: "\(answers.displayParent), bedtime is taking more out of you than it should.")
            HBCard {
                Text("Bedtime struggle score").hbText(.label, color: HBColor.textSecondary)
                HBStat(value: "\(score)", caption: level(score), tone: score >= 50 ? .warm : .calm)
                ScoreBar(label: "Your nights now", value: Double(score) / 100, tone: .warm)
                ScoreBar(label: "Your 30-night goal", value: 0.25, tone: .calm)
                Text("Based on your answers. This is our own simple estimate, not a medical assessment.")
                    .hbText(.footnote, color: HBColor.textSecondary)
            }
            VStack(alignment: .leading, spacing: HBSpacing.sm) {
                Text("What we heard").hbText(.headline)
                ForEach(insights(answers), id: \.self) { line in
                    HStack(alignment: .top, spacing: HBSpacing.sm) {
                        Circle().fill(HBColor.accentWarm).frame(width: 8, height: 8).padding(.top, 8)
                        Text(line).hbText(.body)
                    }
                }
            }
        } footer: {
            Button("Show me what could change", action: next).buttonStyle(.hbPrimary)
        }
    }

    private func level(_ score: Int) -> String {
        switch score {
        case 67...: return "High. Nights are hard for both of you."
        case 34..<67: return "Moderate. Bedtime is wearing you down."
        default: return "Mild. A steady routine can keep it that way."
        }
    }

    private func insights(_ a: OnboardingAnswers) -> [String] {
        var lines: [String] = []
        let child = a.displayChild
        switch a.selected("lotionTime").first {
        case "tears": lines.append("Lotion time has turned into a nightly battle.")
        case "runs": lines.append("\(child) runs from the moisturizer.")
        case "wriggles": lines.append("Getting \(child) to sit still for lotion is a struggle.")
        default: break
        }
        switch a.selected("nightWaking").first {
        case "multiple", "nightly": lines.append("Itching wakes \(child) most nights, and that wakes you too.")
        case "weekly": lines.append("Itchy nights still break up your week.")
        default: break
        }
        switch a.selected("parentSleep").first {
        case "running", "broken": lines.append("You're running on broken sleep.")
        default: break
        }
        if a.selected("bedtimeFeeling").first == "guilty" {
            lines.append("You feel helpless when they itch. You're not doing anything wrong.")
        }
        if lines.isEmpty { lines.append("You want bedtime to stay calm and connected.") }
        return lines
    }
}

private struct ScoreBar: View {
    let label: String
    let value: Double
    let tone: HBBadge.Tone

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.xxs) {
            Text(label).hbText(.footnote, color: HBColor.textSecondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(HBColor.surfaceRaised)
                    Capsule()
                        .fill(tone == .warm ? HBColor.accentWarm : HBColor.accentCalm)
                        .frame(width: max(12, geo.size.width * value))
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - You're not alone (sourced facts only)

struct NotAloneScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void

    var body: some View {
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "You're not alone",
                           title: "Eczema keeps whole families up at night.")
            HBCard {
                HBStat(value: "7 in 10", caption: "children with eczema have disrupted sleep", tone: .warm)
                HBStat(value: "Over half", caption: "of their parents and caregivers lose sleep too", tone: .warm)
                Text("Source: Eczema Society of Canada caregiver survey (361 families).")
                    .hbText(.footnote, color: HBColor.textSecondary)
            }
            HBCard {
                Text("Moisturizing every day is the foundation of eczema care.").hbText(.headline)
                Text("But in studies, parents say keeping it up is one of the hardest parts, especially with a child who resists.")
                    .hbText(.body, color: HBColor.textSecondary)
            }
            Text("\(appState.answers.displayParent), the problem isn't you. It's that lotion time was never designed to feel good.")
                .hbText(.headline)
        } footer: {
            Button("So what helps?", action: next).buttonStyle(.hbPrimary)
        }
    }
}

// MARK: - How it helps (the transformation)

struct HowItHelpsScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void

    var body: some View {
        let child = appState.answers.displayChild
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "The change",
                           title: "When lotion time becomes massage time, everything gets softer.")
            VStack(alignment: .leading, spacing: 0) {
                TimelineRow(when: "Night 1", text: "\(child) lies still and listens to a story while you massage the moisturizer in. No chasing.", isLast: false)
                TimelineRow(when: "Week 1", text: "Bedtime has a rhythm. \(child) knows what comes next, and starts asking for it.", isLast: false)
                TimelineRow(when: "Night 30", text: "Lotion time is your calmest moment together, and your evenings are yours again.", isLast: true)
            }
        } footer: {
            Button("I want that for us", action: next).buttonStyle(.hbPrimary)
        }
    }
}

private struct TimelineRow: View {
    let when: String
    let text: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: HBSpacing.md) {
            VStack(spacing: 0) {
                Circle().fill(HBColor.accentWarm).frame(width: 14, height: 14).padding(.top, 4)
                if !isLast { Rectangle().fill(HBColor.border).frame(width: 2).frame(maxHeight: .infinity) }
            }
            .frame(width: 14)
            VStack(alignment: .leading, spacing: HBSpacing.xxs) {
                Text(when).hbText(.label, color: HBColor.accentWarm)
                Text(text).hbText(.body)
            }
            .padding(.bottom, isLast ? 0 : HBSpacing.lg)
        }
    }
}

// MARK: - Social proof (real reviews only, otherwise the founder's story)

struct SocialProofScreen: View {
    let next: () -> Void

    var body: some View {
        OnboardingScaffold {
            if AppConfig.testimonials.isEmpty {
                HBScreenHeader(eyebrow: "Why we built this", title: "Made by someone who gets it.")
                HBCard {
                    Text("“\(AppConfig.founderNote)”").hbText(.body)
                    Text("— \(AppConfig.founderName), founder").hbText(.callout, color: HBColor.textSecondary)
                }
                HBCard {
                    Text("Become a founding family").hbText(.headline)
                    Text("You're one of the first families on \(AppConfig.appName). Your feedback shapes every new story and technique.")
                        .hbText(.body, color: HBColor.textSecondary)
                }
            } else {
                HBScreenHeader(eyebrow: "Families like yours", title: "Calmer nights, in their words.")
                ForEach(AppConfig.testimonials) { review in
                    HBCard {
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in Image(hb: .star).hbIcon(14, color: HBColor.accentWarm) }
                        }
                        .accessibilityLabel("5 stars")
                        Text("“\(review.quote)”").hbText(.body)
                        Text(review.name).hbText(.footnote, color: HBColor.textSecondary)
                    }
                }
            }
        } footer: {
            Button("Continue", action: next).buttonStyle(.hbPrimary)
        }
    }
}

// MARK: - Features, framed as outcomes

struct FeaturesScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void

    var body: some View {
        let child = appState.answers.displayChild
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "What you get", title: "Everything you need for calmer nights with \(child).")
            FeatureRow(icon: .hands, title: "Your hands always know what to do",
                       text: "A soothing voice guides each stroke, area by area.")
            FeatureRow(icon: .tonight, title: "\(child) drifts off, screen-free",
                       text: "Calming stories and spa music play while you massage.")
            FeatureRow(icon: .shield, title: "Gentle on flares",
                       text: "Glide on dry skin, no massage on flares, skip broken skin.")
            FeatureRow(icon: .report, title: "Walk into appointments with proof",
                       text: "A 2-second nightly check-in builds a report for your doctor.")
        } footer: {
            Button("Continue", action: next).buttonStyle(.hbPrimary)
        }
    }
}

private struct FeatureRow: View {
    let icon: HBIcon
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: HBSpacing.md) {
            Image(hb: icon)
                .hbIcon(HBSize.iconMedium, color: HBColor.accentCalm)
                .frame(width: 48, height: 48)
                .background(HBColor.surface, in: RoundedRectangle(cornerRadius: HBRadius.md, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: HBSpacing.xxs) {
                Text(title).hbText(.headline)
                Text(text).hbText(.body, color: HBColor.textSecondary)
            }
        }
    }
}

// MARK: - Reminder

struct ReminderScreen: View {
    @Environment(AppState.self) private var appState
    @State private var time = Calendar.current.date(bySettingHour: 19, minute: 30, second: 0, of: .now) ?? .now
    let next: () -> Void

    var body: some View {
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "Consistency is everything",
                           title: "When does bedtime usually start?",
                           subtitle: "Routines work because they happen every night. We'll send one gentle reminder.")
            DatePicker("Bedtime", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .colorScheme(.dark)
        } footer: {
            Button("Remind me each night") {
                let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
                appState.answers.reminderHour = parts.hour ?? 19
                appState.answers.reminderMinute = parts.minute ?? 30
                appState.answers.wantsReminder = true
                let answers = appState.answers
                Task {
                    await ReminderScheduler.enable(hour: answers.reminderHour, minute: answers.reminderMinute,
                                                   childName: answers.displayChild)
                    next()
                }
            }
            .buttonStyle(.hbPrimary)
            Button("Not now", action: next).buttonStyle(.hbGhost)
        }
    }
}

// MARK: - Building the plan (automatic)

struct BuildingPlanScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void
    @State private var done = 0

    private var items: [String] {
        let a = appState.answers
        return ["Choosing gentle techniques for \(a.usualZones.count) care areas",
                "Matching calming stories for a \(a.ageGroup.label.lowercased())",
                "Setting a \(a.recommendedMinutes)-minute ritual for \(a.displayChild)",
                "Preparing your 30-night plan"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HBSpacing.lg) {
            Spacer()
            HBScreenHeader(title: "Building \(appState.answers.displayChild)'s plan…")
            VStack(alignment: .leading, spacing: HBSpacing.md) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: HBSpacing.sm) {
                        ZStack {
                            Circle().fill(index < done ? HBColor.accentCalm : HBColor.surfaceRaised)
                            if index < done { Image(hb: .check).hbIcon(12, color: HBColor.onAccent) }
                        }
                        .frame(width: 26, height: 26)
                        Text(item).hbText(.body, color: index < done ? HBColor.textPrimary : HBColor.textSecondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, HBSpacing.screenGutter)
        .task {
            for step in 1...items.count {
                try? await Task.sleep(for: .milliseconds(850))
                withAnimation(.easeOut(duration: 0.25)) { done = step }
            }
            try? await Task.sleep(for: .milliseconds(500))
            next()
        }
    }
}

// MARK: - Custom plan → paywall

struct PlanScreen: View {
    @Environment(AppState.self) private var appState
    let next: () -> Void

    var body: some View {
        let a = appState.answers
        OnboardingScaffold {
            HBScreenHeader(eyebrow: "Your plan is ready",
                           title: "\(a.displayChild)'s calm bedtime plan")
            HBCard {
                PlanLine(label: "Nightly ritual", value: "\(a.recommendedMinutes) minutes")
                PlanLine(label: "Care areas", value: a.usualZones.map(\.label).joined(separator: ", "))
                PlanLine(label: "First story", value: StoryLibrary.otter.title)
                PlanLine(label: "Techniques", value: "Glide on dry skin, gentle smoothing on flares")
            }
            HBCard {
                Text("Your 30-night goal").hbText(.label, color: HBColor.accentWarm)
                Text("Lotion time without the fight, and nights you both sleep through more often.")
                    .hbText(.headline)
            }
        } footer: {
            Button("Try night 1 now, 1 minute", action: next).buttonStyle(.hbPrimary)
        }
    }
}

private struct PlanLine: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).hbText(.footnote, color: HBColor.textSecondary)
            Text(value).hbText(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
