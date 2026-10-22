import SwiftUI

@main
struct PhilipsTVRemoteApp: App {
    @StateObject private var tv = TVClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tv)
        }
    }
}
