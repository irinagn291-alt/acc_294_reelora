import XCTest
@testable import Periplus

final class PeriplusTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }

    func testRouteXIsCumulativePagesOverTotal() {
        let legs = [
            Leg(expeditionId: UUID(), dayKey: 20260101, pages: 30),
            Leg(expeditionId: UUID(), dayKey: 20260101, pages: 10),
            Leg(expeditionId: UUID(), dayKey: 20260102, pages: 20),
        ]
        let reading = RouteProjection.project(
            totalPages: 200,
            legs: legs,
            baseDayKey: 20260101,
            landfallDayKey: 20260121,
            today: 20260101,
            calendar: calendar
        )
        XCTAssertEqual(reading.lastEndPage, 60)
        XCTAssertEqual(reading.routeX, 0.3, accuracy: 0.000_001)
    }

    func testIdleDayIncreasesDriftAngle() {
        let legs = [Leg(expeditionId: UUID(), dayKey: 20260301, pages: 40)]
        let first = RouteProjection.project(
            totalPages: 200,
            legs: legs,
            baseDayKey: 20260301,
            landfallDayKey: 20260321,
            today: 20260305,
            calendar: calendar
        )
        let next = RouteProjection.project(
            totalPages: 200,
            legs: legs,
            baseDayKey: 20260301,
            landfallDayKey: 20260321,
            today: 20260306,
            calendar: calendar
        )
        XCTAssertEqual(first.routeX, 0.2, accuracy: 0.000_001)
        XCTAssertEqual(first.expectedProgress, 4.0 / 20.0, accuracy: 0.000_001)
        XCTAssertEqual(first.driftAngle, (first.expectedProgress - first.routeX) * 45, accuracy: 0.000_001)
        XCTAssertGreaterThan(next.driftAngle, first.driftAngle)
        XCTAssertLessThanOrEqual(next.driftAngle, 45)
    }

    func testDriftClampsAtFortyFive() {
        let reading = RouteProjection.project(
            totalPages: 100,
            legs: [],
            baseDayKey: 20260101,
            landfallDayKey: 20260111,
            today: 20260201,
            calendar: calendar
        )
        XCTAssertEqual(reading.driftAngle, 45, accuracy: 0.000_001)
        XCTAssertTrue(reading.logRefused)
    }

    func testLogEmptyPopulatedAndInvalid() throws {
        var snapshot = PeriplusSnapshot()
        XCTAssertEqual(ExpeditionFold.log(snapshot, pages: 10, dayKey: 20260401, calendar: calendar), .failure(.noExpedition))
        let volume = Volume(title: "Harbour Notes", totalPages: 100)
        snapshot.volumes = [volume]
        snapshot = try ExpeditionFold.open(
            snapshot,
            volumeId: volume.id,
            baseDayKey: 20260401,
            landfallDayKey: 20260421,
            calendar: calendar
        ).get()
        XCTAssertEqual(ExpeditionFold.log(snapshot, pages: 0, dayKey: 20260401, calendar: calendar), .failure(.pagesNotPositive))
        XCTAssertEqual(ExpeditionFold.log(snapshot, pages: -3, dayKey: 20260401, calendar: calendar), .failure(.pagesNotPositive))
        XCTAssertEqual(ExpeditionFold.log(snapshot, pages: 400, dayKey: 20260401, calendar: calendar), .failure(.pagesExceedRemaining))
        snapshot = try ExpeditionFold.log(snapshot, pages: 10, dayKey: 20260401, calendar: calendar).get()
        snapshot = try ExpeditionFold.log(snapshot, pages: 5, dayKey: 20260401, calendar: calendar).get()
        XCTAssertEqual(snapshot.legs.count, 2)
        let reading = ExpeditionFold.projection(snapshot, expedition: snapshot.expeditions[0], today: 20260401, calendar: calendar)
        XCTAssertEqual(reading?.lastEndPage, 15)
        XCTAssertEqual(reading?.routeX ?? 0, 0.15, accuracy: 0.000_001)
    }

    func testLogRefusedWhenDriftCapsUntilSetClearsIt() throws {
        let volume = Volume(title: "Slow Crossing", totalPages: 100)
        var snapshot = PeriplusSnapshot(volumes: [volume])
        snapshot = try ExpeditionFold.open(
            snapshot,
            volumeId: volume.id,
            baseDayKey: 20260101,
            landfallDayKey: 20260111,
            calendar: calendar
        ).get()
        snapshot = try ExpeditionFold.log(snapshot, pages: 40, dayKey: 20260101, calendar: calendar).get()
        XCTAssertEqual(
            ExpeditionFold.log(snapshot, pages: 1, dayKey: 20260115, calendar: calendar),
            .failure(.driftCapped)
        )
        snapshot = try ExpeditionFold.set(snapshot, dayKey: 20260115, calendar: calendar).get()
        let cleared = ExpeditionFold.projection(snapshot, expedition: snapshot.expeditions[0], today: 20260115, calendar: calendar)
        XCTAssertEqual(cleared?.driftAngle ?? 1, 0, accuracy: 0.000_001)
        XCTAssertEqual(snapshot.setMarks.count, 1)
        snapshot = try ExpeditionFold.log(snapshot, pages: 1, dayKey: 20260115, calendar: calendar).get()
        XCTAssertEqual(snapshot.legs.count, 2)
    }

    func testSetClearsDriftWhenElapsedOverRouteIsNotWholeDays() throws {
        let volume = Volume(title: "Uneven Crossing", totalPages: 100)
        var snapshot = PeriplusSnapshot(volumes: [volume])
        snapshot = try ExpeditionFold.open(
            snapshot,
            volumeId: volume.id,
            baseDayKey: 20260101,
            landfallDayKey: 20260111,
            calendar: calendar
        ).get()
        snapshot = try ExpeditionFold.log(snapshot, pages: 30, dayKey: 20260101, calendar: calendar).get()
        let capped = ExpeditionFold.projection(snapshot, expedition: snapshot.expeditions[0], today: 20260114, calendar: calendar)
        XCTAssertEqual(capped?.routeX ?? 0, 0.3, accuracy: 0.000_001)
        XCTAssertEqual(capped?.elapsedDays, 13)
        let ratio = Double(capped?.elapsedDays ?? 0) / (capped?.routeX ?? 1)
        XCTAssertGreaterThan(abs(ratio - ratio.rounded()), 0.000_001)
        XCTAssertTrue(capped?.logRefused ?? false)
        XCTAssertEqual(
            ExpeditionFold.log(snapshot, pages: 1, dayKey: 20260114, calendar: calendar),
            .failure(.driftCapped)
        )
        snapshot = try ExpeditionFold.set(snapshot, dayKey: 20260114, calendar: calendar).get()
        let cleared = ExpeditionFold.projection(snapshot, expedition: snapshot.expeditions[0], today: 20260114, calendar: calendar)
        XCTAssertEqual(cleared?.driftAngle ?? 1, 0, accuracy: 0.000_001)
        XCTAssertFalse(cleared?.logRefused ?? true)
        XCTAssertGreaterThan(snapshot.expeditions[0].landfallDayKey, 20260114)
        snapshot = try ExpeditionFold.log(snapshot, pages: 1, dayKey: 20260114, calendar: calendar).get()
        XCTAssertEqual(snapshot.legs.count, 2)
    }

    func testSetRefusedWhenDriftIsZero() throws {
        let volume = Volume(title: "Calm", totalPages: 100)
        var snapshot = PeriplusSnapshot(volumes: [volume])
        snapshot = try ExpeditionFold.open(
            snapshot,
            volumeId: volume.id,
            baseDayKey: 20260501,
            landfallDayKey: 20260520,
            calendar: calendar
        ).get()
        XCTAssertEqual(ExpeditionFold.set(snapshot, dayKey: 20260501, calendar: calendar), .failure(.driftAlreadyZero))
    }

    func testQuartileBuoysAndLandfallFold() throws {
        let volume = Volume(title: "Full Route", totalPages: 100)
        var snapshot = PeriplusSnapshot(volumes: [volume])
        snapshot = try ExpeditionFold.open(
            snapshot,
            volumeId: volume.id,
            baseDayKey: 20260601,
            landfallDayKey: 20260630,
            calendar: calendar
        ).get()
        XCTAssertEqual(ExpeditionFold.phase(in: snapshot), .underway(snapshot.expeditions[0]))
        XCTAssertEqual(
            ExpeditionFold.open(snapshot, volumeId: volume.id, baseDayKey: 20260601, landfallDayKey: 20260630, calendar: calendar),
            .failure(.alreadyUnderway)
        )
        snapshot = try ExpeditionFold.log(snapshot, pages: 80, dayKey: 20260601, calendar: calendar).get()
        XCTAssertEqual(snapshot.buoys.map(\.quartile), [25, 50, 75])
        XCTAssertEqual(ExpeditionFold.phase(in: snapshot), .underway(snapshot.expeditions[0]))
        snapshot = try ExpeditionFold.log(snapshot, pages: 20, dayKey: 20260601, calendar: calendar).get()
        if case .landed = ExpeditionFold.phase(in: snapshot) {
            XCTAssertEqual(snapshot.landfalls.count, 1)
        } else {
            XCTFail("Finished route on a clear drift should land")
        }
        XCTAssertEqual(ExpeditionFold.log(snapshot, pages: 1, dayKey: 20260601, calendar: calendar), .failure(.alreadyLanded))
    }

    func testDemoSeedEnablesLog() {
        let seeded = DemoSeed.make(today: 20260912, calendar: calendar)
        XCTAssertNotNil(seeded)
        guard let seeded else { return }
        XCTAssertEqual(seeded.volumes.count, 1)
        XCTAssertEqual(seeded.volumes[0].title, "Northwater Atlas")
        XCTAssertEqual(seeded.legs.count, 4)
        XCTAssertEqual(seeded.buoys.count, 1)
        XCTAssertEqual(ExpeditionFold.phase(in: seeded), .underway(seeded.expeditions[0]))
        let reading = ExpeditionFold.projection(seeded, expedition: seeded.expeditions[0], today: 20260912, calendar: calendar)
        XCTAssertGreaterThan(reading?.routeX ?? 0, 0)
        XCTAssertLessThan(reading?.driftAngle ?? 45, 45)
        XCTAssertFalse(reading?.logRefused ?? true)
    }

    func testReviewLaunchParsesOnceAfterOnboarding() async {
        XCTAssertNil(ReviewLaunch.destination(from: ["Periplus"]))
        XCTAssertEqual(ReviewLaunch.destination(from: ["Periplus", "-ReviewScreen", "today"]), .today)
        XCTAssertEqual(ReviewLaunch.destination(from: ["-ReviewScreen", "log"]), .log)
        XCTAssertEqual(ReviewLaunch.destination(from: ["-ReviewScreen", "goals"]), .goals)
        XCTAssertEqual(ReviewLaunch.destination(from: ["-ReviewScreen", "catalogue"]), .catalogue)
        XCTAssertEqual(ReviewLaunch.destination(from: ["-ReviewScreen", "settings"]), .settings)
        XCTAssertNil(ReviewLaunch.destination(from: ["-ReviewScreen", "missing"]))

        let suite = "prp.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            XCTFail("Could not open defaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suite)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let routeCalendar = calendar
        let store = await MainActor.run {
            PeriplusStore(directory: directory, defaults: defaults, clock: { Date(timeIntervalSince1970: 1_700_000_000) }, calendar: routeCalendar)
        }
        await MainActor.run {
            store.consumeLaunch(arguments: ["-ReviewScreen", "log"])
        }
        let blocked = await MainActor.run { store.reviewDestination }
        XCTAssertNil(blocked)
        await MainActor.run {
            store.finishOnboarding()
            store.consumeLaunch(arguments: ["-ReviewScreen", "goals"])
        }
        let first = await MainActor.run { store.reviewDestination }
        XCTAssertEqual(first, .goals)
        await MainActor.run {
            store.consumeLaunch(arguments: ["-ReviewScreen", "today"])
        }
        let second = await MainActor.run { store.reviewDestination }
        XCTAssertEqual(second, .goals)
    }
}

