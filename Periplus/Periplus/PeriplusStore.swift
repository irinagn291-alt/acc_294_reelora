import Foundation
import Observation

/// In-memory periplus. Screens talk to this type and never to `CsvStore`.
/// Disk writes are debounced off the caller's await, flushed when the scene
/// leaves the foreground, and flushed again after a destructive reset.
@MainActor
@Observable
final class PeriplusStore {
    static let demoKey = "prp.demo.v1"
    static let onboardingKey = "prp.onboarding.complete"

    private(set) var snapshot = PeriplusSnapshot.empty
    private(set) var loadNotice: LoadNotice?
    private(set) var diskWriteFailed = false
    private(set) var reviewDestination: ReviewDestination?
    var onboardingComplete: Bool

    private let csv: CsvStore
    private let defaults: UserDefaults
    private let clock: @Sendable () -> Date
    private let calendar: Calendar
    private var saveTask: Task<Void, Never>?
    private var saveGeneration = 0
    private var didConsumeLaunch = false

    init(
        directory: URL? = nil,
        defaults: UserDefaults = .standard,
        clock: @escaping @Sendable () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        let folder = directory ?? Self.applicationSupportDirectory()
        self.csv = CsvStore(directory: folder)
        self.defaults = defaults
        self.clock = clock
        self.calendar = calendar
        self.onboardingComplete = defaults.bool(forKey: Self.onboardingKey)
    }

    func prepare() async {
        let loaded = await csv.load()
        snapshot = loaded.snapshot
        loadNotice = loaded.notice
        await seedDemoIfNeeded()
        if onboardingComplete {
            consumeLaunch(arguments: ProcessInfo.processInfo.arguments)
        }
    }

    func consumeLaunch(arguments: [String]) {
        guard onboardingComplete, !didConsumeLaunch else { return }
        didConsumeLaunch = true
        reviewDestination = ReviewLaunch.destination(from: arguments)
    }

    func finishOnboarding() {
        onboardingComplete = true
        defaults.set(true, forKey: Self.onboardingKey)
    }

    /// Settings can walk the reader through the pages again. Launch keys stay consumed.
    func reopenOnboarding() {
        onboardingComplete = false
        defaults.set(false, forKey: Self.onboardingKey)
    }

    var today: Int {
        DayKey.make(from: clock(), calendar: calendar)
    }

    func upsertVolume(title: String, author: String, isbn: String, totalPages: Int) -> Result<UUID, RouteRefusal> {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, totalPages > 0 else { return .failure(.volumeMissing) }
        let digits = isbn.filter(\.isNumber)
        if !digits.isEmpty, let index = snapshot.volumes.firstIndex(where: { $0.isbn.filter(\.isNumber) == digits }) {
            snapshot.volumes[index].title = trimmed
            snapshot.volumes[index].author = author
            snapshot.volumes[index].totalPages = totalPages
            scheduleSave()
            return .success(snapshot.volumes[index].id)
        }
        let volume = Volume(title: trimmed, author: author, isbn: digits, totalPages: totalPages)
        snapshot.volumes.append(volume)
        scheduleSave()
        return .success(volume.id)
    }

    func openExpedition(volumeId: UUID, landfallDayKey: Int) -> Result<Void, RouteRefusal> {
        switch ExpeditionFold.open(
            snapshot,
            volumeId: volumeId,
            baseDayKey: today,
            landfallDayKey: landfallDayKey,
            calendar: calendar
        ) {
        case .success(let next):
            snapshot = next
            scheduleSave()
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    func logLeg(pages: Int) -> Result<Void, RouteRefusal> {
        switch LogLeg.commit(snapshot: snapshot, pages: pages, dayKey: today, calendar: calendar) {
        case .success(let next):
            snapshot = next
            scheduleSave()
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    func recalibrate() -> Result<Void, RouteRefusal> {
        switch ExpeditionFold.set(snapshot, dayKey: today, calendar: calendar) {
        case .success(let next):
            snapshot = next
            scheduleSave()
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    func projection() -> RouteProjection? {
        guard let expedition = ExpeditionFold.underway(snapshot) ?? {
            if case .landed(let landed) = ExpeditionFold.phase(in: snapshot) { return landed }
            return nil
        }() else { return nil }
        return ExpeditionFold.projection(snapshot, expedition: expedition, today: today, calendar: calendar)
    }

    func scheduleSave() {
        saveGeneration += 1
        let generation = saveGeneration
        let copy = snapshot
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await csv.write(copy, generation: generation)
        }
    }

    func flush() async {
        saveTask?.cancel()
        saveTask = nil
        saveGeneration += 1
        let generation = saveGeneration
        await csv.write(snapshot, generation: generation)
        diskWriteFailed = await csv.takeWriteError() != nil
    }

    func resetAllData() async {
        saveTask?.cancel()
        saveTask = nil
        saveGeneration += 1
        snapshot = .empty
        loadNotice = nil
        await csv.reset()
    }

    func noteScenePhase(_ phase: ScenePhaseBridge) {
        switch phase {
        case .inactive, .background:
            let generation = saveGeneration
            let copy = snapshot
            saveTask?.cancel()
            saveTask = Task {
                await csv.write(copy, generation: generation)
            }
        case .active:
            break
        }
    }

    private func seedDemoIfNeeded() async {
        #if targetEnvironment(simulator)
        guard defaults.bool(forKey: Self.demoKey) == false else { return }
        defaults.set(true, forKey: Self.demoKey)
        guard snapshot.volumes.isEmpty, snapshot.expeditions.isEmpty else { return }
        guard let seeded = DemoSeed.make(today: today, calendar: calendar) else { return }
        snapshot = seeded
        finishOnboarding()
        saveGeneration += 1
        await csv.write(snapshot, generation: saveGeneration)
        #endif
    }

    private static func applicationSupportDirectory() -> URL {
        let fileManager = FileManager.default
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return root.appendingPathComponent("com.periplus.route", isDirectory: true)
    }
}

/// Scene phase without importing SwiftUI into the fold. The app maps the environment value.
enum ScenePhaseBridge: Sendable {
    case active
    case inactive
    case background
}
