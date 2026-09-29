import SpriteKit
import SwiftUI

/// The route a stranger can see without waiting on a scene snapshot.
struct RoutePlate: View {
    var routeX: Double
    var driftAngle: Double
    var quartiles: [Int]

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let height = max(geo.size.height, 1)
            let inset = min(width, height) * 0.14
            let midY = height * 0.55
            let start = CGPoint(x: inset, y: midY)
            let end = CGPoint(x: width - inset, y: midY)
            let span = end.x - start.x
            let progress = max(0, min(1, routeX))
            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                .stroke(DesignTokens.muted.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                routePath(start: start, span: span, progress: progress)
                    .stroke(DesignTokens.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-driftAngle), anchor: unitAnchor(start, in: geo.size))
                ForEach(quartiles, id: \.self) { mark in
                    Circle()
                        .fill(DesignTokens.ink)
                        .overlay { Circle().strokeBorder(DesignTokens.accent, lineWidth: 2) }
                        .frame(width: 18, height: 18)
                        .position(point(start: start, span: span, fraction: CGFloat(mark) / 100, degrees: driftAngle))
                }
                Text("True bearing")
                    .font(RouteMeasure.mono(.caption, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                    .padding(RouteMeasure.row)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Route on this voyage")
    }

    private func routePath(start: CGPoint, span: CGFloat, progress: CGFloat) -> Path {
        Path { path in
            path.move(to: start)
            path.addLine(to: CGPoint(x: start.x + span * progress, y: start.y))
            if progress < 1 {
                path.move(to: CGPoint(x: start.x + span * progress, y: start.y))
                path.addLine(to: CGPoint(x: start.x + span, y: start.y))
            }
        }
    }

    private func unitAnchor(_ point: CGPoint, in size: CGSize) -> UnitPoint {
        UnitPoint(x: point.x / max(size.width, 1), y: point.y / max(size.height, 1))
    }

    private func point(start: CGPoint, span: CGFloat, fraction: CGFloat, degrees: Double) -> CGPoint {
        let raw = CGPoint(x: start.x + span * fraction, y: start.y)
        let radians = -degrees * .pi / 180
        let dx = raw.x - start.x
        let dy = raw.y - start.y
        return CGPoint(
            x: start.x + dx * cos(radians) - dy * sin(radians),
            y: start.y + dx * sin(radians) + dy * cos(radians)
        )
    }
}

/// SpriteKit host for the home route. One scene, updated in place.
struct RouteCanvas: UIViewRepresentable {
    var routeX: Double
    var driftAngle: Double
    var quartiles: [Int]
    var reduceMotion: Bool

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = false
        view.ignoresSiblingOrder = true
        let scene = CyanotypeScene(size: CGSize(width: 320, height: 240))
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        guard let scene = uiView.scene as? CyanotypeScene else { return }
        let bounds = uiView.bounds
        if bounds.width > 1, bounds.height > 1, scene.size != bounds.size {
            scene.size = bounds.size
        }
        scene.render(
            routeX: CGFloat(routeX),
            driftDegrees: CGFloat(driftAngle),
            quartiles: quartiles,
            instant: reduceMotion
        )
    }
}
