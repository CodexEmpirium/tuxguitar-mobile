import SwiftUI

@main
struct TuxGuitarMobileApp: App {
    @StateObject private var library: SongLibrary

    init() {
        _library = StateObject(wrappedValue: SongLibrary())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .tint(.orange)
        }
    }
}
