import SwiftUI
import WatchConnectivity

@main
struct FitForgeWatchApp: App {
  @StateObject private var store = WatchSessionStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(store)
    }
  }
}
