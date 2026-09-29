import SwiftUI
import UIKit

/// Named colours from the asset catalog. Views use these properties only.
/// background #34373D, surface #42454D, ink #F4F4F6, accent #6D95E3, muted #B6BAC3.
enum DesignTokens {
    static let bg = Color("background")
    static let surface = Color("surface")
    static let ink = Color("ink")
    static let accent = Color("accent")
    static let muted = Color("muted")

    static var uiBackground: UIColor { named("background") }
    static var uiSurface: UIColor { named("surface") }
    static var uiInk: UIColor { named("ink") }
    static var uiAccent: UIColor { named("accent") }
    static var uiMuted: UIColor { named("muted") }

    private static func named(_ name: String) -> UIColor {
        UIColor(named: name) ?? .darkGray
    }
}
