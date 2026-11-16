import SwiftUI
import AljiDesignSystem

// Story illustrations: covers, the Tonight banner, the scenes behind the massage guide, and the night sky.
// The drawings in `StoryArtData` are placeholders that mark each story's subject until final art is ready.

enum StoryArt {
    static func motif(_ id: String) -> [ArtShape] { StoryArtData.motifs[id] ?? StoryArtData.fallback }

    /// A five-point star centered on `center`.
    static func star(_ center: CGPoint, radius: CGFloat, rotation: Double = 0) -> Path {
        var path = Path()
        for index in 0..<10 {
            let angle = (-90 + rotation + Double(index) * 36) * Double.pi / 180
            let r = index % 2 == 0 ? radius : radius * 0.5
            let point = CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// Rolling hills along the bottom of a picture, drawn through `points` (alternating control and end points).
    static func hills(start: CGPoint, curves: [(control: CGPoint, end: CGPoint)], width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        path.move(to: start)
        for curve in curves { path.addQuadCurve(to: curve.end, control: curve.control) }
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }

    static func sparkles(_ ctx: GraphicsContext, at points: [CGPoint], radius: CGFloat) {
        for (index, point) in points.enumerated() {
            ctx.fill(star(point, radius: radius), with: .color(.white.opacity(index % 2 == 0 ? 0.85 : 0.55)))
        }
    }

    static func gradient(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color, AJColor.surfaceDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// A story's picture-book cover, 150 × 190.
struct StoryCoverArt: View {
    let storyID: String
    let color: Color

    var body: some View {
        Canvas { context, size in
            var ctx = context
            ctx.scaleBy(x: size.width / 150, y: size.height / 190)
            let p = { (x: CGFloat, y: CGFloat) in CGPoint(x: x, y: y) }
            ctx.fill(StoryArt.hills(start: p(0, 158), curves: [(p(38, 136), p(76, 152)), (p(114, 168), p(150, 146))], width: 150, height: 190),
                     with: .color(Color(hex: 0x0E1238, opacity: 0.35)))
            StoryArt.sparkles(ctx, at: [p(22, 26), p(128, 22), p(116, 164), p(30, 170), p(136, 76)], radius: 3.4)
            ArtRenderer.draw(StoryArt.motif(storyID), in: ctx, blob: color, bounds: CGSize(width: 150, height: 190))
        }
        .background(StoryArt.gradient(color))
        .accessibilityHidden(true)
    }
}

/// Tonight's story as a wide banner on the home screen.
struct StoryBanner: View {
    let storyID: String
    let color: Color
    let label: String
    let minutes: String

    var body: some View {
        Canvas { context, size in
            var ctx = context
            ctx.scaleBy(x: size.width / 346, y: size.height / 204)
            let p = { (x: CGFloat, y: CGFloat) in CGPoint(x: x, y: y) }
            StoryArt.sparkles(ctx, at: [p(30, 40), p(300, 35), p(64, 112), p(286, 123), p(238, 48)], radius: 4)
            ctx.fill(StoryArt.hills(start: p(0, 168), curves: [(p(60, 138), p(122, 158)), (p(184, 178), p(240, 150)), (p(296, 122), p(346, 160))],
                                    width: 346, height: 204),
                     with: .color(Color(hex: 0x0E1238, opacity: 0.38)))
            ctx.translateBy(x: 98, y: 4)
            ArtRenderer.draw(StoryArt.motif(storyID), in: ctx, blob: color, bounds: CGSize(width: 150, height: 190))
        }
        .frame(height: 204)
        .background(StoryArt.gradient(color))
        .overlay(alignment: .topLeading) { chip(label, color: AJColor.accentWarm) }
        .overlay(alignment: .topTrailing) { chip(minutes, color: AJColor.textPrimary) }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5))
        .accessibilityElement()
        .accessibilityLabel("\(label). \(minutes)")
    }

    private func chip(_ text: String, color: Color) -> some View {
        Text(text)
            .ajText(.label, color: color)
            .padding(.horizontal, AJSpacing.sm)
            .padding(.vertical, 6)
            .background(Color(hex: 0x0E1238, opacity: 0.55), in: Capsule())
            .padding(AJSpacing.sm)
    }
}

/// The picture behind the massage guide. It follows what the story is saying in the current step.
struct StoryScene: View {
    let storyLine: String

    /// Words in the story line → which drawing to show, and the sky color behind it.
    private static let table: [(words: [String], motif: String, tint: UInt32)] = [
        (["comet", "whoosh"], "comet", 0x3B2F86),
        (["net", "catch", "search", "zigzag"], "lastStar", 0x274A86),
        (["pond", "puddle", "skate", "circle", "round"], "calm", 0x1F5A78),
        (["river", "moonbeam", "slide", "sail", "glide", "down the"], "emotions", 0x2B4C8C),
        (["cloud", "blanket", "snow", "feather"], "flareStory", 0x3A3F8A),
        (["warm", "sun", "cozy", "jar", "cream"], "positive", 0x6A4A7E),
        (["ladder", "climb", "hill", "up, up"], "brave", 0x34407F),
        (["love", "heart", "kiss"], "loved", 0x6A3F7A),
        (["moon", "goodnight", "sleep", "tuck", "rest", "dream"], "sleepy", 0x2A2F78),
        (["star"], "littleStar", 0x2F3A86)
    ]

    private var match: (motif: String, tint: UInt32) {
        let text = storyLine.lowercased()
        if let hit = Self.table.first(where: { row in row.words.contains { text.contains($0) } }) { return (hit.motif, hit.tint) }
        return ("littleStar", 0x2F3A86)
    }

    var body: some View {
        let scene = match
        let tint = Color(hex: scene.tint)
        Canvas { context, size in
            // Fill the area like a photo would: scale up until both sides are covered, then center.
            let scale = max(size.width / 390, size.height / 420)
            var ctx = context
            ctx.translateBy(x: (size.width - 390 * scale) / 2, y: (size.height - 420 * scale) / 2)
            ctx.scaleBy(x: scale, y: scale)
            let p = { (x: CGFloat, y: CGFloat) in CGPoint(x: x, y: y) }
            ctx.fill(StoryArt.hills(start: p(0, 356), curves: [(p(70, 318), p(150, 344)), (p(230, 370), p(290, 330)), (p(350, 290), p(390, 348))],
                                    width: 390, height: 420),
                     with: .color(Color(hex: 0x0E1238, opacity: 0.4)))
            StoryArt.sparkles(ctx, at: [p(40, 64), p(352, 50), p(330, 217), p(30, 254)], radius: 4)
            let bounds = CGSize(width: 150, height: 190)
            var left = ctx
            left.opacity = 0.7
            left.translateBy(x: -22, y: -18)
            left.scaleBy(x: 0.92, y: 0.92)
            ArtRenderer.draw(StoryArt.motif(scene.motif), in: left, blob: tint, bounds: bounds)
            var right = ctx
            right.opacity = 0.5
            right.translateBy(x: 284, y: 210)
            right.scaleBy(x: 0.66, y: 0.66)
            ArtRenderer.draw(StoryArt.motif(scene.motif == "littleStar" ? "sleepy" : "littleStar"), in: right, blob: tint, bounds: bounds)
        }
        .background(LinearGradient(colors: [tint, AJColor.background], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.78)))
        .animation(.easeInOut(duration: 1.2), value: scene.motif)
        .accessibilityHidden(true)
    }
}

/// The child's sky: every finished night is a glow star, and each five stars join into a constellation.
struct NightSky: View {
    /// One color per night, oldest first.
    let colors: [Color]

