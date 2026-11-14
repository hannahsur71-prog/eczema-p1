import SwiftUI

// Alji's signature detail: the glow-in-the-dark star stickers on a childhood ceiling.
// Stars glow a soft phosphorescent green-yellow, like real glow stickers, never bright white.

public extension HBColor {
    /// Glow-sticker green-yellow. Decorative and for the "lit night" state.
    static let starGlow = Color(hex: 0xE4F5A8)
    /// An unlit sticker in daylight: barely there.
    static let starUnlit = Color(hex: 0x3A4685)
}

/// A soft, rounded five-point star, like a sticker.
public struct HBStarShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.48
        var path = Path()
        for index in 0..<10 {
            let radius = index.isMultiple(of: 2) ? outer : inner
            let angle = (Double(index) * .pi / 5) - .pi / 2
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius,
                                y: center.y + CGFloat(sin(angle)) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// One glow-sticker star.
public struct HBStar: View {
    let size: CGFloat
    let isLit: Bool

    public init(size: CGFloat = 18, isLit: Bool = true) {
        self.size = size
        self.isLit = isLit
    }

    public var body: some View {
        HBStarShape()
            .fill(isLit ? HBColor.starGlow : HBColor.starUnlit)
            .frame(width: size, height: size)
            .shadow(color: isLit ? HBColor.starGlow.opacity(0.7) : .clear, radius: size * 0.35)
            .accessibilityHidden(true)
    }
}

/// A scattered ceiling of glow stars for backgrounds. Positions are fixed per `seed`
/// so screens don't reshuffle. Twinkles gently unless Reduce Motion is on.
public struct HBStarField: View {
    let count: Int
    let seed: UInt64
    let opacity: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var twinkle = false

    public init(count: Int = 14, seed: UInt64 = 7, opacity: Double = 0.55) {
        self.count = count
        self.seed = seed
        self.opacity = opacity
    }

    public var body: some View {
        GeometryReader { geo in
            ForEach(stars) { star in
                HBStar(size: star.size)
                    .opacity(opacity * (twinkle && star.twinkles ? 0.45 : 1))
                    .rotationEffect(.degrees(star.rotation))
                    .position(x: star.x * geo.size.width, y: star.y * geo.size.height)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { twinkle = true }
        }
    }

    private struct Star: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let rotation: Double
        let twinkles: Bool
    }

    private var stars: [Star] {
        var generator = SeededGenerator(seed: seed)
        return (0..<count).map { index in
            Star(id: index,
                 x: CGFloat.random(in: 0.04...0.96, using: &generator),
                 y: CGFloat.random(in: 0.02...0.98, using: &generator),
                 size: CGFloat.random(in: 6...16, using: &generator),
                 rotation: Double.random(in: -20...20, using: &generator),
                 twinkles: index.isMultiple(of: 3))
        }
    }
}

/// "Your ceiling": one star per night of the plan. Each logged night lights a star.
public struct HBStarCeiling: View {
    let total: Int
    let lit: Int

    public init(total: Int = 30, lit: Int) {
        self.total = total
        self.lit = min(lit, total)
    }

    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: HBSpacing.xs), count: 6),
                  spacing: HBSpacing.sm) {
            ForEach(0..<total, id: \.self) { index in
                HBStar(size: 22, isLit: index < lit)
                    .rotationEffect(.degrees(Double((index * 37) % 30) - 15))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(lit) of \(total) nights lit")
    }
}

/// Small deterministic random generator so star layouts are stable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
