import Foundation

/// One voyage from Base toward a Landfall date, bound to a single volume.
/// The stored landfall day is the current plan. Set rewrites that day.
/// routeX and driftAngle are never stored here. They are folded from legs.
struct Expedition: Identifiable, Equatable, Sendable {
    var id: UUID
    var volumeId: UUID
    var baseDayKey: Int
    var landfallDayKey: Int

    init(id: UUID = UUID(), volumeId: UUID, baseDayKey: Int, landfallDayKey: Int) {
        self.id = id
        self.volumeId = volumeId
        self.baseDayKey = baseDayKey
        self.landfallDayKey = landfallDayKey
    }
}
