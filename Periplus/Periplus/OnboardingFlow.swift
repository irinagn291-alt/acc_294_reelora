import SwiftUI

/// Three pages, then the map. Skip writes the same completion flag as the last page.
struct OnboardingFlow: View {
    var finish: () -> Void
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("prp_Onboarding1", "A route for one volume.", "Periplus keeps a cyanotype line toward the day you mean to finish the book."),
        ("prp_Onboarding2", "Log the pages you read today.", "Each log advances the route. A day with no log curls the line off the true bearing."),
        ("prp_Onboarding3", "Set when the curl reaches its cap.", "Set moves landfall forward so the drift returns to zero, and the next log is allowed.")
    ]

    var body: some View {
        ZStack {
            DesignTokens.bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .font(RouteMeasure.mono(.body, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                Button(page == pages.count - 1 ? "Continue" : "Next") {
                    if page == pages.count - 1 {
                        finish()
                    } else {
                        page += 1
                    }
                }
                .buttonStyle(RoutePrimaryStyle())
            }
            .padding(RouteMeasure.band)
        }
    }

    private func pageView(_ item: (String, String, String)) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                Image(item.0)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: RouteMeasure.unit * 40)
                    .accessibilityHidden(true)
                Text(item.1)
                    .font(RouteMeasure.mono(.title, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.2)
                    .font(RouteMeasure.mono(.body))
                    .foregroundStyle(DesignTokens.muted)
                    .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
