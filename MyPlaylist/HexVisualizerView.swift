import SwiftUI

struct HexVisualizerView: View {
    @EnvironmentObject private var player: AudioPlayer

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: player.state != .playing)) { timeline in
            Canvas { context, size in
                let t     = timeline.date.timeIntervalSinceReferenceDate
                let level = Double(player.audioLevel)
                draw(context: context, size: size, time: t, level: level)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }

    // MARK: - Drawing

    private func draw(context: GraphicsContext, size: CGSize, time: Double, level: Double) {
        let center  = CGPoint(x: size.width / 2, y: size.height / 2)
        let baseR   = 20.0
        let ballR   = baseR + level * 24.0   // pulses hard on beats
        let maxLine = 64.0
        let count   = 48

        // Hue drifts slowly: cyan → blue-purple → back (never jarring)
        let hue      = 0.50 + sin(time * 0.22) * 0.09
        let primary  = Color(hue: hue,        saturation: 1.0, brightness: 1.0)
        let glow     = Color(hue: hue + 0.13, saturation: 0.8, brightness: 1.0) // cooler purple glow

        // Whole pattern rotates gently — always feels alive
        let rotation = time * 0.09

        // --- Outer ambient ring ---
        // Expands with amplitude like a force field
        let outerR    = ballR + maxLine * 0.80 * level + 8.0
        let outerRect = CGRect(x: center.x - outerR, y: center.y - outerR,
                               width: outerR * 2, height: outerR * 2)
        context.stroke(Path(ellipseIn: outerRect),
                       with: .color(glow.opacity(0.07 + level * 0.13)), lineWidth: 8)
        context.stroke(Path(ellipseIn: outerRect),
                       with: .color(primary.opacity(0.18 * level)), lineWidth: 1.5)

        // --- Radial lines ---
        for i in 0..<count {
            let angle = Double(i) / Double(count) * 2 * .pi + rotation

            // Per-line independent oscillation → spectrum-like variation
            let v = 0.40
                + sin(Double(i) * 0.85 + time * 2.4) * 0.22
                + sin(Double(i) * 1.60 + time * 3.9) * 0.18
                + sin(Double(i) * 0.38 + time * 1.2) * 0.12
            let len = max(4.0, maxLine * level * max(0.05, v))

            let ox = cos(angle), oy = sin(angle)
            let s = CGPoint(x: center.x + ox * ballR,          y: center.y + oy * ballR)
            let e = CGPoint(x: center.x + ox * (ballR + len),  y: center.y + oy * (ballR + len))

            var line = Path()
            line.move(to: s); line.addLine(to: e)

            // Purple outer bloom → cyan mid glow → bright core → white tip
            context.stroke(line, with: .color(glow.opacity(0.12)),          lineWidth: 8)
            context.stroke(line, with: .color(primary.opacity(0.22)),       lineWidth: 4)
            context.stroke(line, with: .color(primary.opacity(0.75)),       lineWidth: 1.5)
            context.stroke(line, with: .color(.white.opacity(0.40 * level)), lineWidth: 0.8)
        }

        // --- Ball ---
        func disc(_ r: Double, _ op: Double, _ color: Color) {
            let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(op)))
        }

        // Outer glow halos
        disc(ballR + 20, 0.04, glow)
        disc(ballR + 12, 0.09, glow)
        disc(ballR +  6, 0.18, primary)
        disc(ballR,      0.62, primary)
        // Bright white core that flashes on every beat
        disc(ballR - 5,  0.22 + level * 0.55, .white)

        // Crisp ring around the ball edge
        let ringRect = CGRect(x: center.x - ballR, y: center.y - ballR,
                              width: ballR * 2, height: ballR * 2)
        context.stroke(Path(ellipseIn: ringRect),
                       with: .color(primary.opacity(0.45 + level * 0.35)), lineWidth: 1.5)
    }
}
