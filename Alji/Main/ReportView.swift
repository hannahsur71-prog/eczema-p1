import SwiftUI
import SwiftData
import Charts
import AljiDesignSystem

/// Doctor-ready report built from nightly check-ins.
struct ReportView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var store
    @Query(sort: \NightLog.date, order: .reverse) private var logs: [NightLog]
    @State private var pdfURL: URL?
    @State private var showUpgrade = false

    private var recent: [NightLog] { Array(logs.prefix(14)).reversed() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.lg) {
                    AJScreenHeader(eyebrow: "Skin report · last 14 nights", title: appState.answers.displayChild)
                    if logs.isEmpty {
                        AJCard {
                            Text("No nights logged yet").ajText(.headline)
                            Text("After each ritual, tap how itchy tonight was. It takes 2 seconds, and your report builds itself.")
                                .ajText(.body, color: AJColor.textSecondary)
                        }
                    } else {
                        ceiling
                        stats
                        chart
                        notes
                        shareButton
                    }
                    Text(AppConfig.medicalDisclaimer).ajText(.footnote, color: AJColor.textSecondary)
                }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.vertical, AJSpacing.lg)
            }
            .background(AJColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showUpgrade) { PaywallView(context: .upgrade) }
        }
    }

    /// One glow star for every night logged, like stickers going up on the ceiling.
    private var ceiling: some View {
        AJCard {
            AJSectionHeader("Your ceiling", trailing: "\(min(logs.count, 30)) of 30 nights")
            AJStarCeiling(total: 30, lit: logs.count)
            Text("Every night you log lights a star.").ajText(.footnote, color: AJColor.textSecondary)
        }
    }

    private var stats: some View {
        let avg = Double(recent.map(\.itch).reduce(0, +)) / Double(max(recent.count, 1))
        return HStack(spacing: AJSpacing.xs) {
            AJCard { AJStat(value: String(format: "%.1f", avg), caption: "average itch (1–5)", tone: avg >= 3.5 ? .warm : .calm) }
            AJCard { AJStat(value: "\(recent.count)", caption: "rituals logged") }
        }
    }

    private var chart: some View {
        AJCard {
            AJSectionHeader("Itch each night")
            Chart(recent) { log in
                BarMark(x: .value("Night", log.date, unit: .day), y: .value("Itch", log.itch))
                    .foregroundStyle(log.itch >= 4 ? AJColor.accentWarm : AJColor.accentCalm)
                    .cornerRadius(6)
            }
            .chartYScale(domain: 0...5)
            .chartYAxis { AxisMarks(values: [1, 3, 5]) }
            .frame(height: 180)
            .accessibilityLabel("Bar chart of nightly itch ratings")
        }
    }

    private var notes: some View {
        let tagCounts = Dictionary(recent.flatMap(\.tags).map { ($0, 1) }, uniquingKeysWith: +)
            .sorted { $0.value > $1.value }
        let zoneCounts = Dictionary(recent.flatMap(\.zoneIDs).map { ($0, 1) }, uniquingKeysWith: +)
            .sorted { $0.value > $1.value }
            .compactMap { CareZone(rawValue: $0.key)?.label }
        return AJCard {
            AJSectionHeader("Areas cared for most")
            Text(zoneCounts.isEmpty ? "Whole body" : zoneCounts.prefix(4).joined(separator: ", ")).ajText(.body)
            AJSectionHeader("Notes")
            Text(tagCounts.isEmpty ? "None logged" : tagCounts.prefix(4).map { "\($0.key) (\($0.value)×)" }.joined(separator: " · "))
                .ajText(.body)
        }
    }

    @ViewBuilder private var shareButton: some View {
        if !store.isSubscribed {
            Button("Share PDF with your doctor · Premium") { showUpgrade = true }.buttonStyle(.ajSecondary)
        } else if let pdfURL {
            ShareLink(item: pdfURL) { Text("Share PDF with your doctor") }.buttonStyle(.ajPrimary)
        } else {
            Button("Create PDF for your doctor") { pdfURL = makePDF() }.buttonStyle(.ajPrimary)
        }
    }

    @MainActor
    private func makePDF() -> URL? {
        let content = ReportPDFPage(childName: appState.answers.displayChild, logs: recent)
            .frame(width: 612, height: 792)
        let renderer = ImageRenderer(content: content)
        let url = URL.temporaryDirectory.appending(path: "\(AppConfig.appName)-Skin-Report.pdf")
        var made = false
        renderer.render { size, render in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            render(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            made = true
        }
        return made ? url : nil
    }
}

/// Printable, light-background page for the doctor.
private struct ReportPDFPage: View {
    let childName: String
    let logs: [NightLog]

    var body: some View {
        VStack(alignment: .leading, spacing: AJSpacing.md) {
            Text("\(AppConfig.appName) skin report").ajText(.title, color: .black)
            Text("\(childName) · \(logs.count) nights · generated \(Date.now.formatted(date: .abbreviated, time: .omitted))")
                .ajText(.callout, color: .gray)
            ForEach(logs) { log in
                HStack(alignment: .top) {
                    Text(log.date.formatted(date: .abbreviated, time: .omitted)).ajText(.callout, color: .black).frame(width: 110, alignment: .leading)
                    Text("Itch \(log.itch)/5").ajText(.callout, color: .black).frame(width: 80, alignment: .leading)
                    Text(log.tags.joined(separator: ", ")).ajText(.footnote, color: .gray)
                }
            }
            Spacer()
            Text("Parent-reported nightly itch ratings (1 = calm, 5 = very itchy). Not a diagnosis.")
                .ajText(.footnote, color: .gray)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }
}
