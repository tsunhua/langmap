import SwiftUI

@main
struct langmapApp: App {
    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authService)
        }
    }
}
