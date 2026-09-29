import Foundation

/// One client for both Open Library endpoints: title search and ISBN edition.
/// User-Agent is set on every request. Timeout is 15 seconds. A transient
/// transport failure is retried once. A 404 is not retried. JSON is decoded
/// into DTOs, then mapped to `CatalogueHit`.
struct OpenLibraryClient: Sendable {
    static let userAgent = "Periplus/1.0 (iOS; +https://periplus-route.pro)"
    static let timeout: TimeInterval = 15

    private let transport: any HTTPTransport
    private let cache: EditionCache

    init(transport: any HTTPTransport, cache: EditionCache) {
        self.transport = transport
        self.cache = cache
    }

    static func live(cache: EditionCache) -> OpenLibraryClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.waitsForConnectivity = false
        return OpenLibraryClient(transport: URLSessionTransport(session: URLSession(configuration: configuration)), cache: cache)
    }

    func search(query: String) async throws -> [CatalogueHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard var components = URLComponents(string: "https://openlibrary.org/search.json") else {
            throw CatalogueError.transport
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "fields", value: "key,title,author_name,isbn,number_of_pages_median"),
        ]
        guard let url = components.url else { throw CatalogueError.transport }
        do {
            let data = try await send(url)
            let hits = try decodeSearch(data)
            await cache.store(hits)
            return hits
        } catch is CancellationError {
            throw CancellationError()
        } catch CatalogueError.cancelled {
            throw CancellationError()
        } catch let error as CatalogueError {
            return try await fallback(query: trimmed, error: error)
        } catch {
            return try await fallback(query: trimmed, error: .transport)
        }
    }

    func edition(isbn: String) async throws -> CatalogueHit {
        let code = isbn.filter(\.isNumber)
        guard (8...14).contains(code.count) else { throw CatalogueError.notFound }
        if let cached = await cache.edition(isbn: code) {
            return cached
        }
        guard let url = URL(string: "https://openlibrary.org/isbn/\(code).json") else {
            throw CatalogueError.transport
        }
        do {
            let data = try await send(url)
            let hit = try decodeEdition(data, isbn: code)
            await cache.store([hit])
            return hit
        } catch is CancellationError {
            throw CancellationError()
        } catch CatalogueError.cancelled {
            throw CancellationError()
        } catch let error as CatalogueError {
            if let cached = await cache.edition(isbn: code) {
                return cached
            }
            throw error
        } catch {
            if let cached = await cache.edition(isbn: code) {
                return cached
            }
            throw CatalogueError.transport
        }
    }

    private func fallback(query: String, error: CatalogueError) async throws -> [CatalogueHit] {
        let local = await cache.search(query: query)
        if local.isEmpty {
            throw error
        }
        return local
    }

    private func send(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = Self.timeout
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let first = await result(of: request)
        switch first {
        case .success(let payload):
            return payload
        case .failure(let failure):
            if failure.retryable {
                let second = await result(of: request)
                switch second {
                case .success(let payload):
                    return payload
                case .failure(let again):
                    throw again.error
                }
            }
            throw failure.error
        }
    }

    private func result(of request: URLRequest) async -> Result<Data, TransportFailure> {
        do {
            try Task.checkCancellation()
            let (data, response) = try await transport.data(for: request)
            switch response.statusCode {
            case 200...299:
                return .success(data)
            case 404:
                return .failure(TransportFailure(error: .notFound, retryable: false))
            default:
                return .failure(TransportFailure(error: .transport, retryable: false))
            }
        } catch is CancellationError {
            return .failure(TransportFailure(error: .cancelled, retryable: false))
        } catch let error as URLError where Self.isTransient(error) {
            return .failure(TransportFailure(error: .transport, retryable: true))
        } catch {
            return .failure(TransportFailure(error: .transport, retryable: false))
        }
    }

    private static func isTransient(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private func decodeSearch(_ data: Data) throws -> [CatalogueHit] {
        let envelope: SearchEnvelope
        do {
            envelope = try Self.makeDecoder().decode(SearchEnvelope.self, from: data)
        } catch {
            throw CatalogueError.decoding
        }
        return envelope.docs.compactMap { doc in
            guard let title = doc.title, !title.isEmpty else { return nil }
            let isbn = doc.isbn?.first(where: { value in
                let digits = value.filter(\.isNumber)
                return (8...14).contains(digits.count)
            })?.filter(\.isNumber) ?? ""
            let author = doc.author_name?.first ?? ""
            let key = doc.key ?? (isbn.isEmpty ? title : isbn)
            return CatalogueHit(
                id: key,
                title: title,
                author: author,
                isbn: isbn,
                totalPages: doc.number_of_pages_median?.value
            )
        }
    }

    private func decodeEdition(_ data: Data, isbn: String) throws -> CatalogueHit {
        let edition: EditionDTO
        do {
            edition = try Self.makeDecoder().decode(EditionDTO.self, from: data)
        } catch {
            throw CatalogueError.decoding
        }
        guard let title = edition.title, !title.isEmpty else { throw CatalogueError.notFound }
        let resolved = edition.isbn_13?.first?.filter(\.isNumber) ?? isbn
        return CatalogueHit(
            id: resolved,
            title: title,
            author: "",
            isbn: resolved,
            totalPages: edition.number_of_pages?.value
        )
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }
}

