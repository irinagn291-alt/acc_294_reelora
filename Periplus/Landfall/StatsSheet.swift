import SwiftUI

/// Counts landfalls, legs, and set marks. One hero figure, then a varied list.
struct StatsScreen: View {
    var store: PeriplusStore
    @Environment(\.dismiss) private var dismiss
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.bg.ignoresSafeArea()
                if failed {
                    error
                } else if store.snapshot.legs.isEmpty && store.snapshot.landfalls.isEmpty && store.snapshot.setMarks.isEmpty {
                    empty
                } else {
                    filled
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(DesignTokens.accent)
    }

    private var empty: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                    Image("prp_EmptyList")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: RouteMeasure.unit * 32)
                        .accessibilityHidden(true)
                    Text("No landfalls yet.")
                        .font(RouteMeasure.mono(.title, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                    Text("Legs, buoys, and set marks collect here after you log the route.")
                        .font(RouteMeasure.mono(.body))
                        .foregroundStyle(DesignTokens.muted)
                        .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                    Spacer(minLength: RouteMeasure.row)
                    Button("Back to the route") { dismiss() }
                        .buttonStyle(RoutePrimaryStyle())
                }
                .padding(RouteMeasure.band)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
    }

    private var error: some View {
        VStack(alignment: .leading, spacing: RouteMeasure.pad) {
            Text("The history could not be counted.")
                .font(RouteMeasure.mono(.headline, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Button("Try again") { failed = false }
                .buttonStyle(RoutePrimaryStyle())
            Spacer(minLength: 0)
        }
        .padding(RouteMeasure.band)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var filled: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                VStack(alignment: .leading, spacing: RouteMeasure.tight) {
                    Text("Landfalls")
                        .font(RouteMeasure.mono(.micro))
                        .foregroundStyle(DesignTokens.muted)
                    Text(RouteMeasure.pagesText(store.snapshot.landfalls.count))
                        .font(RouteMeasure.mono(.display, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .contentTransition(.numericText())
                }
                .padding(RouteMeasure.pad)
                .frame(maxWidth: .infinity, alignment: .leading)
                .hairlinePlate()
                HStack(alignment: .top, spacing: RouteMeasure.row) {
                    countTile("Legs", store.snapshot.legs.count)
                    countTile("Set marks", store.snapshot.setMarks.count)
                }
                if store.loadNotice == .restoredBackup {
                    Text("A backup of the route was restored.")
                        .font(RouteMeasure.mono(.caption))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                }
                Text("Legs")
                    .font(RouteMeasure.mono(.headline))
                    .foregroundStyle(DesignTokens.ink)
                    ForEach(store.snapshot.legs.reversed()) { leg in
                    let day = RouteMeasure.dayText(leg.dayKey)
                    let count = RouteMeasure.pagesText(leg.pages)
                    HStack {
                        Text(day)
                            .font(RouteMeasure.mono(.body))
                            .foregroundStyle(DesignTokens.ink)
                        Spacer()
                        Text("\(count) pages")
                            .font(RouteMeasure.mono(.body, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                    }
                    .padding(RouteMeasure.row)
                    .frame(minHeight: 44)
                    .hairlinePlate(radius: RouteMeasure.chip)
                }
                if !store.snapshot.buoys.isEmpty {
                    Text("Buoys")
                        .font(RouteMeasure.mono(.headline))
                        .foregroundStyle(DesignTokens.ink)
                    ForEach(store.snapshot.buoys) { buoy in
                        let mark = RouteMeasure.pagesText(buoy.quartile)
                        Text("Quartile \(mark)")
                            .font(RouteMeasure.mono(.body))
                            .foregroundStyle(DesignTokens.ink)
                            .padding(RouteMeasure.row)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .hairlinePlate(radius: RouteMeasure.chip)
                    }
                }
                if !store.snapshot.setMarks.isEmpty {
                    Text("Recalibrations")
                        .font(RouteMeasure.mono(.headline))
                        .foregroundStyle(DesignTokens.ink)
                    ForEach(store.snapshot.setMarks) { mark in
                        let when = RouteMeasure.dayText(mark.dayKey)
                        let from = RouteMeasure.dayText(mark.previousLandfallDayKey)
                        let to = RouteMeasure.dayText(mark.revisedLandfallDayKey)
                        Text("On \(when), the finish day moved from \(from) to \(to).")
                            .font(RouteMeasure.mono(.caption))
                            .foregroundStyle(DesignTokens.ink)
                            .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                            .padding(RouteMeasure.row)
                            .hairlinePlate(radius: RouteMeasure.chip)
                    }
                }
            }
            .padding(RouteMeasure.band)
        }
    }

    private func countTile(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: RouteMeasure.tight) {
            Text(title)
                .font(RouteMeasure.mono(.micro))
                .foregroundStyle(DesignTokens.muted)
            Text(RouteMeasure.pagesText(value))
                .font(RouteMeasure.mono(.title, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
        }
        .padding(RouteMeasure.row)
        .frame(maxWidth: .infinity, alignment: .leading)
        .hairlinePlate(radius: RouteMeasure.chip)
    }
}
