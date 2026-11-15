import SwiftUI

// Parts used by the main app (Tonight, Stories, the massage player, Progress), matching the approved prototype.

/// The gold crescent moon.
public struct AJMoon: View {
    let size: CGFloat
    let color: Color

    public init(size: CGFloat = 150, color: Color = AJColor.accentWarm) {
        self.size = size
        self.color = color
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size * 0.62, height: size * 0.62)
                .offset(x: -size * 0.02, y: size * 0.02)
            Circle()
                .frame(width: size * 0.56, height: size * 0.56)
                .offset(x: size * 0.11, y: -size * 0.075)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A small answer chip for check-ins. Selected: filled gold.
public struct AJChoiceChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    public init(_ label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .ajText(.callout, color: isSelected ? AJColor.onAccent : AJColor.textPrimary)
                .padding(.horizontal, AJSpacing.md)
                .frame(minHeight: 46)
                .background(isSelected ? AJColor.accentWarm : Color.clear, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : AJColor.border, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A titled on/off row, used in sheets.
public struct AJSwitchRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    public init(_ title: String, detail: String, isOn: Binding<Bool>) {
        self.title = title
        self.detail = detail
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).ajText(.callout)
                Text(detail).ajText(.footnote, color: AJColor.textSecondary)
            }
        }
        .tint(AJColor.accentCalm)
        .padding(.horizontal, 14)
        .padding(.vertical, AJSpacing.xs)
        .frame(minHeight: 58)
        .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
    }
}

/// A story in the library. Wide: art on the left. Compact: art on top, for side-scrolling rows.
public struct AJStoryCard: View {
    let title: String
    let meta: String
    let color: Color
    let isWide: Bool
    let action: () -> Void

    public init(title: String, meta: String, color: Color, isWide: Bool, action: @escaping () -> Void) {
        self.title = title
        self.meta = meta
        self.color = color
        self.isWide = isWide
        self.action = action
    }

    private var art: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(colors: [color, AJColor.surfaceDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(AJStar(size: 26))
            .accessibilityHidden(true)
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).ajText(.callout).multilineTextAlignment(.leading)
            Text(meta).ajText(.footnote, color: AJColor.textSecondary)
        }
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if isWide {
                    HStack(spacing: 14) {
                        art.frame(width: 84, height: 84)
                        text
                        Spacer(minLength: 0)
                    }
                    .padding(AJSpacing.sm)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        art.frame(height: 96)
                        text
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .frame(width: 156)
                }
            }
            .background(AJColor.surface, in: RoundedRectangle(cornerRadius: AJRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// The title row of a bottom sheet, with a close button.
public struct AJSheetHeader: View {
    let title: String
    let onClose: () -> Void

    public init(_ title: String, onClose: @escaping () -> Void) {
        self.title = title
        self.onClose = onClose
    }

    public var body: some View {
        HStack(spacing: 10) {
            AJHighlightedTitle(title, style: .title2)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(aj: .close)
                    .ajIcon(14)
                    .frame(width: AJSize.minTouch, height: AJSize.minTouch)
                    .overlay(Circle().strokeBorder(AJColor.border, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

/// A thin progress track, used by the massage player.
public struct AJProgressTrack: View {
    let progress: Double

    public init(progress: Double) { self.progress = min(max(progress, 0), 1) }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.22))
                Capsule()
                    .fill(LinearGradient(colors: [AJColor.accentCalm, AJColor.accentWarm], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 6)
        .animation(.linear(duration: 1), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}


/// Two or three choices in one pill-shaped row. Selected: white.
public struct AJSegmentedPicker<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    let accessibilityLabel: String

    public init(_ accessibilityLabel: String, options: [(value: Value, label: String)], selection: Binding<Value>) {
        self.accessibilityLabel = accessibilityLabel
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: AJSpacing.xxs) {
            ForEach(options, id: \.value) { option in
                let isOn = option.value == selection
                Button { selection = option.value } label: {
                    Text(option.label)
                        .ajText(.callout, color: isOn ? AJColor.onAccent : AJColor.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(isOn ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(AJSpacing.xxs)
        .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// A gold-edged note with a small heading, used for "Why it helps".
public struct AJFactCard: View {
    let eyebrow: String
    let text: String
    let source: String

    public init(eyebrow: String, text: String, source: String) {
        self.eyebrow = eyebrow
        self.text = text
        self.source = source
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AJSpacing.xxs) {
            Text(eyebrow).ajText(.label, color: AJColor.accentWarm)
            Text(text).ajText(.subhead)
            Text(source).ajText(.footnote, color: AJColor.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AJColor.accentWarm.opacity(0.1), in: RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: AJRadius.md, style: .continuous).strokeBorder(AJColor.accentWarm.opacity(0.45), lineWidth: 1.5))
    }
}

/// A full-width outlined button, 52pt tall, used for quieter actions next to a primary button.
public struct AJOutlineButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .ajText(.callout)
            .frame(maxWidth: .infinity, minHeight: 52)
            .overlay(RoundedRectangle(cornerRadius: AJRadius.button, style: .continuous).strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5))
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public extension ButtonStyle where Self == AJOutlineButtonStyle {
    static var ajOutline: AJOutlineButtonStyle { AJOutlineButtonStyle() }
}
