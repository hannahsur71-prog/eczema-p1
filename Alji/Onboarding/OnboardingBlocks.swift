import SwiftUI
import AljiDesignSystem

/// The scrolling content of one onboarding screen, in the prototype's order:
/// art, title, body, then the block for that kind of screen, then the source line.
struct OnboardingContent: View {
    let screen: OBScreen
    @Binding var draft: OnboardingDraft
    let index: Int
    let tasteIndex: Int
    let tasteLeft: Int
    let tasteSeconds: Int
    let onAnswer: () -> Void
    let onContinue: () -> Void

    @Environment(StoreManager.self) private var store

    private var usesDisplayTitle: Bool {
        [OBKind.hero, .paywall, .win, .welcome].contains(screen.kind)
    }
    private var isChoice: Bool {
        [OBKind.single, .multi, .question].contains(screen.kind)
    }
    private var bodyText: String { screen.body.isEmpty ? screen.note : screen.body }

    var body: some View {
        VStack(alignment: screen.isCentered ? .center : .leading, spacing: AJSpacing.screenGutter) {
            if screen.showsArt {
                HeroArt(colorIndex: index).frame(maxWidth: .infinity)
            }
            if screen.kind == .loading {
                LoadingRing().frame(maxWidth: .infinity).padding(.top, 30)
            }
            AJHighlightedTitle(screen.title, style: usesDisplayTitle ? .display : .title)
            if !bodyText.isEmpty {
                Text(bodyText).ajText(.body)
            }
            block
            if !screen.statValue.isEmpty {
                AJStat(value: screen.statValue, caption: screen.statCaption)
            }
            if screen.showsCeiling {
                ConstellationCard(lit: screen.kind == .featureStars ? 14 : max(1, draft.lit), child: draft.childName)
            }
            if !screen.source.isEmpty {
                AJSourceNote(screen.source)
            }
        }
        .multilineTextAlignment(screen.isCentered ? .center : .leading)
        .frame(maxWidth: .infinity, alignment: screen.isCentered ? .center : .leading)
        .padding(.top, isChoice && screen.options.count <= 5 ? 60 : 0)
    }

    @ViewBuilder
    private var block: some View {
        switch screen.kind {
        case .input: inputBlock
        case .single, .multi, .question: optionsBlock
        case .featureDemo: demoBlock
        case .featureScreenFree: screenFreeBlock
        case .environment: environmentBlock
        case .cost: costBlock
        case .chart: chartBlock
        case .beforeAfter: beforeAfterBlock
        case .month: monthBlock
        case .plan: planBlock
        case .taste: if tasteIndex >= 0 { tasteBlock }
        case .commit: commitBlock
        case .rate: rateBlock
        case .signin: signInBlock
        case .building: BuildingBlock(lines: OnboardingScript.buildingLines(draft), lockTitle: OnboardingScript.lockTitle(draft))
        case .paywall: paywallBlock
        default: EmptyView()
        }
    }

    // MARK: Answers

    private var inputBlock: some View {
        AJTextField(screen.placeholder, text: screen.key == "child" ? $draft.child : $draft.parent)
    }

    private func isSelected(_ id: String) -> Bool {
        switch screen.kind {
        case .multi: return (draft.multi[screen.key] ?? []).contains(id)
        case .question: return draft.q[screen.key] == id
        default: return draft.picks[screen.key] == id
        }
    }

    private func pick(_ id: String) {
        switch screen.kind {
        case .multi:
            var chosen = draft.multi[screen.key] ?? []
            if let at = chosen.firstIndex(of: id) { chosen.remove(at: at) } else { chosen.append(id) }
            draft.multi[screen.key] = chosen
        case .question:
            draft.q[screen.key] = id
            onAnswer()
        default:
            draft.picks[screen.key] = id
        }
    }

    private var chosenAnswer: String? {
        screen.kind == .question ? draft.q[screen.key] : draft.picks[screen.key]
    }

