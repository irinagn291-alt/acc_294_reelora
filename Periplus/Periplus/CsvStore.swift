import Foundation

/// Disk projection of `PeriplusSnapshot`. The only type that touches `FileManager`
/// for the route. Writes are atomic. A bad decode restores `.backup` files, and
/// if those fail too the store starts empty and reports that to the reader.
/// schemaVersion is 1. routeX, driftAngle, and expectedProgress are not columns.
actor CsvStore {
    static let schemaVersion = 1

    private let directory: URL
    private let fileManager: FileManager
    private var acceptedGeneration = 0
    private var writeError: String?

    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    func load() -> (snapshot: PeriplusSnapshot, notice: LoadNotice?) {
        switch decodeFolder(directory) {
        case .missing:
            return (.empty, nil)
        case .decoded(let snapshot):
            return (snapshot, nil)
        case .failed:
            switch decodeFolder(backupDirectory()) {
            case .decoded(let snapshot):
                return (snapshot, .restoredBackup)
            case .missing, .failed:
                return (.empty, .startedEmpty)
            }
        }
    }

    func write(_ snapshot: PeriplusSnapshot, generation: Int) {
        guard generation >= acceptedGeneration else { return }
        acceptedGeneration = generation
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try preserveBackup()
            try writeFolder(snapshot, to: directory)
        } catch {
            writeError = String(describing: error)
            acceptedGeneration = max(0, generation - 1)
        }
    }

    func takeWriteError() -> String? {
        let error = writeError
        writeError = nil
        return error
    }

    func reset() {
        acceptedGeneration = 0
        do {
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
            let backup = backupDirectory()
            if fileManager.fileExists(atPath: backup.path) {
                try fileManager.removeItem(at: backup)
            }
        } catch {
            writeError = String(describing: error)
        }
    }

    private func backupDirectory() -> URL {
        directory.deletingLastPathComponent().appendingPathComponent(directory.lastPathComponent + ".backup", isDirectory: true)
    }

    private func preserveBackup() throws {
        let backup = backupDirectory()
        guard fileManager.fileExists(atPath: directory.path) else { return }
        if fileManager.fileExists(atPath: backup.path) {
            try fileManager.removeItem(at: backup)
        }
        try fileManager.copyItem(at: directory, to: backup)
    }

    private static let tableNames = [
        "manifest.csv",
        "volumes.csv",
        "expeditions.csv",
        "legs.csv",
        "buoys.csv",
        "setmarks.csv",
        "landfalls.csv",
    ]

    private func decodeFolder(_ folder: URL) -> FolderDecode {
        let present = Self.tableNames.contains { name in
            fileManager.fileExists(atPath: folder.appendingPathComponent(name).path)
        }
        if !present {
            return fileManager.fileExists(atPath: folder.path) ? .failed : .missing
        }
        do {
            let manifest = try rows(folder, "manifest.csv")
            guard let version = manifest.first.flatMap({ $0.first }).flatMap(Int.init) else {
                return .failed
            }
            switch version {
            case Self.schemaVersion:
                break
            default:
                return .failed
            }
            let volumes = try volumes(from: try rows(folder, "volumes.csv"))
            let expeditions = try expeditions(from: try rows(folder, "expeditions.csv"))
            let legs = try legs(from: try rows(folder, "legs.csv"))
            let buoys = try buoys(from: try rows(folder, "buoys.csv"))
            let setMarks = try setMarks(from: try rows(folder, "setmarks.csv"))
            let landfalls = try landfalls(from: try rows(folder, "landfalls.csv"))
            return .decoded(PeriplusSnapshot(
                volumes: volumes,
                expeditions: expeditions,
                legs: legs,
                buoys: buoys,
                setMarks: setMarks,
                landfalls: landfalls
            ))
        } catch {
            return .failed
        }
    }

    private func writeFolder(_ snapshot: PeriplusSnapshot, to folder: URL) throws {
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try write(name: "manifest.csv", rows: [[String(Self.schemaVersion)]], to: folder)
        try write(name: "volumes.csv", rows: snapshot.volumes.map { volume in
            [
                volume.id.uuidString,
                volume.title,
                volume.author,
                volume.isbn,
                String(volume.totalPages),
            ]
        }, to: folder)
        try write(name: "expeditions.csv", rows: snapshot.expeditions.map { expedition in
            [
                expedition.id.uuidString,
                expedition.volumeId.uuidString,
                String(expedition.baseDayKey),
                String(expedition.landfallDayKey),
            ]
        }, to: folder)
        try write(name: "legs.csv", rows: snapshot.legs.map { leg in
            [leg.id.uuidString, leg.expeditionId.uuidString, String(leg.dayKey), String(leg.pages)]
        }, to: folder)
        try write(name: "buoys.csv", rows: snapshot.buoys.map { buoy in
            [buoy.id.uuidString, buoy.expeditionId.uuidString, String(buoy.quartile)]
        }, to: folder)
        try write(name: "setmarks.csv", rows: snapshot.setMarks.map { mark in
            [
                mark.id.uuidString,
                mark.expeditionId.uuidString,
                String(mark.dayKey),
                String(mark.previousLandfallDayKey),
                String(mark.revisedLandfallDayKey),
            ]
        }, to: folder)
        try write(name: "landfalls.csv", rows: snapshot.landfalls.map { landfall in
            [landfall.id.uuidString, landfall.expeditionId.uuidString, String(landfall.dayKey)]
        }, to: folder)
    }

    private func write(name: String, rows: [[String]], to folder: URL) throws {
        var lines = ["schemaVersion,\(Self.schemaVersion)"]
        lines.append(contentsOf: rows.map { $0.map(Self.escape).joined(separator: ",") })
        let text = lines.joined(separator: "\n") + "\n"
        guard let data = text.data(using: .utf8) else { throw CsvIssue.corrupt }
        let url = folder.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
    }

    private func rows(_ folder: URL, _ name: String) throws -> [[String]] {
        let url = folder.appendingPathComponent(name)
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw CsvIssue.corrupt
        }
        guard let text = String(data: data, encoding: .utf8) else { throw CsvIssue.corrupt }
        var parsed = Self.parse(text)
        guard let header = parsed.first, header.count >= 2, header[0] == "schemaVersion" else {
            throw CsvIssue.corrupt
        }
        switch Int(header[1]) {
        case Self.schemaVersion:
            break
        default:
            throw CsvIssue.corrupt
        }
        parsed.removeFirst()
        return parsed.filter { !$0.isEmpty && !($0.count == 1 && $0[0].isEmpty) }
    }

    private func volumes(from rows: [[String]]) throws -> [Volume] {
        try rows.map { row in
            guard row.count == 5, let id = UUID(uuidString: row[0]), let pages = Int(row[4]), pages > 0 else {
                throw CsvIssue.corrupt
            }
            return Volume(id: id, title: row[1], author: row[2], isbn: row[3], totalPages: pages)
        }
    }

    private func expeditions(from rows: [[String]]) throws -> [Expedition] {
        try rows.map { row in
            guard row.count == 4,
                  let id = UUID(uuidString: row[0]),
                  let volumeId = UUID(uuidString: row[1]),
                  let base = Int(row[2]),
                  let landfall = Int(row[3]) else { throw CsvIssue.corrupt }
            return Expedition(id: id, volumeId: volumeId, baseDayKey: base, landfallDayKey: landfall)
        }
    }

    private func legs(from rows: [[String]]) throws -> [Leg] {
        try rows.map { row in
            guard row.count == 4,
                  let id = UUID(uuidString: row[0]),
                  let expeditionId = UUID(uuidString: row[1]),
                  let day = Int(row[2]),
                  let pages = Int(row[3]) else { throw CsvIssue.corrupt }
            return Leg(id: id, expeditionId: expeditionId, dayKey: day, pages: pages)
        }
    }

    private func buoys(from rows: [[String]]) throws -> [Buoy] {
        try rows.map { row in
            guard row.count == 3,
                  let id = UUID(uuidString: row[0]),
                  let expeditionId = UUID(uuidString: row[1]),
                  let quartile = Int(row[2]) else { throw CsvIssue.corrupt }
            return Buoy(id: id, expeditionId: expeditionId, quartile: quartile)
        }
    }

    private func setMarks(from rows: [[String]]) throws -> [SetMark] {
        try rows.map { row in
            guard row.count == 5,
                  let id = UUID(uuidString: row[0]),
                  let expeditionId = UUID(uuidString: row[1]),
                  let day = Int(row[2]),
                  let previous = Int(row[3]),
                  let revised = Int(row[4]) else { throw CsvIssue.corrupt }
            return SetMark(
                id: id,
                expeditionId: expeditionId,
                dayKey: day,
                previousLandfallDayKey: previous,
                revisedLandfallDayKey: revised
            )
        }
    }

    private func landfalls(from rows: [[String]]) throws -> [Landfall] {
        try rows.map { row in
            guard row.count == 3,
                  let id = UUID(uuidString: row[0]),
                  let expeditionId = UUID(uuidString: row[1]),
                  let day = Int(row[2]) else { throw CsvIssue.corrupt }
            return Landfall(id: id, expeditionId: expeditionId, dayKey: day)
        }
    }

    static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if inQuotes {
                if character == "\"" {
                    let next = text.index(after: index)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else if character == "\"" {
                inQuotes = true
            } else if character == "," {
                row.append(field)
                field = ""
            } else if character == "\n" {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else if character == "\r" {
                // ignore
            } else {
                field.append(character)
            }
            index = text.index(after: index)
        }
        if inQuotes {
            return []
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        return rows
    }
}

private enum FolderDecode {
    case missing
    case decoded(PeriplusSnapshot)
    case failed
}

private enum CsvIssue: Error {
    case corrupt
}
