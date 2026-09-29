import SwiftUI

/// Catalogue sheet. Title search and ISBN scan share this surface.
/// A failed lookup falls through to a manual shelf entry.
struct CatalogueScreen: View {
    @Bindable var store: PeriplusStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var desk = CatalogueDesk()
    @State private var showScan = false
    @State private var manual = false
    @State private var manualTitle = ""
    @State private var manualAuthor = ""
    @State private var manualISBN = ""
    @State private var manualPages = ""
    @State private var notice: String?
    @State private var showSpinner = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bg.ignoresSafeArea()
                if store.snapshot.volumes.isEmpty && desk.query.isEmpty && !manual {
                    empty
                } else {
                    filled
                }
            }
            .navigationTitle("Catalogue")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(DesignTokens.accent)
        .sheet(isPresented: $showScan) {
            IsbnScanSheet { code in
                showScan = false
                Task { await desk.lookupISBN(code) }
            }
        }
        .onChange(of: desk.query) { _, value in
            desk.submit(value)
        }
        .onChange(of: desk.busy) { _, busy in
            guard busy else {
                showSpinner = false
                return
            }
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                if desk.busy { showSpinner = true }
            }
        }
        .onChange(of: desk.needsManual) { _, needs in
            if needs { manual = true }
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: RouteMeasure.pad) {
            Image("prp_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: RouteMeasure.unit * 30)
                .accessibilityHidden(true)
            Text("The shelf is empty.")
                .font(RouteMeasure.mono(.title, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Text("Search a title or scan an ISBN to put a book on this device.")
                .font(RouteMeasure.mono(.body))
                .foregroundStyle(DesignTokens.muted)
                .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
            searchField
            Spacer(minLength: 0)
            Button("Scan ISBN") { showScan = true }
                .buttonStyle(RoutePrimaryStyle())
            Button("Enter a book") { manual = true }
                .buttonStyle(RouteQuietStyle())
        }
        .padding(RouteMeasure.band)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var filled: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                searchField
                HStack(spacing: RouteMeasure.row) {
                    Button("Scan ISBN") { showScan = true }
                        .buttonStyle(RoutePrimaryStyle())
                    Button("Enter a book") { manual = true }
                        .buttonStyle(RouteQuietStyle())
                }
                if showSpinner {
                    ProgressView("Searching Open Library")
                        .font(RouteMeasure.mono(.caption))
                        .tint(DesignTokens.accent)
                        .foregroundStyle(DesignTokens.ink)
                }
                if let failure = desk.failure {
                    VStack(alignment: .leading, spacing: RouteMeasure.row) {
                        Text(failureText(failure))
                            .font(RouteMeasure.mono(.caption))
                            .foregroundStyle(DesignTokens.ink)
                        Button("Try the search again") { desk.submit(desk.query) }
                            .buttonStyle(RoutePrimaryStyle())
                    }
                    .padding(RouteMeasure.row)
                    .hairlinePlate(radius: RouteMeasure.chip)
                }
                if let notice {
                    Text(notice)
                        .font(RouteMeasure.mono(.caption))
                        .foregroundStyle(DesignTokens.ink)
                }
                if manual || desk.needsManual {
                    manualForm
                }
                if !desk.hits.isEmpty {
                    Text("Open Library")
                        .font(RouteMeasure.mono(.headline))
                        .foregroundStyle(DesignTokens.ink)
                    ForEach(desk.hits) { hit in
                        hitRow(hit)
                    }
                }
                Text("On this device")
                    .font(RouteMeasure.mono(.headline))
                    .foregroundStyle(DesignTokens.ink)
                let local = filteredLocal
                if local.isEmpty {
                    Text("No saved book matches that search. The shelf still filters without a network.")
                        .font(RouteMeasure.mono(.caption))
                        .foregroundStyle(DesignTokens.muted)
                        .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                } else {
                    ForEach(local) { volume in
                        volumeRow(volume)
                    }
                }
            }
            .padding(RouteMeasure.band)
            .animation(reduceMotion ? nil : RouteMeasure.settle, value: desk.hits.count)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var searchField: some View {
        TextField("Search a title", text: $desk.query)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(RouteMeasure.mono(.body))
            .foregroundStyle(DesignTokens.ink)
            .padding(RouteMeasure.row)
            .frame(minHeight: 44)
            .hairlinePlate(radius: RouteMeasure.chip)
    }

    private var manualForm: some View {
        VStack(alignment: .leading, spacing: RouteMeasure.row) {
            Text("Save the book on this device. Page count is required.")
                .font(RouteMeasure.mono(.caption))
                .foregroundStyle(DesignTokens.muted)
                field("Title", text: $manualTitle)
            field("Author", text: $manualAuthor)
            field("ISBN", text: $manualISBN)
            field("Total pages", text: $manualPages)
                .keyboardType(.numberPad)
            Button("Save book") { saveManual() }
                .buttonStyle(RoutePrimaryStyle())
                .disabled(manualTitle.trimmingCharacters(in: .whitespaces).isEmpty || (Int(manualPages.filter(\.isNumber)) ?? 0) < 1)
        }
        .padding(RouteMeasure.pad)
        .hairlinePlate()
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .font(RouteMeasure.mono(.body))
            .foregroundStyle(DesignTokens.ink)
            .padding(RouteMeasure.row)
            .frame(minHeight: 44)
            .hairlinePlate(radius: RouteMeasure.chip)
    }

    private var filteredLocal: [Volume] {
        let needle = desk.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return store.snapshot.volumes }
        return store.snapshot.volumes.filter {
            $0.title.lowercased().contains(needle)
                || $0.author.lowercased().contains(needle)
                || $0.isbn.contains(needle.filter(\.isNumber))
        }
    }

    private func hitRow(_ hit: CatalogueHit) -> some View {
        VStack(alignment: .leading, spacing: RouteMeasure.tight) {
            Text(hit.title)
                .font(RouteMeasure.mono(.body, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
            Text(hit.author.isEmpty ? "Author unknown" : hit.author)
                .font(RouteMeasure.mono(.micro))
                .foregroundStyle(DesignTokens.muted)
            Button("Save") {
                if let pages = hit.totalPages, pages > 0 {
                    commit(title: hit.title, author: hit.author, isbn: hit.isbn, pages: pages)
                } else {
                    manualTitle = hit.title
                    manualAuthor = hit.author
                    manualISBN = hit.isbn
                    manual = true
                    notice = "Open Library did not include a page count. Add the total, then save."
                }
            }
            .buttonStyle(RoutePrimaryStyle())
        }
        .padding(RouteMeasure.row)
        .hairlinePlate()
    }

    private func volumeRow(_ volume: Volume) -> some View {
        let author = volume.author.isEmpty ? "Author unknown" : volume.author
        let count = RouteMeasure.pagesText(volume.totalPages)
        return VStack(alignment: .leading, spacing: RouteMeasure.tight) {
            Text(volume.title)
                .font(RouteMeasure.mono(.body, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(2)
            Text("\(author), \(count) pages")
                .font(RouteMeasure.mono(.micro))
                .foregroundStyle(DesignTokens.muted)
        }
        .padding(RouteMeasure.row)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlinePlate()
    }

    private func saveManual() {
        guard let pages = Int(manualPages.filter(\.isNumber)), pages > 0 else {
            notice = "Enter the total pages as a whole number."
            return
        }
        commit(title: manualTitle, author: manualAuthor, isbn: manualISBN, pages: pages)
        manual = false
        desk.needsManual = false
    }

    private func commit(title: String, author: String, isbn: String, pages: Int) {
        switch store.upsertVolume(title: title, author: author, isbn: isbn, totalPages: pages) {
        case .success:
            notice = "Saved \(title) on this device."
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .failure:
            notice = "A volume needs a title and a page count."
        }
    }

    private func failureText(_ error: CatalogueError) -> String {
        switch error {
        case .transport:
            return "Open Library did not answer. You can still save a volume by hand."
        case .notFound:
            return "That ISBN is not in Open Library. Enter the volume yourself."
        case .decoding:
            return "The catalogue reply could not be read. Enter the volume yourself."
        case .cancelled:
            return "The search was cancelled."
        }
    }
}

@MainActor
@Observable
final class CatalogueDesk {
    var query = ""
    var hits: [CatalogueHit] = []
    var failure: CatalogueError?
    var busy = false
    var needsManual = false

    private let search = TitleSearch()
    private let client: OpenLibraryClient
    private var watch: Task<Void, Never>?

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = caches.appendingPathComponent("com.periplus.route", isDirectory: true)
        client = OpenLibraryClient.live(cache: CatalogueCache(directory: folder))
    }

    func submit(_ raw: String) {
        query = raw
        search.submit(query: raw, client: client)
        watch?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            hits = []
            failure = nil
            busy = false
            return
        }
        busy = true
        watch = Task { [weak self] in
            for _ in 0..<30 {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, !Task.isCancelled else { return }
                self.hits = self.search.hits
                self.failure = self.search.failure
                if self.search.failure != nil || !self.search.hits.isEmpty {
                    self.busy = false
                    if self.search.hits.isEmpty, self.search.failure != nil {
                        self.needsManual = true
                    }
                    return
                }
            }
            self?.busy = false
            if self?.hits.isEmpty == true {
                self?.needsManual = true
            }
        }
    }

    func lookupISBN(_ code: String) async {
        busy = true
        defer { busy = false }
        do {
            let hit = try await client.edition(isbn: code)
            if hit.totalPages == nil {
                needsManual = true
            }
            hits = [hit]
            failure = nil
        } catch let error as CatalogueError {
            failure = error
            needsManual = true
        } catch {
            failure = .transport
            needsManual = true
        }
    }
}
