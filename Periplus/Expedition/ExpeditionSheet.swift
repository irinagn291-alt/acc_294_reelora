import SwiftUI

/// Opens a voyage from Base. Landfall is a calendar day after today.
struct ExpeditionScreen: View {
    @Bindable var store: PeriplusStore
    var openCatalogue: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var landfall = Calendar.current.date(byAdding: .day, value: 21, to: .now) ?? .now
    @State private var volumeId: UUID?
    @State private var notice: String?
    @State private var failed = false

    var body: some View {
        let phase = ExpeditionFold.phase(in: store.snapshot)
        NavigationStack {
            ZStack {
                DesignTokens.bg.ignoresSafeArea()
                if store.snapshot.volumes.isEmpty {
                    empty
                } else if failed {
                    error
                } else {
                    filled(phase: phase)
                }
            }
            .navigationTitle(openTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(DesignTokens.accent)
        .onAppear {
            if volumeId == nil {
                volumeId = store.snapshot.volumes.first?.id
            }
        }
    }

    private var empty: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                    Image("prp_EmptyHome")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: RouteMeasure.unit * 28)
                        .accessibilityHidden(true)
                    Text("No book is on the shelf yet.")
                        .font(RouteMeasure.mono(.title, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                    Text("Add a book in the catalogue, then choose the day you mean to finish it.")
                        .font(RouteMeasure.mono(.body))
                        .foregroundStyle(DesignTokens.muted)
                        .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                    Spacer(minLength: RouteMeasure.row)
                    Button("Open the catalogue") { openCatalogue() }
                        .buttonStyle(RoutePrimaryStyle())
                }
                .padding(RouteMeasure.band)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
    }

    private var error: some View {
        VStack(alignment: .leading, spacing: RouteMeasure.pad) {
            Text(notice ?? "The voyage could not be opened.")
                .font(RouteMeasure.mono(.headline, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Text("Check the finish day and try again.")
                .font(RouteMeasure.mono(.body))
                .foregroundStyle(DesignTokens.muted)
            Button("Try again") { failed = false }
                .buttonStyle(RoutePrimaryStyle())
            Spacer(minLength: 0)
        }
        .padding(RouteMeasure.band)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func filled(phase: ExpeditionPhase) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                switch phase {
                case .underway(let expedition):
                    underway(expedition)
                case .landed(let expedition):
                    Text("The last voyage has landed. You can open the next book.")
                        .font(RouteMeasure.mono(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                    if let volume = store.snapshot.volumes.first(where: { $0.id == expedition.volumeId }) {
                        Text(volume.title)
                            .font(RouteMeasure.mono(.headline))
                            .foregroundStyle(DesignTokens.muted)
                    }
                    opener
                case .moored:
                    Text("Pick a book and the day you intend to finish it. That day is the finish day.")
                        .font(RouteMeasure.mono(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                    opener
                }
                if let notice, !failed {
                    Text(notice)
                        .font(RouteMeasure.mono(.caption))
                        .foregroundStyle(DesignTokens.ink)
                }
            }
            .padding(RouteMeasure.band)
        }
    }

    private var openTitle: String {
        let phase = ExpeditionFold.phase(in: store.snapshot)
        let expedition: Expedition?
        switch phase {
        case .moored:
            expedition = nil
        case .underway(let value), .landed(let value):
            expedition = value
        }
        guard let expedition,
              let volume = store.snapshot.volumes.first(where: { $0.id == expedition.volumeId }) else {
            return "Open a voyage"
        }
        return volume.title
    }

    private func underway(_ expedition: Expedition) -> some View {
        let volume = store.snapshot.volumes.first { $0.id == expedition.volumeId }
        let projection = store.projection()
        let opened = RouteMeasure.dayText(expedition.baseDayKey)
        let finish = RouteMeasure.dayText(expedition.landfallDayKey)
        let along = RouteMeasure.pagesText(projection?.lastEndPage ?? 0)
        let total = RouteMeasure.pagesText(volume?.totalPages ?? 0)
        let remaining = max(0, (volume?.totalPages ?? 0) - (projection?.lastEndPage ?? 0))
        let buoys = store.snapshot.buoys.filter { $0.expeditionId == expedition.id }.map(\.quartile).sorted()
        return VStack(alignment: .leading, spacing: RouteMeasure.pad) {
            Text("This book's route.")
                .font(RouteMeasure.mono(.title, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
            Text("Opened \(opened). Finish day \(finish). \(along) of \(total) pages are on the line.")
                .font(RouteMeasure.mono(.body))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            RoutePlate(
                routeX: projection?.routeX ?? 0,
                driftAngle: projection?.driftAngle ?? 0,
                quartiles: buoys
            )
            .frame(maxWidth: .infinity)
            .frame(height: RouteMeasure.unit * 22)
            .clipShape(RoundedRectangle(cornerRadius: RouteMeasure.card, style: .continuous))
            .hairlinePlate()
            Button("Log pages") { dismiss() }
                .buttonStyle(RoutePrimaryStyle())
            Button("Finish the book") { finishBook(remaining: remaining) }
                .buttonStyle(RouteQuietStyle())
                .disabled(remaining < 1 || projection?.logRefused == true)
        }
    }

    private func finishBook(remaining: Int) {
        guard remaining > 0 else { return }
        switch store.logLeg(pages: remaining) {
        case .success:
            notice = "The remaining pages are on the route."
            failed = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .failure(let error):
            notice = MapScreen.message(for: error)
            failed = true
        }
    }

    private var opener: some View {
        VStack(alignment: .leading, spacing: RouteMeasure.row) {
            Text("Book")
                .font(RouteMeasure.mono(.micro))
                .foregroundStyle(DesignTokens.muted)
            Picker("Volume", selection: Binding(
                get: { volumeId ?? store.snapshot.volumes.first?.id ?? UUID() },
                set: { volumeId = $0 }
            )) {
                ForEach(store.snapshot.volumes) { volume in
                    Text(volume.title).tag(volume.id)
                }
            }
            .pickerStyle(.menu)
            .font(RouteMeasure.mono(.body))
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            DatePicker("Finish day", selection: $landfall, in: tomorrow..., displayedComponents: .date)
                .font(RouteMeasure.mono(.body))
                .foregroundStyle(DesignTokens.ink)
            Button("Open voyage") { open() }
                .buttonStyle(RoutePrimaryStyle())
        }
        .padding(RouteMeasure.pad)
        .hairlinePlate()
    }

    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
    }

    private func open() {
        guard let volumeId else {
            notice = "Choose a volume first."
            failed = true
            return
        }
        let key = DayKey.make(from: landfall)
        switch store.openExpedition(volumeId: volumeId, landfallDayKey: key) {
        case .success:
            notice = "The expedition is open from today."
            failed = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .failure(let error):
            notice = MapScreen.message(for: error)
            failed = true
        }
    }
}