    private var otherText: Binding<String> {
        Binding(
            get: { draft.other[screen.key] ?? "" },
            set: { text in
                draft.other[screen.key] = text
                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    draft.q[screen.key] = "other"
                } else if draft.q[screen.key] == "other" {
                    draft.q[screen.key] = nil
                }
            })
    }

    private var optionsBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            if screen.isGrid {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(screen.options) { option in
                        AJOptionRow(option.label, isSelected: isSelected(option.id), isMultiSelect: true, isCompact: true) { pick(option.id) }
                    }
                }
            } else {
                ForEach(screen.options) { option in
                    AJOptionRow(option.label, isSelected: isSelected(option.id), isMultiSelect: screen.kind == .multi) { pick(option.id) }
                }
            }
            if screen.hasOther {
                AJTextField("Something else? Tell us", text: otherText)
            }
            if let answer = chosenAnswer, let reply = screen.feedback[answer] {
                AJFeedbackNote(reply)
            }
        }
        .animation(.easeOut(duration: 0.3), value: chosenAnswer)
    }

    // MARK: Feature screens

    private var demoBlock: some View {
        VStack(spacing: 10) {
            MassageFigure(motion: .armGlide)
                .frame(maxWidth: 270)
                .frame(maxWidth: .infinity)
                .background(figurePanel)
            Text("Lumi's story tells you which stroke to do. The hands show you how.")
                .ajText(.subhead, color: AJColor.textSecondary)
        }
    }

    private var figurePanel: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(RadialGradient(colors: [Color(hex: 0x3A3470), Color(hex: 0x262252)], center: .center, startRadius: 0, endRadius: 220))
    }

    private var screenFreeBlock: some View {
        VStack(spacing: 0) {
            ArtView(shapes: ArtData.screenFree, size: ArtData.screenFreeSize)
                .accessibilityLabel("A child lies in bed with eyes closed while a parent's hands rest on their back. The phone lies face down on the nightstand, playing the story.")
            FlowLayout(spacing: 8) {
                ForEach(["Phone face down", "Eyes closed", "Just your hands"], id: \.self) { text in
                    Chip(text: text, color: AJColor.accentWarm)
                }
            }
            .padding(.horizontal, AJSpacing.sm)
            .padding(.bottom, 14)
        }
        .background(LinearGradient(colors: [Color(hex: 0x1A1840), Color(hex: 0x2B2760)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: Results

    private var environmentBlock: some View {
        VStack(spacing: 10) {
            ForEach(OnboardingScript.environment(draft)) { item in
                HStack(alignment: .top, spacing: AJSpacing.sm) {
                    Image(aj: item.ok ? .check : .plus)
                        .ajIcon(14, color: AJColor.background)
                        .frame(width: 26, height: 26)
                        .background(item.ok ? AJColor.accentCalm : AJColor.accentWarm, in: Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).ajText(.callout)
                        Text(item.text).ajText(.subhead, color: AJColor.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, AJSpacing.sm)
                .background(item.ok ? AJColor.surface : AJColor.accentWarm.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                    .strokeBorder(item.ok ? AJColor.borderQuiet : AJColor.accentWarm, lineWidth: 1.5))
                .accessibilityElement(children: .combine)
            }
        }
        .multilineTextAlignment(.leading)
    }

    private var costBlock: some View {
        let numbers = OnboardingScript.cost(draft)
        let top = Double(max(numbers.struggleHours, numbers.lostSleepHours, 1))
        let rows: [(value: String, label: String, share: Double)] = [
            ("\(numbers.struggleHours) hrs", "of bedtime struggle (\(numbers.nightlyStruggle) extra min a night)", Double(numbers.struggleHours) / top),
            ("\(numbers.wakesPerYear.formatted()) times", "\(draft.childName) wakes up scratching (\(numbers.wakeLabel))",
             min(1, max(Double(numbers.lostSleepHours) / top, 0.25))),
            ("\(numbers.lostSleepHours) hrs", "of your own sleep lost to those wake-ups", Double(numbers.lostSleepHours) / top)
        ]
        return VStack(alignment: .leading, spacing: AJSpacing.sm) {
            VStack(alignment: .leading, spacing: AJSpacing.sm) {
                Text("Every year, right now").ajText(.label, color: AJColor.textSecondary)
                ForEach(rows, id: \.label) { row in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: AJSpacing.xs) {
                            Text(row.label).ajText(.subhead)
                            Spacer(minLength: 0)
                            Text(row.value).ajText(.title2, color: AJColor.coralText).fixedSize()
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.12))
                                Capsule().fill(AJColor.coral).frame(width: geo.size.width * max(0.06, row.share))
                            }
                        }
                        .frame(height: 10)
                    }
                }
            }
            .padding(AJSpacing.md)
            .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous).strokeBorder(AJColor.borderQuiet, lineWidth: 1.5))

            HStack(spacing: 14) {
                Image(aj: .moon).ajIcon(44, color: AJColor.accentWarm).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alji's goal for you").ajText(.label, color: Color(hex: 0xBDE9F7))
                    Text("Calmer bedtimes and fewer wake-ups: up to \(numbers.gainHours) hours back this year, for both of you.")
                        .ajText(.bodyStrong)
                }
                Spacer(minLength: 0)
            }
            .padding(AJSpacing.md)
            .background(AJColor.hopeGradient, in: RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous))

            Text("From your answers: \(numbers.nightlyStruggle) extra minutes at bedtime, waking \(numbers.wakeLabel), about 20 minutes awake each time. An estimate, not a guarantee.")
                .ajText(.footnote, color: AJColor.textTertiary)
        }
        .multilineTextAlignment(.leading)
    }

    private var chartBlock: some View {
        let times = OnboardingScript.fallAsleep(draft)
        let saved = max(0, times.now - times.goal)
        return VStack(spacing: AJSpacing.screenGutter) {
            AJComparisonBars(eyebrow: "Time to fall asleep", nowValue: "\(times.now) min",
                             goalLabel: "Goal with a nightly ritual", goalValue: "\(times.goal) min",
                             goalFraction: Double(times.goal) / Double(times.now))
            AJResultCard(value: saved > 0 ? "−\(saved) min" : "Calmer",
                         caption: saved > 0 ? "a night. That's about \(Int((Double(saved) * 365 / 60).rounded())) hours a year back for you both."
                                            : "\(draft.childName) already settles quickly. The ritual makes that time closer, and the cream easier.")
        }
    }

    private var beforeAfterBlock: some View {
        VStack(spacing: AJSpacing.sm) {
            sceneCard(shapes: ArtData.before, label: "Tonight", labelColor: AJColor.coral, line: OnboardingScript.beforeLine(draft),
                      chips: OnboardingScript.beforeChips(draft), chipColor: AJColor.coralText,
                      fill: Color(hex: 0x3B2E52), border: AJColor.coral.opacity(0.6))
            Image(aj: .arrowDown).ajIcon(22, color: AJColor.accentWarm).accessibilityHidden(true)
            sceneCard(shapes: ArtData.after, label: "A month in, with Alji", labelColor: AJColor.accentCalm, line: OnboardingScript.afterLine(draft),
                      chips: OnboardingScript.afterChips(draft), chipColor: Color(hex: 0xBDE9F7),
                      fill: AJColor.surfaceDeep, border: AJColor.accentCalm)
        }
        .multilineTextAlignment(.leading)
    }

    private func sceneCard(shapes: [ArtShape], label: String, labelColor: Color, line: String, chips: [String],
                           chipColor: Color, fill: Color, border: Color) -> some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) {
            HStack(spacing: AJSpacing.sm) {
                ArtView(shapes: shapes, size: ArtData.sceneSize).frame(width: 120, height: 84)
                VStack(alignment: .leading, spacing: AJSpacing.xxs) {
                    Text(label).ajText(.label, color: labelColor)
                    Text(line).ajText(.callout)
                }
            }
            FlowLayout(spacing: 6) {
                ForEach(chips, id: \.self) { chip in Chip(text: chip, color: chipColor) }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill, in: RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous).strokeBorder(border, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }

    private var monthBlock: some View {
        let steps = OnboardingScript.monthSteps(draft)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { offset, step in
                HStack(alignment: .top, spacing: AJSpacing.sm) {
                    VStack(spacing: 0) {
                        AJStar(size: 26).opacity(0.5 + Double(offset) * 0.125)
                        Rectangle()
                            .fill(offset < steps.count - 1 ? AJColor.accentWarm.opacity(0.35) : Color.clear)
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: 34)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.when).ajText(.label, color: AJColor.accentWarm)
                        Text(step.title).ajText(.callout)
                        Text(step.text).ajText(.subhead, color: AJColor.textSecondary)
                    }
                    .padding(.bottom, AJSpacing.md)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .multilineTextAlignment(.leading)
    }

    private var planBlock: some View {
        let steps = OnboardingScript.plan(draft)
        return VStack(alignment: .leading, spacing: AJSpacing.sm) {
            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { offset, step in
                    AJTimelineRow(time: step.time, title: step.title, detail: step.detail,
                                  icon: AJIcon(rawValue: step.icon) ?? .sparkles,
                                  tint: Color(hex: step.tint), isLast: offset == steps.count - 1)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Bedroom tweaks this week").ajText(.callout)
                HStack(alignment: .top, spacing: AJSpacing.xs) {
                    ForEach(OnboardingScript.bedroomTweaks(draft), id: \.label) { tweak in
                        VStack(spacing: AJSpacing.xxs) {
                            Image(aj: AJIcon(rawValue: tweak.icon) ?? .leaf)
                                .ajIcon(20, color: tweak.ok ? Color(hex: 0xBDE9F7) : AJColor.accentWarm)
                            Text((tweak.ok ? "✓ " : "") + tweak.label)
                                .ajText(.footnote, color: tweak.ok ? Color(hex: 0xBDE9F7) : AJColor.accentWarm)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, AJSpacing.xxs)
                        .background((tweak.ok ? AJColor.accentCalm : AJColor.accentWarm).opacity(0.15),
                                    in: RoundedRectangle(cornerRadius: AJRadius.sm, style: .continuous))
                    }
                }
            }
            .padding(14)
            .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))

            HStack(spacing: AJSpacing.sm) {
                Image(aj: .moon).ajIcon(34, color: AJColor.accentWarm).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("A new moon every month").ajText(.callout)
                    Text("Each calm night adds a star to \(draft.childName)'s sky. Fill the moon, then start the next one.")
                        .ajText(.footnote, color: AJColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(AJColor.surfaceDeep, in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
        }
        .multilineTextAlignment(.leading)
    }

    // MARK: 1-minute ritual

    private var tasteBlock: some View {
        let steps = OnboardingScript.tasteSteps(draft)
        let step = steps[min(max(0, tasteIndex), steps.count - 1)]
        return VStack(alignment: .leading, spacing: 10) {
            MassageFigure(motion: step.motion)
                .frame(maxWidth: 270)
                .frame(maxWidth: .infinity)
                .background(figurePanel)
                .accessibilityLabel("Massage guide: \(step.title). \(step.hands)")
            HStack(spacing: AJSpacing.xxs) {
                ForEach(steps.indices, id: \.self) { i in
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2))
                            Capsule().fill(AJColor.accentCalm).frame(width: geo.size.width * stepFraction(i))
                        }
                    }
                    .frame(height: 6)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: AJSpacing.xs) {
                    Text(step.title).ajText(.title2)
                    Spacer(minLength: 0)
                    Text(step.reps)
                        .ajText(.footnoteStrong, color: AJColor.onAccent)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(AJColor.accentWarm, in: Capsule())
                    Text("\(tasteLeft)s")
                        .ajText(.footnoteStrong)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.white.opacity(0.18), in: Capsule())
                }
                Text(step.hands).ajText(.callout)
                Text("“\(step.story)”").ajText(.subhead, color: AJColor.textSecondary).italic()
            }
            .padding(.horizontal, AJSpacing.md)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
        }
        .multilineTextAlignment(.leading)
    }

    private func stepFraction(_ i: Int) -> Double {
        if i < tasteIndex { return 1 }
        if i > tasteIndex { return 0 }
        return 1 - Double(tasteLeft) / Double(max(1, tasteSeconds))
    }

    // MARK: Commitment, rating, sign-in

    private var commitBlock: some View {
        VStack(spacing: 14) {
            Button {
                withAnimation(.easeOut(duration: 0.5)) {
                    draft.promised = true
                    draft.lit = max(1, draft.lit)
                }
            } label: {
                AJStar(size: 120, isLit: draft.promised)
                    .frame(width: 170, height: 170)
                    .background(draft.promised ? AJColor.accentWarm.opacity(0.16) : Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tap the star to make the promise")
            .accessibilityAddTraits(draft.promised ? .isSelected : [])
            Text(draft.promised ? "Promise made. Night 2 is tomorrow." : "Tap the star")
                .ajText(.bodyStrong, color: AJColor.accentWarm)
            VStack(spacing: AJSpacing.xs) {
                ForEach(OnboardingScript.promiseLines, id: \.self) { line in
                    HStack(spacing: 10) {
                        Image(aj: .check).ajIcon(16, color: AJColor.accentCalm).accessibilityHidden(true)
                        Text(line).ajText(.subhead)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
                }
            }
            .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity)
    }

    private var rateBlock: some View {
        VStack(spacing: 14) {
            HStack(spacing: AJSpacing.xs) {
                ForEach(1...5, id: \.self) { value in
                    Button { draft.rating = value } label: {
                        AJStar(size: 44, isLit: value <= draft.rating).frame(width: 52, height: 52)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(value) stars")
                }
            }
            Text("Every rating helps another eczema family find a calmer bedtime.")
                .ajText(.subhead, color: AJColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var signInBlock: some View {
        VStack(spacing: 10) {
            Button(action: onContinue) {
                HStack(spacing: AJSpacing.xs) {
                    Image(aj: .apple).ajIcon(18, color: .black)
                    Text("Continue with Apple").ajText(.callout, color: .black)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.white, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            Button("Continue with email", action: onContinue).buttonStyle(.ajSecondary)
            Text("So \(draft.childName)'s plan, stars and progress are saved if you switch phones.")
                .ajText(.footnote, color: AJColor.textTertiary)
        }
    }

    // MARK: Paywall

    private var paywallBlock: some View {
        let trialDays = store.yearly?.trialDays ?? 3
        let yearly = "\(store.yearly?.displayPrice ?? "$59.99") a year · \(store.yearly?.monthlyPriceText ?? "$5") a month"
        let monthly = "\(store.monthly?.displayPrice ?? "$9.99") a month"
        let steps: [AJTrialStep] = draft.isYearly
            ? [AJTrialStep(title: "Full access", when: "Today", icon: .sparkles, tint: AJColor.accentWarm),
               AJTrialStep(title: "We remind you", when: OnboardingScript.dateString(daysFromNow: trialDays - 1), icon: .bell, tint: Color(hex: 0x9ADCF2)),
               AJTrialStep(title: "Billing starts", when: OnboardingScript.dateString(daysFromNow: trialDays), icon: .check, tint: AJColor.accentCalm)]
            : [AJTrialStep(title: "Full access", when: "Today", icon: .sparkles, tint: AJColor.accentWarm),
               AJTrialStep(title: "Cancel anytime", when: "Monthly", icon: .check, tint: AJColor.accentCalm)]
        return VStack(spacing: AJSpacing.screenGutter) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(OnboardingScript.paywallBenefits, id: \.self) { AJBenefitRow($0) }
            }
            .padding(.horizontal, 6)
            VStack(spacing: 10) {
                AJPlanCard(title: "Yearly", price: yearly, badge: "\(trialDays) days free", isSelected: draft.isYearly) {
                    draft.picks["plan"] = "yearly"
                }
                AJPlanCard(title: "Monthly", price: monthly, isSelected: !draft.isYearly) {
                    draft.picks["plan"] = "monthly"
                }
            }
            AJTrialSteps(steps)
        }
        .multilineTextAlignment(.leading)
    }
}

// MARK: - Small parts

/// A rounded tag, used for chips under a scene.
private struct Chip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .ajText(.footnoteStrong, color: color)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(color.opacity(0.16), in: Capsule())
    }
}

/// The spinning ring on the "personalizing" screen.
private struct LoadingRing: View {
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.15), lineWidth: 8)
            Circle().trim(from: 0, to: 0.25)
                .stroke(AJColor.accentCalm, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
        }
        .frame(width: 120, height: 120)
        .onAppear {
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) { isSpinning = true }
        }
        .accessibilityLabel("Loading")
    }
}

