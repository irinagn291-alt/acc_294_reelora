import SwiftUI

/// Root host. The cyanotype map stays mounted. Sheets are the other destinations.
struct ContentView: View {
    @Bindable var store: PeriplusStore

    var body: some View {
        RouteShell(store: store)
    }
}
