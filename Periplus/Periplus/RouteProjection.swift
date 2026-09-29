import Foundation

/// Derived bearing of one expedition. Nothing in this type is written to disk.
/// routeX is cumulative pages divided by the volume total, which is also
/// lastEndPage / total. driftAngle is (expectedProgress − routeX) × 45°, clamped
/// from 0 to 45. expectedProgress is elapsed calendar days divided by planned days.
/// An idle day raises expectedProgress and therefore driftAngle, and the map
/// curls the polyline by that angle.
struct RouteProjection: Equatable, Sendable {
    var lastEndPage: Int
    var routeX: Double
    var elapsedDays: Int
    var plannedDays: Int
    var expectedProgress: Double
    var driftAngle: Double

    static let capDegrees = 45.0
    static let quartiles = [25, 50, 75]

    static func project(
        totalPages: Int,
        legs: [Leg],
        baseDayKey: Int,
        landfallDayKey: Int,
        today: Int,
        calendar: Calendar = .current
    ) -> RouteProjection {
        let summed = legs.reduce(0) { $0 + max(0, $1.pages) }
        let endPage = max(0, summed)
        let cappedEnd = totalPages > 0 ? min(endPage, totalPages) : 0
        let routeX = totalPages > 0 ? Double(cappedEnd) / Double(totalPages) : 0
        let elapsed = max(0, DayKey.span(from: baseDayKey, to: today, calendar: calendar) ?? 0)
        let planned = max(1, DayKey.span(from: baseDayKey, to: landfallDayKey, calendar: calendar) ?? 1)
        let expected = Double(elapsed) / Double(planned)
        let raw = (expected - routeX) * capDegrees
        let drift = min(capDegrees, max(0, raw))
        return RouteProjection(
            lastEndPage: cappedEnd,
            routeX: routeX,
            elapsedDays: elapsed,
            plannedDays: planned,
            expectedProgress: expected,
            driftAngle: drift
        )
    }

    var logRefused: Bool {
        driftAngle >= Self.capDegrees - 0.000_001
    }

    var driftIsClear: Bool {
        driftAngle <= 0.000_001
    }

    var hasArrived: Bool {
        routeX >= 1 - 0.000_001 && driftIsClear
    }

    static func crossedQuartiles(from previous: Double, to next: Double) -> [Int] {
        quartiles.filter { mark in
            let threshold = Double(mark) / 100
            return previous < threshold && next >= threshold
        }
    }

    /// Landfall day that brings expectedProgress onto routeX.
    /// Planned days are the least whole count at least elapsed / routeX.
    /// When that ratio is already integral, expected progress equals routeX.
    /// Otherwise the next whole day keeps expected progress at or under routeX,
    /// which clamps drift to zero. Returns nil when routeX is still 0, because
    /// no finite plan makes elapsed / planned equal 0 once days have passed.
    static func revisedLandfallDayKey(
        baseDayKey: Int,
        today: Int,
        routeX: Double,
        calendar: Calendar = .current
    ) -> Int? {
        guard routeX > 0.000_001 else { return nil }
        let elapsed = max(0, DayKey.span(from: baseDayKey, to: today, calendar: calendar) ?? 0)
        guard elapsed > 0 else { return nil }
        let exact = Double(elapsed) / routeX
        var planned = max(1, Int(exact.rounded(.up)))
        if Double(elapsed) / Double(planned) > routeX {
            planned += 1
        }
        return DayKey.adding(days: planned, to: baseDayKey, calendar: calendar)
    }
}
