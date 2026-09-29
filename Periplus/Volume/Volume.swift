import Foundation

/// A book on the local shelf. Pages are the denominator for routeX.
/// Catalogue search maps into this type only after the reader saves it.
/// Open Library payloads never decode straight into `Volume`.
struct Volume: Identifiable, Equatable, Sendable {
    var id: UUID
    var title: String
    var author: String
    var isbn: String
    var totalPages: Int

    init(id: UUID = UUID(), title: String, author: String = "", isbn: String = "", totalPages: Int) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn = isbn
        self.totalPages = totalPages
    }
}

/// A resolved catalogue row before it is committed to the shelf.
/// `totalPages` stays optional because Open Library editions are often incomplete.
struct CatalogueHit: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var author: String
    var isbn: String
    var totalPages: Int?

    init(id: String, title: String, author: String = "", isbn: String = "", totalPages: Int? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn = isbn
        self.totalPages = totalPages
    }
}
