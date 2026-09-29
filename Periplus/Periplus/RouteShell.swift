import SwiftUI

/// Value destinations. The map never leaves the root. The other screens are sheets.
enum RouteSheet: String, Identifiable {
    case catalogue
    case expedition
    case stats
    case settings

    var id: String { rawValue }

    static func matching(_ destination: ReviewDestination?) -> RouteSheet? {
        switch destination {
        case .today, .none:
            return nil
        case .log:
            return .stats
        case .goals:
            return .expedition
        case .catalogue:
            return .catalogue
        case .settings:
            return .settings
        }
    }
}

struct RouteShell: View {
    @Bindable var store: PeriplusStore
    @State private var sheet: RouteSheet?
    @State private var appliedReview = false

    var body: some View {
        Group {
            if store.onboardingComplete {
                MapScreen(store: store) { sheet = $0 }
                    .sheet(item: $sheet) { route in
                        sheetBody(route)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                    }
            } else {
                OnboardingFlow {
                    store.finishOnboarding()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: store.onboardingComplete) { _, done in
            guard done else { return }
            noteLaunchArguments()
        }
        .onChange(of: store.reviewDestination) { _, _ in
            applyReview()
        }
        .task {
            noteLaunchArguments()
        }
    }

    @ViewBuilder
    private func sheetBody(_ route: RouteSheet) -> some View {
        switch route {
        case .catalogue:
            CatalogueScreen(store: store)
        case .expedition:
            ExpeditionScreen(store: store, openCatalogue: { sheet = .catalogue })
        case .stats:
            StatsScreen(store: store)
        case .settings:
            SettingsScreen(store: store)
        }
    }

    /// Read once, after onboarding. `-ReviewScreen` is a launch key, not a tab.
    private func noteLaunchArguments() {
        guard store.onboardingComplete else { return }
        let arguments = ProcessInfo.processInfo.arguments
        store.consumeLaunch(arguments: arguments)
        if arguments.contains("-ReviewScreen") {
            applyReview()
        }
    }

    private func applyReview() {
        guard store.onboardingComplete, !appliedReview else { return }
        guard let destination = store.reviewDestination else { return }
        appliedReview = true
        sheet = RouteSheet.matching(destination)
    }
}
