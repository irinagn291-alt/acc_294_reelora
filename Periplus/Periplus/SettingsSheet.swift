import SwiftUI

/// Re-run onboarding, a named reset, and the contact page.
struct SettingsScreen: View {
    @Bindable var store: PeriplusStore
    @State private var confirmReset = false
    @State private var notice: String?
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bg.ignoresSafeArea()
                if failed {
                    error
                } else if store.snapshot.volumes.isEmpty && store.snapshot.expeditions.isEmpty {
                    empty
                } else {
                    filled
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(DesignTokens.accent)
        .confirmationDialog(resetTitle, isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Delete the route", role: .destructive) {
                Task { await wipe() }
            }
            Button("Keep the route", role: .cancel) {}
        } message: {
            Text("Legs, buoys, set marks, and landfalls for this route leave this device.")
        }
    }

    private var routeName: String {
        store.snapshot.volumes.last?.title ?? "the open route"
    }

    private var resetTitle: String {
        "Delete \(routeName)?"
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: RouteMeasure.pad) {
            Text("Nothing is stored yet.")
                .font(RouteMeasure.mono(.title, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Text(notice ?? "You can still replay the introduction or write to the contact page.")
                .font(RouteMeasure.mono(.body))
                .foregroundStyle(DesignTokens.muted)
                .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
            controls
            Spacer(minLength: 0)
        }
        .padding(RouteMeasure.band)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var error: some View {
        VStack(alignment: .leading, spacing: RouteMeasure.pad) {
            Text(notice ?? "The route could not be written to disk.")
                .font(RouteMeasure.mono(.headline, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Button("Try again") {
                Task {
                    await store.flush()
                    failed = store.diskWriteFailed
                    if !failed { notice = nil }
                }
            }
            .buttonStyle(RoutePrimaryStyle())
            Spacer(minLength: 0)
        }
        .padding(RouteMeasure.band)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var filled: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                Text("The route named \(routeName) stays on this device.")
                    .font(RouteMeasure.mono(.body))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                if store.diskWriteFailed {
                    Text("The last save did not reach disk.")
                        .font(RouteMeasure.mono(.caption))
                        .foregroundStyle(DesignTokens.ink)
                    Button("Save again") {
                        Task {
                            await store.flush()
                            if store.diskWriteFailed {
                                notice = "The last save did not reach disk."
                                failed = true
                            }
                        }
                    }
                    .buttonStyle(RoutePrimaryStyle())
                }
                controls
            }
            .padding(RouteMeasure.band)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: RouteMeasure.row) {
            Button("Replay introduction") { store.reopenOnboarding() }
                .buttonStyle(RouteQuietStyle())
            Button("Delete the route") { confirmReset = true }
                .buttonStyle(RouteDestructiveStyle())
            if let contact = URL(string: "https://periplus-route.pro/contact-us") {
                Link(destination: contact) {
                    Text("Contact")
                }
                .buttonStyle(RoutePrimaryStyle())
                .accessibilityLabel("Contact Periplus")
            }
        }
    }

    private func wipe() async {
        let name = routeName
        await store.resetAllData()
        notice = "\(name) was removed from this device."
    }
}
