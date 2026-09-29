import Foundation

/// Append-only arrival. Written only when routeX has reached 1 and driftAngle is 0,
/// which folds Underway into Landed.
struct Landfall: Identifiable, Equatable, Sendable {
    var id: UUID
    var expeditionId: UUID
    var dayKey: Int

    init(id: UUID = UUID(), expeditionId: UUID, dayKey: Int) {
        self.id = id
        self.expeditionId = expeditionId
        self.dayKey = dayKey
    }
}
