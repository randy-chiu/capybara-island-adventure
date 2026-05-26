import SwiftUI

@main
struct CapybaraIslandAdventureApp: App {
    @StateObject private var game = GameViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
        }
    }
}
