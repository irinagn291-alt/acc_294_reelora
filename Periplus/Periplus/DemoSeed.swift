import Foundation

/// Simulator-only opening route. One named volume, one Underway expedition,
/// four legs, one quartile buoy, routeX above zero, drift under 45 degrees
/// so Log is enabled. Never compiled into a device build.
enum DemoSeed {
    static func make(today: Int, calendar: Calendar = .current) -> PeriplusSnapshot? {
        guard let base = DayKey.adding(days: -10, to: today, calendar: calendar),
              let landfall = DayKey.adding(days: 20, to: base, calendar: calendar) else { return nil }
        let volume = Volume(title: "Northwater Atlas", author: "I. Marlow", isbn: "9780000000002", totalPages: 200)
        var snapshot = PeriplusSnapshot(volumes: [volume])
        switch ExpeditionFold.open(snapshot, volumeId: volume.id, baseDayKey: base, landfallDayKey: landfall, calendar: calendar) {
        case .failure:
            return nil
        case .success(let opened):
            snapshot = opened
        }
        let pageCounts = [20, 20, 15, 15]
        let offsets = [-8, -6, -4, -1]
        for pair in zip(pageCounts, offsets) {
            guard let day = DayKey.adding(days: pair.1, to: today, calendar: calendar) else { return nil }
            switch ExpeditionFold.log(snapshot, pages: pair.0, dayKey: day, calendar: calendar) {
            case .failure:
                return nil
            case .success(let next):
                snapshot = next
            }
        }
        return snapshot
    }
}