@MainActor
final class PeriplusStoreTests: XCTestCase {
    func testPersistenceRoundTripBackupAndReset() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let csv = CsvStore(directory: directory)
        let volume = Volume(title: "Comma, \"Quoted\"", author: "A", isbn: "9781111111111", totalPages: 120)
        let expedition = Expedition(volumeId: volume.id, baseDayKey: 20260101, landfallDayKey: 20260120)
        let leg = Leg(expeditionId: expedition.id, dayKey: 20260102, pages: 12)
        let first = PeriplusSnapshot(volumes: [volume], expeditions: [expedition], legs: [leg])
        await csv.write(first, generation: 1)
        let secondVolume = Volume(id: volume.id, title: volume.title, author: volume.author, isbn: volume.isbn, totalPages: 140)
        let second = PeriplusSnapshot(volumes: [secondVolume], expeditions: [expedition], legs: [leg])
        await csv.write(second, generation: 2)

        let reloaded = CsvStore(directory: directory)
        let loaded = await reloaded.load()
        XCTAssertNil(loaded.notice)
        XCTAssertEqual(loaded.snapshot.volumes.first?.title, "Comma, \"Quoted\"")
        XCTAssertEqual(loaded.snapshot.volumes.first?.totalPages, 140)
        XCTAssertEqual(loaded.snapshot.legs.first?.pages, 12)
        let legsFile = try String(contentsOf: directory.appendingPathComponent("legs.csv"), encoding: .utf8)
        XCTAssertFalse(legsFile.contains("routeX"))
        XCTAssertFalse(legsFile.contains("driftAngle"))

