import SwiftUI

@main
struct PaperboyApp: App {
    @State private var store = WallpaperStore()

    var body: some Scene {
        MenuBarExtra("Paperboy", systemImage: "photo.on.rectangle.angled") {
            MenuView()
                .environment(store)
        }
        .menuBarExtraStyle(.window)
    }
}
