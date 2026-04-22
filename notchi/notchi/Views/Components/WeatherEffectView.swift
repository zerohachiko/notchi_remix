import SwiftUI

/// Composite weather effects overlay for the grass island.
struct WeatherEffectView: View {
    let condition: WeatherCondition
    let isNight: Bool

    var body: some View {
        ZStack {
            // Weather-specific tint (rendered as normal color fill)
            weatherTint

            // Night overlay
            if isNight {
                nightOverlay
            }

            // Particle effects
            switch condition {
            case .rainy:
                RainEffectView()
            case .snowy:
                SnowEffectView()
            case .thunderstorm:
                ThunderstormEffectView()
            case .foggy:
                FogEffectView()
            case .sunny where !isNight:
                SunshineEffectView()
            case .cloudy:
                CloudShadowView()
            case .partlyCloudy where !isNight:
                SunshineEffectView(intensity: 0.6)
            default:
                EmptyView()
            }

            // Night stars
            if isNight && (condition == .sunny || condition == .partlyCloudy) {
                StarsEffectView()
            }
        }
        .allowsHitTesting(false)
    }

    private var weatherTint: some View {
        let tint = condition.grassTintColor
        return Color(red: tint.red, green: tint.green, blue: tint.blue)
            .opacity(tint.opacity)
    }

    private var nightOverlay: some View {
        let tint = WeatherCondition.nightTint
        return Color(red: tint.red, green: tint.green, blue: tint.blue)
            .opacity(tint.opacity)
    }
}

// MARK: - Rain Effect (TimelineView driven)

private struct RainEffectView: View {
    private let dropCount = 35

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                for i in 0..<dropCount {
                    let seed = Double(i)
                    let x = stableRandom(seed: seed, range: 0..<size.width)
                    let speed = stableRandom(seed: seed + 200, range: 80..<160)
                    let phase = stableRandom(seed: seed + 100, range: 0..<1)
                    let y = ((time * speed + phase * size.height).truncatingRemainder(dividingBy: size.height + 20)) - 10

                    let length: CGFloat = stableRandom(seed: seed + 300, range: 10..<20)
                    let alpha = stableRandom(seed: seed + 400, range: 0.25..<0.6)

                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x - 1.5, y: y + length))

                    context.stroke(path, with: .color(.white.opacity(alpha)), lineWidth: 1.2)
                }
            }
        }
    }
}

// MARK: - Snow Effect (TimelineView driven)

private struct SnowEffectView: View {
    private let flakeCount = 25

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                for i in 0..<flakeCount {
                    let seed = Double(i)
                    let baseX = stableRandom(seed: seed, range: 0..<size.width)
                    let speed = stableRandom(seed: seed + 200, range: 20..<50)
                    let phase = stableRandom(seed: seed + 100, range: 0..<1)
                    let y = ((time * speed + phase * size.height).truncatingRemainder(dividingBy: size.height + 20)) - 10

                    let swayAmount = stableRandom(seed: seed + 500, range: 6..<15)
                    let swaySpeed = stableRandom(seed: seed + 600, range: 0.5..<1.5)
                    let sway = sin(time * swaySpeed + seed) * swayAmount
                    let x = baseX + sway

                    let radius: CGFloat = stableRandom(seed: seed + 300, range: 1.5..<4.0)
                    let alpha = stableRandom(seed: seed + 400, range: 0.4..<0.85)

                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }
            }
        }
    }
}

// MARK: - Thunderstorm Effect (rain + periodic flash)

private struct ThunderstormEffectView: View {
    @State private var flashOpacity: Double = 0

    var body: some View {
        ZStack {
            RainEffectView()

            Color.white.opacity(flashOpacity)
        }
        .task {
            while !Task.isCancelled {
                let delay = Double.random(in: 2.5...6.0)
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { break }
                withAnimation(.easeIn(duration: 0.04)) { flashOpacity = 0.5 }
                try? await Task.sleep(for: .milliseconds(70))
                withAnimation(.easeOut(duration: 0.12)) { flashOpacity = 0 }
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeIn(duration: 0.04)) { flashOpacity = 0.3 }
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(.easeOut(duration: 0.25)) { flashOpacity = 0 }
            }
        }
    }
}

// MARK: - Fog Effect (animated floating layers)

private struct FogEffectView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                fogBand(width: w, y: h * 0.2, alpha: 0.2, dx: phase * 25, blur: 18)
                fogBand(width: w, y: h * 0.45, alpha: 0.25, dx: -phase * 18, blur: 20)
                fogBand(width: w, y: h * 0.7, alpha: 0.3, dx: phase * 12, blur: 22)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }

    private func fogBand(width: CGFloat, y: CGFloat, alpha: Double, dx: CGFloat, blur: CGFloat) -> some View {
        Ellipse()
            .fill(Color.white.opacity(alpha))
            .frame(width: width * 1.6, height: 40)
            .blur(radius: blur)
            .offset(x: dx, y: y)
    }
}

// MARK: - Sunshine Effect (warm glow)

private struct SunshineEffectView: View {
    var intensity: Double = 1.0
    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.92, blue: 0.5).opacity((pulse ? 0.25 : 0.15) * intensity),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: geo.size.width * 0.7
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Cloud Shadow (drifting dark patches)

private struct CloudShadowView: View {
    @State private var drift: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: w * 0.5, height: h * 0.35)
                    .blur(radius: 20)
                    .offset(x: -w * 0.15 + drift * 40, y: h * 0.2)

                Ellipse()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: w * 0.4, height: h * 0.3)
                    .blur(radius: 18)
                    .offset(x: w * 0.2 - drift * 30, y: h * 0.5)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                drift = 1
            }
        }
    }
}

// MARK: - Stars Effect (TimelineView driven twinkle)

private struct StarsEffectView: View {
    private let starCount = 18

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 10)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                for i in 0..<starCount {
                    let seed = Double(i)
                    let x = stableRandom(seed: seed + 500, range: 4..<(size.width - 4))
                    let y = stableRandom(seed: seed + 600, range: 4..<(size.height * 0.55))
                    let radius: CGFloat = stableRandom(seed: seed + 700, range: 1.0..<2.5)
                    let twinkleSpeed = stableRandom(seed: seed + 900, range: 0.8..<2.5)
                    let baseAlpha = stableRandom(seed: seed + 800, range: 0.4..<0.9)
                    let alpha = baseAlpha * (0.5 + 0.5 * CGFloat(sin(time * twinkleSpeed + seed * 3)))

                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }
            }
        }
    }
}

// MARK: - Deterministic pseudo-random (seeded, stable across frames)

private func stableRandom(seed: Double, range: Range<CGFloat>) -> CGFloat {
    let hash = sin(seed * 12.9898 + seed * 78.233) * 43758.5453
    let normalized = hash - floor(hash)
    return range.lowerBound + CGFloat(normalized) * (range.upperBound - range.lowerBound)
}
