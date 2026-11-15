import SwiftUI
import AljiDesignSystem

/// One filled or stroked shape of an illustration. Data lives in `ArtData` (generated from the prototype).
struct ArtShape {
    let path: Path
    let fill: Color?
    let stroke: Color?
    let lineWidth: CGFloat
    /// 0 = normal, 1 = skin gradient, 2 = takes the screen's blob color.
    let special: Int

    init(_ d: String, fill: UInt32?, fillOpacity: Double, stroke: UInt32?, strokeOpacity: Double, lineWidth: CGFloat, special: Int) {
        self.path = ArtShape.parse(d)
        self.fill = fill.map { Color(hex: $0, opacity: fillOpacity) }
        self.stroke = stroke.map { Color(hex: $0, opacity: strokeOpacity) }
        self.lineWidth = lineWidth
        self.special = special
    }

    /// Parses absolute path data: M x y · L x y · C x1 y1 x2 y2 x y · Q cx cy x y · Z.
    private static func parse(_ d: String) -> Path {
        var path = Path()
        let tokens = d.split(separator: " ")
        var i = 0
        func number() -> CGFloat {
            defer { i += 1 }
            return i < tokens.count ? CGFloat(Double(tokens[i]) ?? 0) : 0
        }
        func point() -> CGPoint {
            let x = number()
            let y = number()
            return CGPoint(x: x, y: y)
        }
        while i < tokens.count {
            let command = tokens[i]
            i += 1
            switch command {
            case "M": path.move(to: point())
            case "L": path.addLine(to: point())
            case "C":
                let c1 = point()
                let c2 = point()
                let end = point()
                path.addCurve(to: end, control1: c1, control2: c2)
            case "Q":
                let c = point()
                let end = point()
                path.addQuadCurve(to: end, control: c)
            case "Z": path.closeSubpath()
            default: break
            }
        }
        return path
    }
}

enum ArtRenderer {
    static let skin = Gradient(colors: [Color(hex: 0xF8C4A0), Color(hex: 0xE59C76)])

    /// Draws shapes in their own coordinate space. Apply transforms to `context` first.
    static func draw(_ shapes: [ArtShape], in context: GraphicsContext, blob: Color = AJColor.surfaceRaised, bounds: CGSize) {
        for shape in shapes {
            if shape.fill != nil {
                switch shape.special {
                case 1:
                    context.fill(shape.path, with: .linearGradient(skin, startPoint: .zero,
                                                                   endPoint: CGPoint(x: bounds.width, y: bounds.height)))
                case 2:
                    context.fill(shape.path, with: .color(blob))
                default:
                    context.fill(shape.path, with: .color(shape.fill ?? .clear))
                }
            }
            if let stroke = shape.stroke {
                context.stroke(shape.path, with: .color(stroke),
                               style: StrokeStyle(lineWidth: shape.lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

/// A static illustration, scaled to fit its frame.
struct ArtView: View {
    let shapes: [ArtShape]
    let size: CGSize
    var blob: Color = AJColor.surfaceRaised

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width / size.width, canvasSize.height / size.height)
            var ctx = context
            ctx.translateBy(x: (canvasSize.width - size.width * scale) / 2, y: (canvasSize.height - size.height * scale) / 2)
            ctx.scaleBy(x: scale, y: scale)
            ArtRenderer.draw(shapes, in: ctx, blob: blob, bounds: size)
        }
        .aspectRatio(size.width / size.height, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// The night-sky background with glow-sticker stars, used across Alji.
struct StarryBackground: View {
    var opacity: Double = 0.45
    var seed: UInt64 = 7

    var body: some View {
        ZStack {
            AJColor.background
            AJStarField(count: 16, seed: seed, opacity: opacity)
        }
        .ignoresSafeArea()
    }
}

/// Onboarding background: a painted sky band at the top that fades into the night indigo.
struct OnboardingSky: View {
    var body: some View {
        ZStack(alignment: .top) {
            AJColor.background
            LinearGradient(colors: [Color(hex: 0x16245C), Color(hex: 0x1F2C68), AJColor.background],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 300)
            AJStarField(count: 10, seed: 7, opacity: 0.8)
                .frame(height: 300)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// The soft blob with a dashed ring, moon, stars and cream jar shown on insight screens.
struct HeroArt: View {
    let colorIndex: Int

    private var blob: Color {
        [Color(hex: 0x7E63B8), Color(hex: 0x8FC7DD), Color(hex: 0x6C5BB0), Color(hex: 0xA27FD0)][colorIndex % 4]
    }

    var body: some View {
        ZStack {
            Ellipse().fill(blob)
            Ellipse()
                .strokeBorder(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 3, dash: [8, 7]))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            ArtView(shapes: ArtData.hero, size: ArtData.heroSize, blob: blob)
        }
        .frame(width: 230, height: 210)
        .accessibilityHidden(true)
    }
}

// MARK: - Massage figure

/// How the hands move for one step of the 1-minute ritual.
enum MassageMotion: Equatable {
    case warm, armGlide, bigCircle
}

/// The child seen from behind with animated hands, or two hands warming the cream.
/// Coordinates match the prototype's 300 × 340 drawing.
struct MassageFigure: View {
    let motion: MassageMotion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, canvasSize in
                let size = ArtData.bodySize
                let scale = min(canvasSize.width / size.width, canvasSize.height / size.height)
                var ctx = context
                ctx.translateBy(x: (canvasSize.width - size.width * scale) / 2, y: (canvasSize.height - size.height * scale) / 2)
                ctx.scaleBy(x: scale, y: scale)
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                switch motion {
                case .warm:
                    drawWarm(ctx, time: time)
                case .armGlide:
                    ArtRenderer.draw(ArtData.bodyBack, in: ctx, bounds: size)
                    drawStroke(ctx, time: time, at: CGPoint(x: 66, y: 236), from: CGPoint(x: 10, y: -36),
                               to: CGPoint(x: -6, y: 36), rotation: 165, mirrored: false)
                    drawStroke(ctx, time: time, at: CGPoint(x: 234, y: 236), from: CGPoint(x: -10, y: -36),
                               to: CGPoint(x: 6, y: 36), rotation: -165, mirrored: true)
                case .bigCircle:
                    ArtRenderer.draw(ArtData.bodyBack, in: ctx, bounds: size)
                    drawCircle(ctx, time: time, at: CGPoint(x: 150, y: 200), radius: 24)
                }
            }
        }
        .aspectRatio(ArtData.bodySize.width / ArtData.bodySize.height, contentMode: .fit)
    }

    private func glow(_ ctx: GraphicsContext, at center: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [AJColor.accentCalm.opacity(0.55), AJColor.accentCalm.opacity(0)]),
            center: center, startRadius: 0, endRadius: radius))
    }

    private func drawHand(_ ctx: GraphicsContext, at point: CGPoint, rotation: Double, mirrored: Bool, scale: CGFloat, opacity: Double) {
        var hand = ctx
        hand.opacity = opacity
        hand.translateBy(x: point.x, y: point.y)
        hand.rotate(by: .degrees(rotation))
        hand.scaleBy(x: mirrored ? -scale : scale, y: scale)
        hand.translateBy(x: -ArtData.handAnchor.x, y: -ArtData.handAnchor.y)
        ArtRenderer.draw(ArtData.hand, in: hand, bounds: ArtData.handSize)
    }

    /// Press slowly through the stroke, lift, glide back, set down again.
    private func drawStroke(_ ctx: GraphicsContext, time: Double, at origin: CGPoint, from: CGPoint, to: CGPoint,
                            rotation: Double, mirrored: Bool) {
        glow(ctx, at: origin, radius: 44)
        var guide = Path()
        guide.move(to: CGPoint(x: origin.x + from.x, y: origin.y + from.y))
        guide.addLine(to: CGPoint(x: origin.x + to.x, y: origin.y + to.y))
        ctx.stroke(guide, with: .color(AJColor.accentWarm), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 7]))
        let phase = time.truncatingRemainder(dividingBy: 2.4) / 2.4
        var progress = 0.0
        var opacity = 1.0
        if phase < 0.6 {
            progress = phase / 0.6
        } else if phase < 0.68 {
            progress = 1
            opacity = 1 - (phase - 0.6) / 0.08 * 0.6
        } else if phase < 0.9 {
            progress = 1 - (phase - 0.68) / 0.22
            opacity = 0.4
        } else {
            opacity = 0.4 + (phase - 0.9) / 0.1 * 0.6
        }
        let point = CGPoint(x: origin.x + from.x + (to.x - from.x) * progress,
                            y: origin.y + from.y + (to.y - from.y) * progress)
        drawHand(ctx, at: point, rotation: rotation, mirrored: mirrored, scale: 1.25, opacity: opacity)
    }

