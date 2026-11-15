import SwiftUI

/// Card container: groups related content on the night background.
public struct AJCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AJSpacing.sm) { content }
            .padding(AJSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.xl, style: .continuous))
    }
}

/// Section header with an optional trailing note.
public struct AJSectionHeader: View {
    let title: String
    let trailing: String?

    public init(_ title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).ajText(.headline).accessibilityAddTraits(.isHeader)
            Spacer()
            if let trailing { Text(trailing).ajText(.footnote, color: AJColor.textSecondary) }
        }
    }
}

/// Screen title block: optional eyebrow + title + optional supporting line.
public struct AJScreenHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    let isHero: Bool

    public init(eyebrow: String? = nil, title: String, subtitle: String? = nil, isHero: Bool = false) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.isHero = isHero
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AJSpacing.xs) {
            if let eyebrow { Text(eyebrow).ajText(.label, color: AJColor.accentCalm) }
            Text(title)
                .ajText(isHero ? .display : .title)
                .accessibilityAddTraits(.isHeader)
            if let subtitle { Text(subtitle).ajText(.body, color: AJColor.textSecondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Inline notice, e.g. the prescribed-cream safety reminder.
public struct AJNotice: View {
    let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        HStack(alignment: .top, spacing: AJSpacing.sm) {
            Image(aj: .info)
                .font(.system(size: AJSize.iconSmall, weight: .semibold))
                .foregroundStyle(AJColor.accentWarm)
                .accessibilityHidden(true)
            Text(text).ajText(.footnote, color: AJColor.textSecondary)
        }
        .padding(AJSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous))
    }
}

/// Small filled badge, e.g. "Glide · dry skin".
public struct AJBadge: View {
    public enum Tone { case calm, warm }
    let text: String
    let tone: Tone

    public init(_ text: String, tone: Tone) {
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        Text(text)
            .ajText(.label, color: AJColor.onAccent)
            .padding(.horizontal, AJSpacing.sm)
            .padding(.vertical, 6)
            .background(tone == .calm ? AJColor.accentCalm : AJColor.accentWarm, in: Capsule())
    }
}

/// Segmented progress bar for ritual steps.
public struct AJSegmentedProgress: View {
    let total: Int
    let current: Int
    /// Progress within the current segment, 0...1.
    let fraction: Double

    public init(total: Int, current: Int, fraction: Double) {
        self.total = total
        self.current = current
        self.fraction = min(max(fraction, 0), 1)
    }

    public var body: some View {
        HStack(spacing: AJSpacing.xxs) {
            ForEach(0..<max(total, 1), id: \.self) { index in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AJColor.surfaceRaised)
                        Capsule()
                            .fill(AJColor.accentCalm)
                            .frame(width: geo.size.width * fill(for: index))
                    }
                }
                .frame(height: 5)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }

    private func fill(for index: Int) -> CGFloat {
        if index < current { return 1 }
        if index == current { return CGFloat(fraction) }
        return 0
    }
}
