import SwiftUI
import AljiDesignSystem

/// Progress: time back for the parent first, then the month, itch, totals and what research shows.
struct ProgressTabView: View {
    @Environment(AppState.self) private var appState

    private var child: String { appState.child }

    var body: some View {
        let stats = ProgressStats(nights: appState.nights)
        VStack(alignment: .leading, spacing: 14) {
            AJHighlightedTitle("\(child)'s progress")
            timeBack(stats)
            moonCalendar(stats)
            itchTrend(stats)
            rings(stats)
            milestones(stats)
            statTiles(stats)
            research
        }
    }

    // MARK: Time back for you

    private func timeBack(_ stats: ProgressStats) -> some View {
        let weeks = stats.fallWeeks
        let top = weeks.compactMap(\.fallMinutes).max() ?? 1
        return VStack(alignment: .leading, spacing: 10) {
            Text("Time back for you").ajText(.label)
            if let saved = stats.minutesBackThisMonth, weeks.count >= 2 {
                HStack(alignment: .firstTextBaseline, spacing: AJSpacing.xs) {
                    Text(ProgressStats.hours(saved)).ajText(.display)
                    Text("back this month").ajText(.subhead)
                }
                if let faster = stats.minutesFasterThisWeek, faster > 0 {
                    Text("Bedtime takes \(faster) fewer minutes a night than in week \(weeks[0].number). That's \(ProgressStats.hours(faster * 7)) back this week alone.")
                        .ajText(.subhead)
                } else {
                    Text("Bedtime is taking about as long as in week \(weeks[0].number). Hard weeks happen; steady nights are what count.")
                        .ajText(.subhead)
                }
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                        let minutes = week.fallMinutes ?? 0
                        VStack(spacing: AJSpacing.xxs) {
                            Text("\(Int(minutes.rounded())) min").ajText(.footnoteStrong)
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(index == weeks.count - 1 ? AJColor.accentWarm : Color.white.opacity(0.45))
                                .frame(height: max(4, CGFloat(minutes / top) * 44))
                            Text("Week \(week.number)").ajText(.footnote)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 92, alignment: .bottom)
                .accessibilityElement()
                .accessibilityLabel("Minutes to fall asleep by week: " + weeks.map { "\(Int(($0.fallMinutes ?? 0).rounded()))" }.joined(separator: ", "))
                Text("Minutes for \(child) to fall asleep, from your nightly check-ins.").ajText(.footnote)
            } else {
                Text("Your time back shows up here").ajText(.title2)
                Text("Answer the morning check-in for two weeks and you'll see how many minutes of bedtime you've won back.")
                    .ajText(.subhead)
            }
        }
        .padding(AJSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: 0xB9637A), Color(hex: 0x7E63B8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: This month's moon

    private func moonColor(_ entry: NightEntry?) -> Color {
        guard let entry else { return Color.white.opacity(0.08) }
        if entry.wasFlare { return AJColor.coral }
        switch entry.itch {
        case "Calm": return AJColor.accentWarm
        case "A bit itchy": return Color(hex: 0xC9B98A)
        case "Very itchy": return Color(hex: 0x8C86B8)
        default: return Color(hex: 0xC9B98A)
        }
    }

    private func moonCalendar(_ stats: ProgressStats) -> some View {
        panel {
            HStack(alignment: .firstTextBaseline) {
                Text("This month's moon").ajText(.callout).bold()
                Spacer()
                Text("brighter moon = calmer night").ajText(.footnote, color: AJColor.textSecondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AJSpacing.xs), count: 7), spacing: AJSpacing.xs) {
                ForEach(stats.monthDays) { day in
                    VStack(spacing: 2) {
                        AJMoon(size: 34, color: moonColor(day.entry))
                        Text("\(day.id)").ajText(.footnote, color: AJColor.textTertiary)
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Day \(day.id): " + (day.entry.map { $0.wasFlare ? "flare night" : ($0.itch ?? "ritual done") } ?? "no ritual"))
                }
            }
            HStack(spacing: 14) {
                legend("Calm", AJColor.accentWarm)
                legend("Itchy", Color(hex: 0x8C86B8))
                legend("Flare", AJColor.coral)
                legend("No log", Color.white.opacity(0.15))
            }
        }
    }

    private func legend(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).ajText(.footnote, color: AJColor.textSecondary)
        }
    }

    // MARK: Itch trend

