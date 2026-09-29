import SpriteKit
import UIKit

/// The only custom drawing surface. The polyline, quartile buoys, and drift
/// rotation live here. Sheets stay stock SwiftUI.
final class CyanotypeScene: SKScene {
    private let paper = SKSpriteNode()
    private let bearing = SKShapeNode()
    private let route = SKShapeNode()
    private let pivot = SKNode()
    private var buoyNodes: [SKShapeNode] = []

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = DesignTokens.uiBackground
        anchorPoint = CGPoint(x: 0, y: 0)
        addChild(paper)
        addChild(bearing)
        addChild(pivot)
        pivot.addChild(route)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func render(routeX: CGFloat, driftDegrees: CGFloat, quartiles: [Int], instant: Bool) {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        paper.size = CGSize(width: width, height: height)
        paper.position = CGPoint(x: width / 2, y: height / 2)
        paper.color = DesignTokens.uiSurface

        let inset = min(width, height) * 0.12
        let start = CGPoint(x: inset, y: height * 0.42)
        let end = CGPoint(x: width - inset, y: height * 0.42)
        let span = end.x - start.x

        let truePath = CGMutablePath()
        truePath.move(to: start)
        truePath.addLine(to: end)
        bearing.path = truePath
        bearing.strokeColor = DesignTokens.uiMuted.withAlphaComponent(0.45)
        bearing.lineWidth = 2
        bearing.lineCap = .round

        let local = CGMutablePath()
        local.move(to: .zero)
        let progress = max(0, min(1, routeX))
        local.addLine(to: CGPoint(x: span * progress, y: 0))
        if progress < 1 {
            local.move(to: CGPoint(x: span * progress, y: 0))
            local.addLine(to: CGPoint(x: span, y: 0))
        }
        route.path = local
        route.strokeColor = DesignTokens.uiAccent
        route.lineWidth = 7
        route.lineCap = .round
        pivot.position = start
        let radians = -driftDegrees * .pi / 180
        if instant {
            pivot.zRotation = radians
        } else {
            pivot.removeAction(forKey: "curl")
            pivot.run(.rotate(toAngle: radians, duration: 0.18, shortestUnitArc: true), withKey: "curl")
        }

        buoyNodes.forEach { $0.removeFromParent() }
        buoyNodes.removeAll()
        for mark in quartiles {
            let node = SKShapeNode(circleOfRadius: 9)
            node.fillColor = DesignTokens.uiInk
            node.strokeColor = DesignTokens.uiAccent
            node.lineWidth = 2
            node.position = CGPoint(x: span * CGFloat(mark) / 100, y: 0)
            pivot.addChild(node)
            buoyNodes.append(node)
        }
    }
}
