import Foundation

/// Mark dropped when routeX crosses a quartile (25, 50, or 75).
/// Append-only. A quartile is never dropped twice on the same expedition.
struct Buoy: Identifiable, Equatable, Sendable {
    var id: UUID
    var expeditionId: UUID
    /// 25, 50, or 75.
    var quartile: Int

    init(id: UUID = UUID(), expeditionId: UUID, quartile: Int) {
        self.id = id
        self.expeditionId = expeditionId
        self.quartile = quartile
    }
}
