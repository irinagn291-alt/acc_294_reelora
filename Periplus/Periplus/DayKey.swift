import Foundation

/// Calendar day identity for legs and landfalls.
/// Keys are `YYYYMMDD` integers taken from `Calendar.startOfDay`, so daylight-saving
/// edges stay on the reader's local day. Route pace is counted in these keys, never
/// in raw timestamps.
enum DayKey: Sendable {
    static func make(from date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func date(from key: Int, calendar: Calendar = .current) -> Date? {
        let year = key / 10_000
        let month = (key / 100) % 100
        let day = key % 100
        guard year > 0, (1...12).contains(month), (1...31).contains(day) else { return nil }
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        guard let resolved = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: resolved)
    }

    /// Whole calendar days from `start` to `end`. Negative when `end` is earlier.
    static func span(from start: Int, to end: Int, calendar: Calendar = .current) -> Int? {
        guard let startDate = date(from: start, calendar: calendar),
              let endDate = date(from: end, calendar: calendar) else { return nil }
        return calendar.dateComponents([.day], from: startDate, to: endDate).day
    }

    static func adding(days: Int, to key: Int, calendar: Calendar = .current) -> Int? {
        guard let date = date(from: key, calendar: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: date) else { return nil }
        return make(from: shifted, calendar: calendar)
    }
}
