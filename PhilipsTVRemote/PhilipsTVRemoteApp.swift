import SwiftUI

@main
struct PhilipsTVRemoteApp: App {
    @StateObject private var tv = TVClient()

    init() {
        // Selected segment uses the Kiel accent (the AccentColor asset mirrors Kiel.accent).
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(named: "AccentColor")
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tv)
                .preferredColorScheme(.dark)
        }
    }
}