enum CatalogueError: Equatable, Error, Sendable {
    case transport
    case notFound
    case decoding
    case cancelled
}

protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CatalogueError.transport }
        return (data, http)
    }
}

protocol EditionCache: Sendable {
    func search(query: String) async -> [CatalogueHit]
    func edition(isbn: String) async -> CatalogueHit?
    func store(_ hits: [CatalogueHit]) async
}

/// Local shelf of resolved Open Library rows. Lives in Caches and is excluded
/// from backup. User volumes stay in Application Support.
actor CatalogueCache: EditionCache {
    private let fileURL: URL
    private let fileManager: FileManager
    private var hits: [CatalogueHit] = []
    private var loaded = false
    private var persistError: String?

    init(directory: URL, fileManager: FileManager = .default) {
        self.fileURL = directory.appendingPathComponent("editions.csv")
        self.fileManager = fileManager
    }

    func search(query: String) async -> [CatalogueHit] {
        await loadIfNeeded()
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        return hits.filter { hit in
            hit.title.lowercased().contains(needle) || hit.author.lowercased().contains(needle) || hit.isbn.contains(needle)
        }
    }

    func edition(isbn: String) async -> CatalogueHit? {
        await loadIfNeeded()
        let code = isbn.filter(\.isNumber)
        return hits.first { $0.isbn.filter(\.isNumber) == code }
    }

    func store(_ incoming: [CatalogueHit]) async {
        await loadIfNeeded()
        for hit in incoming where !hit.title.isEmpty {
            if let isbn = normalized(hit.isbn), let index = hits.firstIndex(where: { normalized($0.isbn) == isbn }) {
                hits[index] = hit
            } else if let index = hits.firstIndex(where: { $0.id == hit.id }) {
                hits[index] = hit
            } else {
                hits.append(hit)
            }
        }
        do {
            try persist()
        } catch {
            persistError = String(describing: error)
        }
    }

    func lastPersistError() -> String? {
        persistError
    }

    private func normalized(_ isbn: String) -> String? {
        let digits = isbn.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }

    private func loadIfNeeded() async {
        guard !loaded else { return }
        loaded = true
        guard let data = try? Data(contentsOf: fileURL), let text = String(data: data, encoding: .utf8) else {
            return
        }
        let rows = CsvStore.parse(text)
        guard let header = rows.first, header.count >= 2, header[0] == "schemaVersion", Int(header[1]) == 1 else {
            return
        }
        hits = rows.dropFirst().compactMap { row in
            guard row.count == 5 else { return nil }
            let pages = Int(row[4])
            return CatalogueHit(id: row[0], title: row[1], author: row[2], isbn: row[3], totalPages: pages)
        }
    }

    private func persist() throws {
        let folder = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        var folderValues = URLResourceValues()
        folderValues.isExcludedFromBackup = true
        var mutable = folder
        try mutable.setResourceValues(folderValues)
        var lines = ["schemaVersion,1"]
        for hit in hits {
            let pages = hit.totalPages.map(String.init) ?? ""
            let fields = [hit.id, hit.title, hit.author, hit.isbn, pages].map(CsvStore.escape)
            lines.append(fields.joined(separator: ","))
        }
        let text = lines.joined(separator: "\n") + "\n"
        guard let data = text.data(using: .utf8) else { return }
        try data.write(to: fileURL, options: .atomic)
    }
}

private struct TransportFailure: Error, Sendable {
    var error: CatalogueError
    var retryable: Bool
}

private struct LooseInt: Decodable, Sendable {
    var value: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let int = try? container.decode(Int.self) {
            value = int
            return
        }
        if let double = try? container.decode(Double.self) {
            value = Int(double)
            return
        }
        if let string = try? container.decode(String.self) {
            if let int = Int(string) {
                value = int
            } else if let double = Double(string) {
                value = Int(double)
            } else {
                value = nil
            }
            return
        }
        value = nil
    }
}

private struct SearchEnvelope: Decodable {
    var docs: [SearchDoc]
}

private struct SearchDoc: Decodable {
    var key: String?
    var title: String?
    var author_name: [String]?
    var isbn: [String]?
    var number_of_pages_median: LooseInt?
}

private struct EditionDTO: Decodable {
    var title: String?
    var isbn_13: [String]?
    var number_of_pages: LooseInt?
}