/// "Writing Maya's story": lines appear one by one, then the locked story card.
private struct BuildingBlock: View {
    let lines: [String]
    let lockTitle: String
    @State private var shown = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(lines.enumerated()), id: \.offset) { offset, line in
                HStack(spacing: AJSpacing.sm) {
                    Image(aj: .check)
                        .ajIcon(13, color: AJColor.background)
                        .frame(width: 24, height: 24)
                        .background(AJColor.accentCalm, in: Circle())
                        .accessibilityHidden(true)
                    Text(line).ajText(.subhead)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, AJSpacing.sm)
                .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
                .opacity(shown > offset ? 1 : 0)
                .offset(y: shown > offset ? 0 : 6)
            }
            HStack(spacing: 14) {
                Image(aj: .lock)
                    .ajIcon(24, color: .white)
                    .frame(width: 54, height: 54)
                    .background(LinearGradient(colors: [Color(hex: 0x7E63B8), Color(hex: 0x4F7FB8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lockTitle).ajText(.callout)
                    Text("Personalized for tonight. Unlock to play it at bedtime.").ajText(.footnote, color: AJColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(AJColor.accentWarm.opacity(0.1), in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous).strokeBorder(AJColor.accentWarm, lineWidth: 1.5))
            .opacity(shown > lines.count ? 1 : 0)
            .padding(.top, 6)
        }
        .multilineTextAlignment(.leading)
        .task {
            for step in 1...(lines.count + 1) {
                try? await Task.sleep(for: .milliseconds(step == 1 ? 300 : 700))
                withAnimation(.easeOut(duration: 0.5)) { shown = step }
            }
        }
    }
}

/// Thirty stars that fill in to form a crescent moon.
struct ConstellationCard: View {
    let lit: Int
    let child: String

    var body: some View {
        VStack(spacing: AJSpacing.xs) {
            Canvas { context, size in
                let points = OnboardingScript.constellation
                let scale = min(size.width / 240, size.height / 190)
                var ctx = context
                ctx.translateBy(x: (size.width - 240 * scale) / 2, y: (size.height - 190 * scale) / 2)
                ctx.scaleBy(x: scale, y: scale)
                if lit > 1 {
                    var lines = Path()
                    lines.move(to: points[0])
                    for point in points.prefix(lit).dropFirst() { lines.addLine(to: point) }
                    ctx.stroke(lines, with: .color(Color(hex: 0xE4F5A8, opacity: 0.85)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                }
                for (offset, point) in points.enumerated() {
                    let isLit = offset < lit
                    let isNext = offset == lit
                    let radius: CGFloat = isLit ? 4.5 : (isNext ? 4 : 2.6)
                    let color = isLit ? Color(hex: 0xE4F5A8) : (isNext ? AJColor.accentWarm : Color.white.opacity(0.28))
                    ctx.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
                }
            }
            .frame(width: 240, height: 190)
            .accessibilityLabel("\(lit) of 30 stars lit. The stars form a crescent moon when complete.")
            Text(lit <= 1 ? "Your first star" : "\(lit) stars this month").ajText(.callout)
            Text("Each calm night adds a star. Every month completes a new moon for \(child)'s sky.")
                .ajText(.footnote, color: AJColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0x16245C), in: RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous).strokeBorder(AJColor.borderQuiet, lineWidth: 1.5))
    }
}

/// Wraps its children onto new lines, like text.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