    private func drawCircle(_ ctx: GraphicsContext, time: Double, at center: CGPoint, radius: CGFloat) {
        glow(ctx, at: center, radius: 44)
        let ring = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.stroke(Path(ellipseIn: ring), with: .color(AJColor.accentWarm),
                   style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 7]))
        let angle = time.truncatingRemainder(dividingBy: 3) / 3 * 2 * Double.pi - Double.pi / 2
        let point = CGPoint(x: center.x + radius * CGFloat(cos(angle)), y: center.y + radius * CGFloat(sin(angle)))
        drawHand(ctx, at: point, rotation: 10, mirrored: false, scale: 1.25, opacity: 1)
    }

    /// Two hands rubbing together with the cream between them.
    private func drawWarm(_ ctx: GraphicsContext, time: Double) {
        let center = CGPoint(x: 150, y: 190)
        glow(ctx, at: CGPoint(x: center.x, y: center.y - 10), radius: 100)
        let slide = CGFloat(sin(time / 1.4 * 2 * Double.pi))
        let first = CGPoint(x: center.x - 25 + 8 * slide, y: center.y + 25 - 10 * slide)
        let second = CGPoint(x: center.x + 25 - 8 * slide, y: center.y + 25 + 10 * slide)
        drawHand(ctx, at: first, rotation: 42, mirrored: false, scale: 2.5, opacity: 1)
        let cream = CGRect(x: center.x - 16, y: center.y + 3, width: 32, height: 18)
        ctx.fill(Path(ellipseIn: cream), with: .color(.white.opacity(0.95)))
        drawHand(ctx, at: second, rotation: -42, mirrored: true, scale: 2.5, opacity: 0.97)
    }
}

/// Scrolling content with a pinned footer. Used by the in-app paywall and the night check-in.
struct OnboardingScaffold<Content: View, Footer: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AJSpacing.lg) { content }
                    .padding(.horizontal, AJSpacing.screenGutter)
                    .padding(.top, AJSpacing.lg)
                    .padding(.bottom, AJSpacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: AJSpacing.xs) { footer }
                .padding(.horizontal, AJSpacing.screenGutter)
                .padding(.top, AJSpacing.sm)
                .padding(.bottom, AJSpacing.md)
                .background(AJColor.background)
        }
    }
}