    static let capacity = positions.count
    private static let positions: [(CGFloat, CGFloat)] = [
        (30, 40), (58, 24), (86, 44), (70, 74), (40, 78), (124, 30), (150, 52), (178, 34), (196, 66), (160, 86),
        (214, 150), (244, 136), (270, 160), (300, 142), (322, 170), (176, 196), (206, 214), (238, 196), (268, 222), (304, 206),
        (160, 120), (186, 132), (170, 160), (200, 176), (150, 180), (40, 150), (72, 186), (104, 158), (250, 40), (292, 66), (236, 92)]

    var body: some View {
        Canvas { context, size in
            var ctx = context
            let scale = min(size.width / 346, size.height / 236)
            ctx.translateBy(x: (size.width - 346 * scale) / 2, y: 0)
            ctx.scaleBy(x: scale, y: scale)
            let points = Self.positions.prefix(colors.count).map { CGPoint(x: $0.0, y: $0.1) }
            for index in points.indices where index % 5 != 0 {
                var line = Path()
                line.move(to: points[index - 1])
                line.addLine(to: points[index])
                ctx.stroke(line, with: .color(AJColor.starGlow.opacity(0.42)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, dash: [2, 5]))
            }
            for (index, point) in points.enumerated() {
                var glow = ctx
                glow.addFilter(.shadow(color: colors[index], radius: 5))
                glow.fill(StoryArt.star(point, radius: 8, rotation: Double((index * 37) % 30 - 15)), with: .color(colors[index]))
            }
        }
        .aspectRatio(346 / 236, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
