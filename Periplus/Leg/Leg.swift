import Foundation

/// Append-only waypoint on the route. `pages` is the increment logged that day,
/// not a running total. Same-day legs stack. The end page is the sum.
struct Leg: Identifiable, Equatable, Sendable {
    var id: UUID
    var expeditionId: UUID
    var dayKey: Int
    var pages: Int

    init(id: UUID = UUID(), expeditionId: UUID, dayKey: Int, pages: Int) {
        self.id = id
        self.expeditionId = expeditionId
        self.dayKey = dayKey
        self.pages = pages
    }
}
