import SwiftUI

/// One accessor each for space, radius, type, and motion.
/// Face is SF Mono, reached as the system monospaced design.
/// Views never spell a raw point size for these roles.
enum RouteMeasure {
    static let unit: CGFloat = 8

    static var tight: CGFloat { unit }
    static var row: CGFloat { unit * 2 }
    static var pad: CGFloat { unit * 3 }
    static var band: CGFloat { unit * 4 }
    static var measure: CGFloat { unit * 56 }

    static let card: CGFloat = 32
    static let chip: CGFloat = 16
    static let hairline: CGFloat = 1

    static let settle = Animation.easeOut(duration: 0.18)

    /// Six Dynamic Type steps. Views do not pick a raw text style.
    enum Step {
        case display
        case title
        case headline
        case body
        case caption
        case micro
    }

    static func mono(_ step: Step, weight: Font.Weight = .regular) -> Font {
        let style: Font.TextStyle
        switch step {
        case .display: style = .largeTitle
        case .title: style = .title2
        case .headline: style = .title3
        case .body: style = .body
        case .caption: style = .callout
        case .micro: style = .footnote
        }
        return .system(style, design: .monospaced).weight(weight)
    }

    static let pages: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static let angle: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static func pagesText(_ value: Int) -> String {
        pages.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func angleText(_ value: Double) -> String {
        angle.string(from: NSNumber(value: value)) ?? "0"
    }

    static func dayText(_ key: Int) -> String {
        guard let date = DayKey.date(from: key) else { return pagesText(key) }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

struct HairlinePlate: ViewModifier {
    var radius: CGFloat = RouteMeasure.card

    func body(content: Content) -> some View {
        content
            .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(DesignTokens.muted.opacity(0.55), lineWidth: RouteMeasure.hairline)
            }
    }
}

extension View {
    func hairlinePlate(radius: CGFloat = RouteMeasure.card) -> some View {
        modifier(HairlinePlate(radius: radius))
    }
}
