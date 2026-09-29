import SwiftUI

/// Home. The fold is projected onto the cyanotype. Log is the verb.
struct MapScreen: View {
    @Bindable var store: PeriplusStore
    var openSheet: (RouteSheet) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var pages = "1"
    @State private var refusal: String?
    @State private var logging = false
    @State private var loggedMark = false

    var body: some View {
        let phase = ExpeditionFold.phase(in: store.snapshot)
        let projection = store.projection()
        NavigationStack {
            ZStack {
                DesignTokens.bg.ignoresSafeArea()
                switch phase {
                case .moored where projection == nil && store.snapshot.expeditions.isEmpty:
                    empty
                default:
                    populated(phase: phase, projection: projection)
                }
            }
            .navigationTitle(activeVolume(phase: phase)?.title ?? "Log pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { chrome }
        }
        .tint(DesignTokens.accent)
    }

    private var empty: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                    Image("prp_EmptyHome")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: RouteMeasure.unit * 36)
                        .clipped()
                        .accessibilityHidden(true)
                    Text("No voyage yet. Open a book.")
                        .font(RouteMeasure.mono(.title, weight: .semibold))
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("The route appears after you choose a book and a finish day.")
                        .font(RouteMeasure.mono(.body))
                        .foregroundStyle(DesignTokens.muted)
                        .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                    Spacer(minLength: RouteMeasure.row)
                    Button("Open a book") { openSheet(.catalogue) }
                        .buttonStyle(RoutePrimaryStyle())
                }
                .padding(RouteMeasure.band)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
    }

    private func populated(phase: ExpeditionPhase, projection: RouteProjection?) -> some View {
        let volume = activeVolume(phase: phase)
        let buoys = buoys(for: phase)
        let drift = projection?.driftAngle ?? 0
        let routeX = projection?.routeX ?? 0
        let angle = RouteMeasure.angleText(drift)
        let along = RouteMeasure.pagesText(projection?.lastEndPage ?? 0)
        let total = RouteMeasure.pagesText(volume?.totalPages ?? 0)
        let plateHeight = sizeClass == .regular ? RouteMeasure.unit * 36 : RouteMeasure.unit * 22
        return ScrollView {
            VStack(alignment: .leading, spacing: RouteMeasure.pad) {
                Text("Log pages on this voyage.")
                    .font(RouteMeasure.mono(.title, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(caption(phase: phase, projection: projection))
                    .font(RouteMeasure.mono(.body))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                ZStack(alignment: .bottomTrailing) {
                    RoutePlate(routeX: routeX, driftAngle: drift, quartiles: buoys)
                        .frame(maxWidth: .infinity)
                        .frame(height: plateHeight)
                    if loggedMark {
                        Image("prp_SuccessMark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: RouteMeasure.band, height: RouteMeasure.band)
                            .padding(RouteMeasure.row)
                            .accessibilityHidden(true)
                            .transition(.opacity)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: RouteMeasure.card, style: .continuous))
                .hairlinePlate()
                if case .underway = phase {
                    pageControl
                    if let refusal {
                        Text(refusal)
                            .font(RouteMeasure.mono(.caption))
                            .foregroundStyle(DesignTokens.ink)
                            .padding(RouteMeasure.row)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .hairlinePlate(radius: RouteMeasure.chip)
                    }
                    if projection?.logRefused == true {
                        Text("The curl has reached forty five degrees. Set the finish day before the next log.")
                            .font(RouteMeasure.mono(.body))
                            .foregroundStyle(DesignTokens.ink)
                            .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                        Button { commitSet() } label: {
                            Text("Set finish day")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(RoutePrimaryStyle())
                    } else {
                        Button {
                            commitLog()
                        } label: {
                            Text(logging ? "Logging" : "Log \(pages) pages")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .opacity(logging ? 0 : 1)
                        }
                        .buttonStyle(RoutePrimaryStyle(loading: logging))
                        .disabled(logging || parsedPages == nil)
                    }
                } else if case .landed = phase {
                    Text("This book has landed. Open another from the catalogue when you are ready.")
                        .font(RouteMeasure.mono(.body))
                        .foregroundStyle(DesignTokens.ink)
                        .frame(maxWidth: RouteMeasure.measure, alignment: .leading)
                    Button("Open a book") { openSheet(.catalogue) }
                        .buttonStyle(RoutePrimaryStyle())
                }
                HStack(alignment: .firstTextBaseline, spacing: RouteMeasure.row) {
                    VStack(alignment: .leading, spacing: RouteMeasure.tight) {
                        Text("Curl")
                            .font(RouteMeasure.mono(.micro))
                            .foregroundStyle(DesignTokens.muted)
                        Text("\(angle)°")
                            .font(RouteMeasure.mono(.display, weight: .semibold))
                            .foregroundStyle(DesignTokens.accent)
                            .lineLimit(1)
                            .layoutPriority(1)
                            .contentTransition(reduceMotion ? .identity : .numericText())
                            .animation(reduceMotion ? nil : RouteMeasure.settle, value: drift)
                    }
                    Spacer(minLength: RouteMeasure.row)
                    VStack(alignment: .trailing, spacing: RouteMeasure.tight) {
                        Text("Along the route")
                            .font(RouteMeasure.mono(.micro))
                            .foregroundStyle(DesignTokens.muted)
                            .lineLimit(1)
                        Text(along)
                            .font(RouteMeasure.mono(.title, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                            .lineLimit(1)
                            .layoutPriority(1)
                            .contentTransition(reduceMotion ? .identity : .numericText())
                        Text("of \(total) pages")
                            .font(RouteMeasure.mono(.micro))
                            .foregroundStyle(DesignTokens.muted)
                            .lineLimit(1)
                    }
                }
                .padding(RouteMeasure.pad)
                .hairlinePlate()
            }
            .padding(RouteMeasure.band)
            .padding(.bottom, RouteMeasure.row)
            .animation(reduceMotion ? nil : RouteMeasure.settle, value: loggedMark)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            routeDock(phase: phase)
        }
    }

    /// Pinned above the home indicator so the leg count is never cut by the first frame.
    private func routeDock(phase: ExpeditionPhase) -> some View {
        VStack(alignment: .leading, spacing: RouteMeasure.tight) {
            Text(legLine(phase: phase))
                .font(RouteMeasure.mono(.caption))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if store.loadNotice == .startedEmpty && store.snapshot.legs.isEmpty {
                Text("The last file could not be read, so this route started empty.")
                    .font(RouteMeasure.mono(.caption))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, RouteMeasure.band)
        .padding(.top, RouteMeasure.row)
        .padding(.bottom, RouteMeasure.row)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.bg)
    }

    @ToolbarContentBuilder
    private var chrome: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                openSheet(.catalogue)
            } label: {
                Image(systemName: "books.vertical")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Catalogue")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                openSheet(.expedition)
            } label: {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Voyage")
            Button {
                openSheet(.stats)
            } label: {
                Image(systemName: "list.bullet")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Stats")
            Button {
                openSheet(.settings)
            } label: {
                Image(systemName: "gearshape")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var pageControl: some View {
        HStack(spacing: RouteMeasure.row) {
            Button {
                stepPages(by: -1)
            } label: {
                Image(systemName: "minus")
                    .font(RouteMeasure.mono(.headline, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(DesignTokens.ink)
            .frame(width: 44, height: 44)
            .background(DesignTokens.bg, in: RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous))
            .accessibilityLabel("Fewer pages")
            VStack(alignment: .leading, spacing: RouteMeasure.tight) {
                Text("Today's pages")
                    .font(RouteMeasure.mono(.caption, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                Text(pages.isEmpty ? "0" : pages)
                    .font(RouteMeasure.mono(.display, weight: .semibold))
                    .foregroundStyle(DesignTokens.accent)
                    .lineLimit(1)
                    .contentTransition(reduceMotion ? .identity : .numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                stepPages(by: 1)
            } label: {
                Image(systemName: "plus")
                    .font(RouteMeasure.mono(.headline, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(DesignTokens.ink)
            .frame(width: 44, height: 44)
            .background(DesignTokens.bg, in: RoundedRectangle(cornerRadius: RouteMeasure.chip, style: .continuous))
            .accessibilityLabel("More pages")
        }
        .padding(RouteMeasure.row)
        .hairlinePlate(radius: RouteMeasure.chip)
    }

    private func stepPages(by delta: Int) {
        let current = parsedPages ?? 0
        let next = max(1, current + delta)
        pages = String(next)
        refusal = nil
    }

    private var parsedPages: Int? {
        let digits = pages.filter(\.isNumber)
        guard let value = Int(digits), value > 0 else { return nil }
        return value
    }

    private func activeVolume(phase: ExpeditionPhase) -> Volume? {
        let expedition: Expedition?
        switch phase {
        case .moored:
            expedition = store.snapshot.expeditions.last
        case .underway(let value), .landed(let value):
            expedition = value
        }
        guard let expedition else { return nil }
        return store.snapshot.volumes.first { $0.id == expedition.volumeId }
    }

    private func buoys(for phase: ExpeditionPhase) -> [Int] {
        let id: UUID?
        switch phase {
        case .moored:
            id = nil
        case .underway(let expedition), .landed(let expedition):
            id = expedition.id
        }
        guard let id else { return [] }
        return store.snapshot.buoys.filter { $0.expeditionId == id }.map(\.quartile).sorted()
    }

    private func legLine(phase: ExpeditionPhase) -> String {
        let id: UUID?
        switch phase {
        case .moored:
            id = nil
        case .underway(let expedition), .landed(let expedition):
            id = expedition.id
        }
        guard let id else { return "No legs are on this route yet." }
        let legs = store.snapshot.legs.filter { $0.expeditionId == id }
        guard let latest = legs.max(by: { $0.dayKey < $1.dayKey }) else {
            return "No legs are on this route yet."
        }
        let todayPages = legs.filter { $0.dayKey == store.today }.reduce(0) { $0 + $1.pages }
        return "\(RouteMeasure.pagesText(legs.count)) legs are logged. Today holds \(RouteMeasure.pagesText(todayPages)) pages, and the latest leg is \(RouteMeasure.pagesText(latest.pages)) pages on \(RouteMeasure.dayText(latest.dayKey))."
    }

    private func caption(phase: ExpeditionPhase, projection: RouteProjection?) -> String {
        switch phase {
        case .moored:
            return "No voyage is open. Choose a book and set a finish day."
        case .underway:
            if projection?.logRefused == true {
                return "The route has curled to the cap. Set pushes the finish day forward, then you can log again."
            }
            return "Log today's pages. Idle days curl this line off the true bearing."
        case .landed:
            return "The route has arrived and the curl is clear."
        }
    }

    private func commitLog() {
        guard let count = parsedPages else {
            refusal = "Enter the pages you read today as a whole number."
            return
        }
        logging = true
        defer { logging = false }
        switch store.logLeg(pages: count) {
        case .success:
            refusal = nil
            pages = "1"
            loggedMark = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task {
                try? await Task.sleep(for: .milliseconds(900))
                loggedMark = false
            }
        case .failure(let error):
            refusal = MapScreen.message(for: error)
        }
    }

    private func commitSet() {
        switch store.recalibrate() {
        case .success:
            refusal = nil
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .failure(let error):
            refusal = MapScreen.message(for: error)
        }
    }

    static func message(for error: RouteRefusal) -> String {
        switch error {
        case .noExpedition:
            return "Open a voyage before you log a leg."
        case .alreadyUnderway:
            return "A voyage is already underway."
        case .driftCapped:
            return "The curl has reached forty five degrees. Set the finish day before the next log."
        case .driftAlreadyZero:
            return "Set is refused while the curl is already zero."
        case .pagesNotPositive:
            return "Enter a page count greater than zero."
        case .pagesExceedRemaining:
            return "That count runs past the end of the book."
        case .volumeMissing:
            return "The book for this route is missing."
        case .landfallNotAfterBase:
            return "The finish day has to fall on a later day than today."
        case .cannotRecalibrate:
            return "Set needs some pages already logged before it can move the finish day."
        case .alreadyLanded:
            return "This voyage has already landed."
        }
    }
}
