import Foundation

/// In-memory source of truth. CSV files are a projection of this value.
/// Derived route figures are not fields here.
struct PeriplusSnapshot: Equatable, Sendable {
    var volumes: [Volume]
    var expeditions: [Expedition]
    var legs: [Leg]
    var buoys: [Buoy]
    var setMarks: [SetMark]
    var landfalls: [Landfall]

    init(
        volumes: [Volume] = [],
        expeditions: [Expedition] = [],
        legs: [Leg] = [],
        buoys: [Buoy] = [],
        setMarks: [SetMark] = [],
        landfalls: [Landfall] = []
    ) {
        self.volumes = volumes
        self.expeditions = expeditions
        self.legs = legs
        self.buoys = buoys
        self.setMarks = setMarks
        self.landfalls = landfalls
    }

    static let empty = PeriplusSnapshot()
}

enum LoadNotice: Equatable, Sendable {
    case restoredBackup
    case startedEmpty
}
