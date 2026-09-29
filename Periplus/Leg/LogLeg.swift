import Foundation

/// Home verb. Views call this through the store. The fold owns the rules.
enum LogLeg {
    static func commit(
        snapshot: PeriplusSnapshot,
        pages: Int,
        dayKey: Int,
        calendar: Calendar = .current
    ) -> Result<PeriplusSnapshot, RouteRefusal> {
        ExpeditionFold.log(snapshot, pages: pages, dayKey: dayKey, calendar: calendar)
    }
}
