import SwiftUI
import AljiDesignSystem

/// Where the hands go and how they move. Numbers match the prototype's 300 × 340 drawing.
enum MassageGeometry {
    static func spot(_ zone: String) -> CGPoint {
        let table: [String: (CGFloat, CGFloat)] = [
            "upper": (150, 200), "shL": (108, 176), "shR": (192, 176), "armL": (66, 236), "armR": (234, 236),
            "lower": (150, 262), "midL": (118, 232), "midR": (182, 232),
            "face": (150, 60), "chestL": (128, 140), "chestR": (172, 140),
            "tummy": (150, 185), "tummyL": (132, 182), "tummyR": (168, 186),
            "palm": (150, 230), "toes": (160, 88), "ball": (150, 150), "sole": (150, 200), "heel": (150, 262),
            "legL": (126, 268), "legR": (174, 268), "footL": (128, 318), "footR": (172, 318),
            "handL": (80, 216), "handR": (220, 216)]
        let point = table[zone] ?? (150, 220)
        return CGPoint(x: point.0, y: point.1)
    }

    /// One stroke: the line or circle a hand follows, relative to its zone.
    enum Track {
        case line([CGPoint])
        /// Starts at the top of the circle.
        case circle(radius: CGFloat, clockwise: Bool)

        func point(at progress: Double) -> CGPoint {
            switch self {
            case .circle(let radius, let clockwise):
                let angle = -Double.pi / 2 + (clockwise ? 1 : -1) * 2 * Double.pi * progress
                return CGPoint(x: radius * CGFloat(cos(angle)), y: radius * CGFloat(sin(angle)))
            case .line(let points):
                guard points.count > 1 else { return points.first ?? .zero }
                let lengths = zip(points, points.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) }
                let total = lengths.reduce(0, +)
                guard total > 0 else { return points[0] }
                var remaining = CGFloat(progress) * total
                for (index, length) in lengths.enumerated() {
                    if remaining <= length || index == lengths.count - 1 {
                        let t = length > 0 ? min(1, remaining / length) : 0
                        return CGPoint(x: points[index].x + (points[index + 1].x - points[index].x) * t,
                                       y: points[index].y + (points[index + 1].y - points[index].y) * t)
                    }
                    remaining -= length
                }
                return points[points.count - 1]
            }
        }

        var path: Path {
            switch self {
            case .circle(let radius, _):
                return Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
            case .line(let points):
                var path = Path()
                path.addLines(points)
                return path
            }
        }