    private func itchTrend(_ stats: ProgressStats) -> some View {
        let weeks = stats.itchWeeks
        return VStack(alignment: .leading, spacing: 6) {
            Text("Night itch · last 4 weeks").ajText(.label)
            if let change = stats.itchChangePercent, weeks.count >= 2 {
                HStack(alignment: .firstTextBaseline, spacing: AJSpacing.xs) {
                    Text(change == 0 ? "Steady" : "\(change > 0 ? "+" : "−")\(abs(change))%").ajText(.stat)
                    Text("since week \(weeks[0].number)").ajText(.subhead)
                }
                TrendLine(values: weeks.compactMap(\.itch), labels: weeks.map { "Week \($0.number)" })
                    .frame(height: 110)
                Text("1 is calm, 3 is very itchy. From your night check-ins.").ajText(.footnote)
            } else {
                Text("Your itch trend shows up here").ajText(.title2)
                Text("After two weeks of night check-ins you'll see whether nights are getting calmer.").ajText(.subhead)
            }
        }
        .padding(AJSpacing.md + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(hex: 0x4F7FB8), Color(hex: 0x7E63B8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // MARK: Rings, milestones, tiles

    private func rings(_ stats: ProgressStats) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ring(stats.nightsLast28, goal: 28, label: "nights moisturized", color: AJColor.accentCalm)
            ring(stats.minutesLast28, goal: 420, label: "minutes of calm touch", color: AJColor.accentWarm)
            ring(stats.checkInsLast28, goal: 28, label: "check-ins logged", color: Color(hex: 0xF2A0B8))
        }
    }

    private func ring(_ value: Int, goal: Int, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.18), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: min(1, CGFloat(value) / CGFloat(goal)))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(value)").ajText(.title2)
            }
            .frame(width: 72, height: 72)
            Text(label).ajText(.footnote, color: AJColor.textSecondary).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, AJSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("\(value) of \(goal) \(label), last 4 weeks")
    }

    private func milestones(_ stats: ProgressStats) -> some View {
        let goals = [(1, "First night"), (7, "7 nights"), (14, "14 nights"), (30, "30 nights"), (60, "60 nights"), (100, "100 nights")]
        let count = stats.nights.count
        return panel {
            Text("Milestones").ajText(.callout).bold()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(goals, id: \.0) { goal in
                        let earned = count >= goal.0
                        VStack(spacing: AJSpacing.xxs) {
                            AJStar(size: 30, isLit: earned)
                            Text(goal.1).ajText(.footnoteStrong)
                            Text(earned ? "Earned" : "Coming up").ajText(.footnote, color: AJColor.textSecondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, AJSpacing.sm)
                        .frame(width: 96)
                        .background(earned ? AJColor.accentWarm.opacity(0.14) : Color.white.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous)
                                .strokeBorder(earned ? AJColor.accentWarm.opacity(0.55) : Color.white.opacity(0.25),
                                              style: StrokeStyle(lineWidth: 1.5, dash: earned ? [] : [5, 4]))
                        )
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private func statTiles(_ stats: ProgressStats) -> some View {
        let dash = "–"
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
            tile(stats.averageWakes.map { String(format: "%.1f", $0) } ?? dash, "average wake-ups a night", 0x3B5F8C, .moon)
            tile("\(stats.nights.count)", "massage rituals completed", 0xB9637A, .sparkles)
            tile("\(stats.flareNightsThisMonth)", "flare nights this month", 0x3F8F8A, .drop)
            tile(stats.averageRating.map { String(format: "%.1f", $0) } ?? dash, "\(child)'s average story rating", 0xC9A24A, .star)
        }
    }

    private func tile(_ value: String, _ label: String, _ hex: UInt32, _ icon: AJIcon) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(aj: icon)
                .ajIcon(16)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(value).ajText(.title)
            Text(label).ajText(.footnote)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(LinearGradient(colors: [Color(hex: hex), Color(hex: hex, opacity: 0.67)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Research

    private var research: some View {
        let rows: [(String, String, String)] = [
            ("−31%", "average drop in cortisol, a stress hormone, after massage across studies", "relax"),
            ("Less", "eczema in children massaged nightly with their moisturizer", "eczema"),
            ("Lower", "anxiety and depression in mothers who massaged their babies with eczema", "parent")]
        return panel {
            Text("What research shows").ajText(.callout).bold()
            ForEach(rows, id: \.0) { row in
                HStack(alignment: .top, spacing: AJSpacing.sm) {
                    Text(row.0)
                        .ajText(.callout, color: AJColor.accentWarm)
                        .frame(width: 64)
                        .padding(.vertical, 6)
                        .background(AJColor.accentWarm.opacity(0.15), in: RoundedRectangle(cornerRadius: AJRadius.sm, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.1).ajText(.subhead)
                        Text(StoryCatalog.facts[row.2]?.source ?? "").ajText(.footnote, color: AJColor.textTertiary)
                    }
                }
            }
            Text("Study averages, not measurements of your child.").ajText(.footnote, color: AJColor.textTertiary)
        }
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white.opacity(0.25), lineWidth: 1.5))
    }

    private func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) { content() }
            .padding(AJSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// A small line chart with a dot and value for each week.
private struct TrendLine: View {
    let values: [Double]
    let labels: [String]

    var body: some View {
        GeometryReader { geo in
            let low = 1.0, high = 3.0
            let inset: CGFloat = 30
            let step = values.count > 1 ? (geo.size.width - inset * 2) / CGFloat(values.count - 1) : 0
            let points = values.enumerated().map { index, value in
                CGPoint(x: inset + CGFloat(index) * step,
                        y: 22 + (geo.size.height - 48) * CGFloat(1 - (min(max(value, low), high) - low) / (high - low)))
            }
            ZStack(alignment: .topLeading) {
                Path { path in path.addLines(points) }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                ForEach(points.indices, id: \.self) { index in
                    Circle().fill(AJColor.accentWarm).frame(width: 12, height: 12).position(points[index])
                    Text(String(format: "%.1f", values[index])).ajText(.footnoteStrong).position(x: points[index].x, y: points[index].y - 14)
                    Text(labels[index]).ajText(.footnote).position(x: points[index].x, y: geo.size.height - 8)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Average night itch by week: " + values.map { String(format: "%.1f", $0) }.joined(separator: ", "))
    }
}