        let manifest = directory.appendingPathComponent("manifest.csv")
        try Data("schemaVersion,99\n".utf8).write(to: manifest, options: .atomic)
        let restored = await CsvStore(directory: directory).load()
        XCTAssertEqual(restored.notice, .restoredBackup)
        XCTAssertEqual(restored.snapshot.volumes.first?.totalPages, 120)

        try Data("nope".utf8).write(to: directory.appendingPathComponent("manifest.csv"), options: .atomic)
        let backupManifest = directory.deletingLastPathComponent()
            .appendingPathComponent(directory.lastPathComponent + ".backup")
            .appendingPathComponent("manifest.csv")
        try Data("schemaVersion,7\n".utf8).write(to: backupManifest, options: .atomic)
        let emptied = await CsvStore(directory: directory).load()
        XCTAssertEqual(emptied.notice, .startedEmpty)
        XCTAssertTrue(emptied.snapshot.volumes.isEmpty)

        await csv.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }
}

final class OpenLibraryClientTests: XCTestCase {
    func testSearchDecodesStringAndNumberPagesAndSetsUserAgent() async throws {
        let script = ScriptBook()
        await script.enqueue(status: 200, body: """
        {"numFound":1,"docs":[{"key":"/works/OL1W","title":"Paper Route","author_name":["Lee"],"isbn":["9780140328721"],"number_of_pages_median":"320"}]}
        """)
        let cache = CatalogueCache(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let client = OpenLibraryClient(transport: ScriptTransport(book: script), cache: cache)
        let hits = try await client.search(query: "paper")
        XCTAssertEqual(hits.first?.title, "Paper Route")
        XCTAssertEqual(hits.first?.totalPages, 320)
        let request = await script.requests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), OpenLibraryClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        let cached = await cache.search(query: "paper")
        XCTAssertEqual(cached.first?.isbn, "9780140328721")
    }