        var end: CGPoint { point(at: 1) }
    }

    struct Stroke {
        let first: Track
        let second: Track
        let seconds: Double
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    static func stroke(_ motion: String) -> Stroke {
        switch motion {
        case "glide": return Stroke(first: .line([p(0, -30), p(0, 30)]), second: .line([p(0, -30), p(0, 30)]), seconds: 2.2)
        case "armGlide": return Stroke(first: .line([p(10, -36), p(-6, 36)]), second: .line([p(-10, -36), p(6, 36)]), seconds: 2.4)
        case "circle": return Stroke(first: .circle(radius: 11, clockwise: true), second: .circle(radius: 11, clockwise: false), seconds: 1.8)
        case "bigCircle": return Stroke(first: .circle(radius: 24, clockwise: true), second: .circle(radius: 24, clockwise: false), seconds: 3)
        case "open": return Stroke(first: .line([p(6, 0), p(-26, 0)]), second: .line([p(-6, 0), p(26, 0)]), seconds: 2)
        case "cross": return Stroke(first: .line([p(-20, -22), p(20, 22)]), second: .line([p(20, -22), p(-20, 22)]), seconds: 2.4)
        case "tap": return Stroke(first: .line([p(0, 0), p(0, -8), p(0, 0)]), second: .line([p(0, 0), p(0, -8), p(0, 0)]), seconds: 0.6)
        case "smooth": return Stroke(first: .line([p(0, -10), p(0, 10)]), second: .line([p(0, -10), p(0, 10)]), seconds: 3.4)
        case "iloveyou":
            let track = Track.line([p(22, -26), p(22, 18), p(-22, 18), p(-22, -26)])
            return Stroke(first: track, second: track, seconds: 4)
        case "footGlide": return Stroke(first: .line([p(-12, 80), p(-12, -80)]), second: .line([p(12, 80), p(12, -80)]), seconds: 3)
        case "palmOpen": return Stroke(first: .line([p(-6, 26), p(-30, -34)]), second: .line([p(6, 26), p(30, -34)]), seconds: 2.6)
        case "thumbWalk": return Stroke(first: .line([p(-12, 60), p(-12, -60)]), second: .line([p(12, 60), p(12, -60)]), seconds: 3.4)
        case "thumbCircle": return Stroke(first: .circle(radius: 12, clockwise: true), second: .line([.zero]), seconds: 1.8)
        case "heelCup": return Stroke(first: .circle(radius: 10, clockwise: true), second: .line([.zero]), seconds: 3)
        default: return Stroke(first: .line([.zero]), second: .line([.zero]), seconds: 2)
        }
    }

    /// How the hand is turned for each stroke, in degrees.
    static func rotation(_ motion: String) -> Double {
        ["glide": 90, "smooth": 90, "armGlide": 165, "open": -95, "cross": 55, "circle": -10,
         "bigCircle": 10, "tap": 0, "still": 80, "iloveyou": 0][motion] ?? 0
    }

    /// Strokes that press through, lift, and glide back (rather than looping round).
    static func isStroke(_ motion: String) -> Bool {
        ["palmOpen", "glide", "armGlide", "open", "cross", "smooth", "iloveyou", "footGlide", "thumbWalk", "toes"].contains(motion)
    }

    /// Strokes done hand over hand: one hand strokes while the other lifts and returns.
    static func alternates(_ motion: String) -> Bool {
        ["cross", "glide", "thumbWalk", "footGlide"].contains(motion)
    }

    /// Where a hand is in its stroke at `phase` (0...1): position along the track, opacity, press ring, lift.
    static func pose(motion: String, phase: Double, handOver: Bool) -> (progress: Double, opacity: Double, press: CGFloat, lift: CGFloat) {
        guard isStroke(motion) else { return (phase, 1, 19, 1) }
        let times: [Double] = handOver ? [0, 0.46, 0.5, 0.96, 1] : [0, 0.6, 0.68, 0.9, 1]
        let low = handOver ? 0.22 : 0.35
        let pressLow: Double = handOver ? 10 : 11
        let liftHigh = handOver ? 1.12 : 1.1
        return (interpolate(times, [0, 1, 1, 0, 0], phase),
                interpolate(times, [1, 1, low, low, 1], phase),
                CGFloat(interpolate(times, [19, 19, pressLow, pressLow, 19], phase)),
                CGFloat(interpolate(times, [1, 1, liftHigh, liftHigh, 1], phase)))
    }

    private static func interpolate(_ times: [Double], _ values: [Double], _ t: Double) -> Double {
        for index in 1..<times.count where t <= times[index] {
            let span = times[index] - times[index - 1]
            let local = span > 0 ? (t - times[index - 1]) / span : 0
            return values[index - 1] + (values[index] - values[index - 1]) * local
        }
        return values[values.count - 1]
    }
}

