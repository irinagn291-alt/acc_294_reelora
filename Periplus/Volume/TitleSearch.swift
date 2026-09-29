import Foundation

/// Debounced title search. A new query cancels the in-flight task so a stale
/// response cannot replace fresher results. An empty query does not hit the network.
@MainActor
final class TitleSearch {
    private(set) var hits: [CatalogueHit] = []
    private(set) var failure: CatalogueError?
    private var task: Task<Void, Never>?
    private var generation = 0

    func submit(query: String, client: OpenLibraryClient, debounce: Duration = .milliseconds(500)) {
        task?.cancel()
        generation += 1
        let token = generation
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            hits = []
            failure = nil
            return
        }
        task = Task { [weak self] in
            do {
                try await Task.sleep(for: debounce)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            do {
                let found = try await client.search(query: trimmed)
                guard !Task.isCancelled else { return }
                self?.apply(found, token: token)
            } catch is CancellationError {
                return
            } catch let error as CatalogueError {
                self?.applyFailure(error, token: token)
            } catch {
                self?.applyFailure(.transport, token: token)
            }
        }
    }

    func cancel() {
        task?.cancel()
        generation += 1
    }

    private func apply(_ found: [CatalogueHit], token: Int) {
        guard token == generation else { return }
        hits = found
        failure = nil
    }

    private func applyFailure(_ error: CatalogueError, token: Int) {
        guard token == generation, error != .cancelled else { return }
        failure = error
    }
}
