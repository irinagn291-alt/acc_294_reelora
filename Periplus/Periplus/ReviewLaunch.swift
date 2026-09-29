import Foundation

/// Launch keys are not tabs. Parsed once, and only after onboarding has finished.
enum ReviewDestination: String, Equatable, Sendable {
    case today
    case log
    case goals
    case catalogue
    case settings
}

enum ReviewLaunch {
    static func destination(from arguments: [String]) -> ReviewDestination? {
        guard let flag = arguments.firstIndex(of: "-ReviewScreen"),
              flag + 1 < arguments.count else { return nil }
        return ReviewDestination(rawValue: arguments[flag + 1])
    }
}