/// The massage guide for one step: the child (back, front, foot or palm) with hands showing the stroke,
/// two hands warming the cream, or a clear "roll over" sign.
struct MassageStepFigure: View {
    let step: MassageStep
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if step.view == "warm" {
            MassageFigure(motion: .warm)
        } else {
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                Canvas { context, canvasSize in
                    let size = ArtData.bodySize
                    let scale = min(canvasSize.width / size.width, canvasSize.height / size.height)
                    var ctx = context
                    ctx.translateBy(x: (canvasSize.width - size.width * scale) / 2, y: (canvasSize.height - size.height * scale) / 2)
                    ctx.scaleBy(x: scale, y: scale)
                    draw(ctx, time: reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate, size: size)
                }
            }
            .aspectRatio(ArtData.bodySize.width / ArtData.bodySize.height, contentMode: .fit)
            .accessibilityElement()
            .accessibilityLabel("Massage guide: \(step.label). \(step.cue)")
        }
    }

    private var isTurn: Bool { step.view == "turn" || step.view == "turnBack" }
    private var isThumbView: Bool { step.view == "foot" || step.view == "palm" }

    private func draw(_ ctx: GraphicsContext, time: Double, size: CGSize) {
        ctx.fill(Path(ellipseIn: CGRect(x: 40, y: 320, width: 220, height: 20)), with: .color(.black.opacity(0.18)))
        switch step.view {
        case "front", "turn": ArtRenderer.draw(ArtData.bodyFront, in: ctx, bounds: size)
        case "foot": ArtRenderer.draw(ArtData.foot, in: ctx, bounds: size)
        case "palm": ArtRenderer.draw(ArtData.palm, in: ctx, bounds: size)
        default: ArtRenderer.draw(ArtData.bodyBack, in: ctx, bounds: size)
        }
        if isTurn {
            drawTurn(ctx, time: time)
            return
        }

        let zones = step.zones.isEmpty ? ["upper"] : step.zones
        let single = zones.count == 1
        let oneHand = single && ["armGlide", "iloveyou", "bigCircle"].contains(step.motion)
        let zoneList = single ? (oneHand ? [zones[0]] : [zones[0], zones[0]]) : zones
        for zone in zoneList { glow(ctx, at: MassageGeometry.spot(zone), radius: 44) }

        let stroke = MassageGeometry.stroke(step.motion)
        if isThumbView {
            guard step.motion != "still" else { return }
            let both = ["thumbWalk", "footGlide", "palmOpen"].contains(step.motion)
            for index in both ? [0, 1] : [0] {
                let track = index == 0 ? stroke.first : stroke.second
                drawThumb(ctx, at: MassageGeometry.spot(zones[0]), track: track,
                          phase: phase(time, stroke.seconds, offsetHalf: MassageGeometry.alternates(step.motion) && index == 1),
                          handOver: MassageGeometry.alternates(step.motion))
            }
            return
        }

        for (index, zone) in zoneList.enumerated() {
            var origin = MassageGeometry.spot(zone)
            if single && !oneHand {
                let spread: CGFloat = zones[0] == "legL" || zones[0] == "legR" ? 7 : 24
                origin.x += spread * (index == 0 ? -1 : 1)
            }
            let mirrored = zones[0] == "armR" || index == 1
            let track = (zones[0] == "armR" || (zoneList.count > 1 && index == 1)) ? stroke.second : stroke.first
            let handOver = MassageGeometry.alternates(step.motion) || (single && !oneHand)
            let offset = handOver && index == 1 && MassageGeometry.isStroke(step.motion)
            drawHand(ctx, origin: origin, track: track, phase: phase(time, stroke.seconds, offsetHalf: offset),
                     handOver: handOver, mirrored: mirrored)
        }
    }

    private func phase(_ time: Double, _ seconds: Double, offsetHalf: Bool) -> Double {
        let shifted = time + (offsetHalf ? seconds / 2 : 0)
        return shifted.truncatingRemainder(dividingBy: seconds) / seconds
    }

    private func glow(_ ctx: GraphicsContext, at center: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [AJColor.accentCalm.opacity(0.55), AJColor.accentCalm.opacity(0)]),
            center: center, startRadius: 0, endRadius: radius))
    }

    private func drawGuide(_ ctx: GraphicsContext, track: MassageGeometry.Track) {
        ctx.stroke(track.path, with: .color(AJColor.accentWarm), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 7]))
    }

    private func drawHand(_ ctx: GraphicsContext, origin: CGPoint, track: MassageGeometry.Track, phase: Double,
                          handOver: Bool, mirrored: Bool) {
        var local = ctx
        local.translateBy(x: origin.x, y: origin.y)
        drawGuide(local, track: track)
        let end = step.motion == "still" ? CGPoint.zero : track.end
        local.fill(Path(ellipseIn: CGRect(x: end.x - 4, y: end.y - 4, width: 8, height: 8)), with: .color(AJColor.accentWarm))

        let pose = MassageGeometry.pose(motion: step.motion, phase: phase, handOver: handOver)
        let point = track.point(at: pose.progress)
        var hand = local
        hand.opacity = pose.opacity
        hand.translateBy(x: point.x, y: point.y)
        hand.fill(Path(ellipseIn: CGRect(x: -pose.press, y: -pose.press, width: pose.press * 2, height: pose.press * 2)),
                  with: .color(AJColor.accentCalm.opacity(0.35)))
        hand.scaleBy(x: pose.lift, y: pose.lift)
        let rotation = MassageGeometry.rotation(step.motion)
        hand.rotate(by: .degrees(mirrored ? -rotation : rotation))
        hand.scaleBy(x: mirrored ? -1.25 : 1.25, y: 1.25)
        hand.translateBy(x: -ArtData.handAnchor.x, y: -ArtData.handAnchor.y)
        ArtRenderer.draw(ArtData.hand, in: hand, bounds: ArtData.handSize)
    }

    private func drawThumb(_ ctx: GraphicsContext, at origin: CGPoint, track: MassageGeometry.Track, phase: Double, handOver: Bool) {
        var local = ctx
        local.translateBy(x: origin.x, y: origin.y)
        drawGuide(local, track: track)
        let pose = MassageGeometry.pose(motion: step.motion, phase: phase, handOver: handOver)
        let point = track.point(at: pose.progress)
        var thumb = local
        thumb.opacity = pose.opacity
        thumb.translateBy(x: point.x, y: point.y)
        thumb.fill(Path(ellipseIn: CGRect(x: -14, y: -14, width: 28, height: 28)), with: .color(AJColor.accentCalm.opacity(0.35)))
        thumb.scaleBy(x: 1.35, y: 1.35)
        thumb.translateBy(x: -ArtData.thumbAnchor.x, y: -ArtData.thumbAnchor.y)
        ArtRenderer.draw(ArtData.thumb, in: thumb, bounds: ArtData.thumbSize)
    }

    /// A round sign with a turning arrow and "Roll onto back" or "Roll onto tummy".
    private func drawTurn(_ ctx: GraphicsContext, time: Double) {
        let disc = Path(ellipseIn: CGRect(x: 88, y: 134, width: 124, height: 124))
        ctx.fill(disc, with: .color(AJColor.background.opacity(0.86)))
        ctx.stroke(disc, with: .color(AJColor.accentWarm), lineWidth: 3)
        var arrow = Path()
        arrow.addArc(center: CGPoint(x: 150, y: 200), radius: 32, startAngle: .degrees(173), endAngle: .degrees(485), clockwise: false)
        var pulsing = ctx
        pulsing.opacity = 0.7 + 0.3 * sin(time / 1.6 * 2 * Double.pi)
        pulsing.stroke(arrow, with: .color(AJColor.accentWarm), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        var head = Path()
        head.move(to: CGPoint(x: 112, y: 232))
        head.addLine(to: CGPoint(x: 134, y: 222))
        head.addLine(to: CGPoint(x: 134, y: 244))
        head.closeSubpath()
        ctx.fill(head, with: .color(AJColor.accentWarm))
        ctx.draw(Text(step.reps).ajCanvasText(.callout, color: AJColor.accentWarm), at: CGPoint(x: 150, y: 282))
    }
}