    func testIsbnNotFoundIsDistinctAndMalformedJSONIsAnError() async throws {
        let script = ScriptBook()
        await script.enqueue(status: 404, body: "{}")
        let cache = CatalogueCache(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let client = OpenLibraryClient(transport: ScriptTransport(book: script), cache: cache)
        do {
            _ = try await client.edition(isbn: "9780140328721")
            XCTFail("Expected not found")
        } catch let error as CatalogueError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("Unexpected \(error)")
        }
        let misses = await script.callCount()
        XCTAssertEqual(misses, 1)

        await script.enqueue(status: 200, body: "{")
        do {
            _ = try await client.edition(isbn: "9780140328721")
            XCTFail("Expected decoding")
        } catch let error as CatalogueError {
            XCTAssertEqual(error, .decoding)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testRetriesTransientFailureOnce() async throws {
        let script = ScriptBook()
        await script.enqueueThrow(URLError(.timedOut))
        await script.enqueue(status: 200, body: """
        {"title":"Ribbon","isbn_13":["9780140328721"],"number_of_pages":188}
        """)
        let cache = CatalogueCache(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let client = OpenLibraryClient(transport: ScriptTransport(book: script), cache: cache)
        let hit = try await client.edition(isbn: "9780140328721")
        XCTAssertEqual(hit.totalPages, 188)
        let attempts = await script.callCount()
        XCTAssertEqual(attempts, 2)
    }

    func testEmptyQueryDoesNotHitNetworkAndStaleSearchIsDropped() async throws {
        let script = ScriptBook()
        let cache = CatalogueCache(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        let client = OpenLibraryClient(transport: ScriptTransport(book: script), cache: cache)
        let empty = try await client.search(query: "  ")
        XCTAssertTrue(empty.isEmpty)
        let calls = await script.callCount()
        XCTAssertEqual(calls, 0)

        let gate = SearchGate()
        let gated = OpenLibraryClient(transport: GatedTransport(gate: gate), cache: cache)
        let search = TitleSearch()
        await MainActor.run {
            search.submit(query: "first", client: gated, debounce: .zero)
        }
        try await Task.sleep(for: .milliseconds(50))
        await MainActor.run {
            search.submit(query: "second", client: gated, debounce: .zero)
        }
        try await Task.sleep(for: .milliseconds(50))
        await gate.open()
        try await Task.sleep(for: .milliseconds(80))
        let hits = await MainActor.run { search.hits }
        XCTAssertEqual(hits.map(\.title), ["second"])
    }
}

private actor ScriptBook {
    struct Step {
        var status: Int?
        var body: Data?
        var error: URLError?
    }

    private var steps: [Step] = []
    private var seen: [URLRequest] = []

    func enqueue(status: Int, body: String) {
        steps.append(Step(status: status, body: Data(body.utf8), error: nil))
    }

    func enqueueThrow(_ error: URLError) {
        steps.append(Step(status: nil, body: nil, error: error))
    }

    func next(_ request: URLRequest) throws -> (Data, HTTPURLResponse) {
        seen.append(request)
        guard !steps.isEmpty else { throw CatalogueError.transport }
        let step = steps.removeFirst()
        if let error = step.error { throw error }
        guard let url = request.url,
              let status = step.status,
              let body = step.body,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            throw CatalogueError.transport
        }
        return (body, response)
    }

    func callCount() -> Int { seen.count }
    func requests() -> [URLRequest] { seen }
}

private struct ScriptTransport: HTTPTransport {
    let book: ScriptBook
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await book.next(request)
    }
}

private actor SearchGate {
    private var waiters: [CheckedContinuation<Void, Never>] = []
    func wait() async {
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func open() {
        let pending = waiters
        waiters.removeAll()
        for waiter in pending {
            waiter.resume()
        }
    }
}

private struct GatedTransport: HTTPTransport {
    let gate: SearchGate
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try Task.checkCancellation()
        await gate.wait()
        try Task.checkCancellation()
        let query = URLComponents(url: request.url ?? URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "q" }?
            .value ?? ""
        let body = Data("{\"docs\":[{\"key\":\"/works/\(query)\",\"title\":\"\(query)\"}]}".utf8)
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            throw CatalogueError.transport
        }
        return (body, response)
    }
}
