import Foundation

/// Append-only record that the reader recalibrated the landfall date.
/// The expedition row holds the new date. This row is the history.
struct SetMark: Identifiable, Equatable, Sendable {
    var id: UUID
    var expeditionId: UUID
    var dayKey: Int
    var previousLandfallDayKey: Int
    var revisedLandfallDayKey: Int

    init(
        id: UUID = UUID(),
        expeditionId: UUID,
        dayKey: Int,
        previousLandfallDayKey: Int,
        revisedLandfallDayKey: Int
    ) {
        self.id = id
        self.expeditionId = expeditionId
        self.dayKey = dayKey
        self.previousLandfallDayKey = previousLandfallDayKey
        self.revisedLandfallDayKey = revisedLandfallDayKey
    }
}
