import Foundation

/// Fold of Moored, Underway, and Landed over append-only legs, buoys, set marks,
/// and landfalls. Moored means no expedition is open. Open is refused while one
/// is already Underway. Landfall folds Underway to Landed.
enum ExpeditionPhase: Equatable, Sendable {
    case moored
    case underway(Expedition)
    case landed(Expedition)
}

enum RouteRefusal: Equatable, Sendable, Error {
    case noExpedition
    case alreadyUnderway
    case driftCapped
    case driftAlreadyZero
    case pagesNotPositive
    case pagesExceedRemaining
    case volumeMissing
    case landfallNotAfterBase
    case cannotRecalibrate
    case alreadyLanded
}

enum ExpeditionFold {
    static func phase(in snapshot: PeriplusSnapshot) -> ExpeditionPhase {
        guard let expedition = snapshot.expeditions.last else { return .moored }
        if snapshot.landfalls.contains(where: { $0.expeditionId == expedition.id }) {
            return .landed(expedition)
        }
        return .underway(expedition)
    }

    static func underway(_ snapshot: PeriplusSnapshot) -> Expedition? {
        if case .underway(let expedition) = phase(in: snapshot) {
            return expedition
        }
        return nil
    }

    static func projection(
        _ snapshot: PeriplusSnapshot,
        expedition: Expedition,
        today: Int,
        calendar: Calendar = .current
    ) -> RouteProjection? {
        guard let volume = snapshot.volumes.first(where: { $0.id == expedition.volumeId }) else {
            return nil
        }
        let legs = snapshot.legs.filter { $0.expeditionId == expedition.id }
        return RouteProjection.project(
            totalPages: volume.totalPages,
            legs: legs,
            baseDayKey: expedition.baseDayKey,
            landfallDayKey: expedition.landfallDayKey,
            today: today,
            calendar: calendar
        )
    }

    static func open(
        _ snapshot: PeriplusSnapshot,
        volumeId: UUID,
        baseDayKey: Int,
        landfallDayKey: Int,
        calendar: Calendar = .current
    ) -> Result<PeriplusSnapshot, RouteRefusal> {
        if case .underway = phase(in: snapshot) {
            return .failure(.alreadyUnderway)
        }
        guard snapshot.volumes.contains(where: { $0.id == volumeId }) else {
            return .failure(.volumeMissing)
        }
        guard let span = DayKey.span(from: baseDayKey, to: landfallDayKey, calendar: calendar), span >= 1 else {
            return .failure(.landfallNotAfterBase)
        }
        var next = snapshot
        next.expeditions.append(
            Expedition(volumeId: volumeId, baseDayKey: baseDayKey, landfallDayKey: landfallDayKey)
        )
        return .success(next)
    }

    /// Log is the home verb. It appends a leg, stacks on the same day key,
    /// drops a buoy at each quartile crossed, and appends a landfall when the
    /// route is finished on a clear drift.
    static func log(
        _ snapshot: PeriplusSnapshot,
        pages: Int,
        dayKey: Int,
        calendar: Calendar = .current
    ) -> Result<PeriplusSnapshot, RouteRefusal> {
        guard pages > 0 else { return .failure(.pagesNotPositive) }
        guard let expedition = underway(snapshot) else {
            if case .landed = phase(in: snapshot) {
                return .failure(.alreadyLanded)
            }
            return .failure(.noExpedition)
        }
        guard let volume = snapshot.volumes.first(where: { $0.id == expedition.volumeId }) else {
            return .failure(.volumeMissing)
        }
        guard let before = projection(snapshot, expedition: expedition, today: dayKey, calendar: calendar) else {
            return .failure(.volumeMissing)
        }
        if before.logRefused {
            return .failure(.driftCapped)
        }
        let remaining = volume.totalPages - before.lastEndPage
        guard pages <= remaining else { return .failure(.pagesExceedRemaining) }

        var next = snapshot
        next.legs.append(Leg(expeditionId: expedition.id, dayKey: dayKey, pages: pages))
        guard let after = projection(next, expedition: expedition, today: dayKey, calendar: calendar) else {
            return .failure(.volumeMissing)
        }
        let marks = RouteProjection.crossedQuartiles(from: before.routeX, to: after.routeX)
        for mark in marks where !next.buoys.contains(where: { $0.expeditionId == expedition.id && $0.quartile == mark }) {
            next.buoys.append(Buoy(expeditionId: expedition.id, quartile: mark))
        }
        if after.hasArrived {
            next.landfalls.append(Landfall(expeditionId: expedition.id, dayKey: dayKey))
        }
        return .success(next)
    }

    /// Set is refused while drift is already zero. Otherwise it pushes the
    /// landfall day until expected progress matches routeX, which clears drift.
    static func set(
        _ snapshot: PeriplusSnapshot,
        dayKey: Int,
        calendar: Calendar = .current
    ) -> Result<PeriplusSnapshot, RouteRefusal> {
        guard let expedition = underway(snapshot) else {
            if case .landed = phase(in: snapshot) {
                return .failure(.alreadyLanded)
            }
            return .failure(.noExpedition)
        }
        guard let before = projection(snapshot, expedition: expedition, today: dayKey, calendar: calendar) else {
            return .failure(.volumeMissing)
        }
        if before.driftIsClear {
            return .failure(.driftAlreadyZero)
        }
        guard let revised = RouteProjection.revisedLandfallDayKey(
            baseDayKey: expedition.baseDayKey,
            today: dayKey,
            routeX: before.routeX,
            calendar: calendar
        ) else {
            return .failure(.cannotRecalibrate)
        }
        var next = snapshot
        guard let index = next.expeditions.firstIndex(where: { $0.id == expedition.id }) else {
            return .failure(.noExpedition)
        }
        let previous = next.expeditions[index].landfallDayKey
        next.expeditions[index].landfallDayKey = revised
        next.setMarks.append(
            SetMark(
                expeditionId: expedition.id,
                dayKey: dayKey,
                previousLandfallDayKey: previous,
                revisedLandfallDayKey: revised
            )
        )
        if let after = projection(next, expedition: next.expeditions[index], today: dayKey, calendar: calendar),
           after.hasArrived {
            next.landfalls.append(Landfall(expeditionId: expedition.id, dayKey: dayKey))
        }
        return .success(next)
    }
}
